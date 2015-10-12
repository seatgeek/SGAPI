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
    if (self.itemSet.fetching) {
        return; // nope. we's already busy
    }

    // todo: properly send start/succeeded/failed events at the right times
    // todo: properly manage the `refreshing` bool

    BOOL haveSentStartEvent = NO;

    // need to refresh the entire itemSet?
    if (self.itemSet.needsRefresh) {
        [self.itemSet reset];
        [self.itemSet fetchNextPage];
        [self trigger:SGDataManagerRefreshStarted];
        haveSentStartEvent = YES;
        return;
    }

    // need to refresh any individual items?
    for (SGItem *item in self.itemSet.orderedSet) {
        if (item.needsRefresh) {
            [item fetch];
            if (!haveSentStartEvent) {
                [self trigger:SGDataManagerRefreshStarted];
                haveSentStartEvent = YES;
            }
        }
    }
}

- (BOOL)refreshing {
    // todo: this might give wrong results if individual items are being refreshed instead
    return self.itemSet.fetching;
}

#pragma mark - Flagging data as in need of refresh

- (void)itemSetNeedsRefresh {
   [self.itemSet setNeedsRefresh];
}

- (void)needToRefreshItemOfKind:(Class)itemClass withID:(NSString *)itemID {
    BOOL weHaveIt = [self setNeedsToRefreshOnItemOfKind:itemClass withID:itemID];
    if (!weHaveIt) { // we don't have the item, so refresh the entire set instead
        [self.itemSet setNeedsRefresh];
    }
}

// returns NO if no matching item is found in our existing data
- (BOOL)setNeedsToRefreshOnItemOfKind:(Class)itemClass withID:(NSString *)itemID {

    // todo: need to be able to walk an infinitely deep tree of itemSets / items

    for (SGItem *item in self.itemSet.orderedSet) {
        if ([item isKindOfClass:itemClass] && [item.ID isEqualToString:itemID]) {
            [item setNeedsRefresh];
            return YES;
        }
    }
    return NO;
}

#pragma mark - Fetching more paginated data

- (void)fetchMoreIfAvailable {
    [self.itemSet fetchNextPage];
}

- (NSUInteger)pageSize {
    return self.itemSet.query.perPage;
}

#pragma mark - Setters

- (void)setItemSet:(SGItemSet *)itemSet {
    _itemSet = itemSet;

    __weakSelf me = self;
    self.itemSet.dataManager = self;
    [self when:itemSet does:SGItemSetFetchSucceeded do:^{
        me.lastRefreshFailed = NO;
        [me trigger:SGDataManagerRefreshSucceeded];
    }];
    [self when:itemSet does:SGItemSetFetchFailed do:^{
        me.lastRefreshFailed = YES;
        [me trigger:SGDataManagerRefreshFailed];
    }];
}

@end
