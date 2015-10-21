//
//  SGDataManager.m
//  SeatGeek
//
//  Created by David McNerney on 10/5/15.
//  Copyright © 2015 SeatGeek. All rights reserved.
//

#import <MGEvents/MGEvents.h>
#import "SGDataManager.h"
#import "SGItemSet.h"
#import "SGQuery.h"
#import "SGItem.h"

@interface SGDataManager ()
@property (nonatomic, strong) NSArray *resultItems;
@property (nonatomic, assign) BOOL lastRefreshFailed;
@end

@implementation SGDataManager

+ (instancetype)managerForItemSet:(SGItemSet *)itemSet {
    SGDataManager *manager = self.new;
    manager.itemSet = itemSet;
    return manager;
}

#pragma mark - Refreshing data

- (void)refresh {

    // need to refresh the entire itemSet?
    if (self.itemSet.needsRefresh && !self.itemSet.fetching) {
        [self.itemSet reset];
        [self.itemSet fetchNextPage];
        return;
    }

    // need to refresh any individual items?
    for (SGItem *item in self.itemSet.orderedSet) {
        if (item.needsRefresh && !item.fetching) {
            [item fetch];
        }
        [self fetchChildrenOf:item];
    }
}

- (void)fetchChildrenOf:(SGItem *)item {
    for (SGItem *child in item.childItems) {
        if (child.needsRefresh && !child.fetching) {
            [child fetch];
        }
        [self fetchChildrenOf:child];
    }
}

#pragma mark - Flagging data as in need of refresh

- (void)needToRefreshItemOfKind:(Class)itemClass withID:(NSString *)itemID {
    BOOL weHaveIt = [self setNeedsToRefreshOnItemOfKind:itemClass withID:itemID in:self.itemSet.array];
    if (!weHaveIt) { // we don't have the item, so refresh the entire set instead
        [self.itemSet setNeedsRefresh];
    }
}

// returns NO if no matching item is found in our existing data
- (BOOL)setNeedsToRefreshOnItemOfKind:(Class)itemClass withID:(NSString *)itemID in:(NSArray *)items {
    for (SGItem *item in items) {
        if ([item isKindOfClass:itemClass] && [item.ID isEqualToString:itemID]) {
            [item setNeedsRefresh];
            return YES;
        }
        if ([self setNeedsToRefreshOnItemOfKind:itemClass withID:itemID in:item.childItems]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Setters

- (void)setItemSet:(SGItemSet *)itemSet {
    _itemSet = itemSet;

    self.itemSet.dataManager = self;

    // pick up any cached results
    self.resultItems = itemSet.array;

    __weakSelf me = self;
    [self when:itemSet does:SGItemSetFetchSucceeded doWithContext:^(NSOrderedSet *newItems) {
        me.lastRefreshFailed = NO;
        me.resultItems = me.itemSet.array;
    }];

    [self when:itemSet does:SGItemSetFetchFailed do:^{
        me.lastRefreshFailed = YES;
    }];
}

@end
