//
//  Created by matt on 18/01/14.
//

#import "SGItemSet.h"
#import "SGHTTPRequest.h"
#import "SGQuery.h"

@interface SGItemSet ()

@property (nonatomic, strong) NSMutableOrderedSet *items;
@property (nonatomic, strong) NSDictionary *meta;
@property (nonatomic, assign) BOOL fetching;
@property (nonatomic, assign) int lastFetchedPage;
@property (nonatomic, strong) SGHTTPRequest *request;

@end

@implementation SGItemSet

- (id)init {
    self = [super init];
    self.allowStatusBarSpinner = YES;
    return self;
}

// abstract. implemented in subclass
- (id)itemForDict:(NSDictionary *)dict {
    return nil;
}

#pragma mark - Fetching and Processing

- (void)reset {
    self.items = nil;
    self.lastFetchedPage = 0;
    self.meta = nil;
    [self cancelFetch];
}

- (void)fetchNextPage {
    if (!self.lastPageAlreadyFetched) {
        [self fetchPage:self.lastFetchedPage + 1];
    }
}

- (void)fetchPage:(int)page {
    if (self.fetching) {
        return;
    }
    self.fetching = YES;

    self.query.page = page;

    SGHTTPRequest *req = [SGHTTPRequest requestWithURL:self.query.URL];
    req.showActivityIndicator = self.allowStatusBarSpinner;

    SGPlatformLog(@"%@", self.query.URL);

    __weakSelf me = self;
    req.onSuccess = ^(SGHTTPRequest *_req) {
        [me processResults:_req.responseData];
    };
    req.onFailure = ^(SGHTTPRequest *_req) {
        me.fetching = NO;
        SGPlatformLog(@"SGItemSet request failed with URL: %@ Error: %@",
                    me.query.URL, _req.error);
        if (self.onPageLoadFailed) {
            self.onPageLoadFailed(_req.error);
        }
    };
    req.onNetworkReachable = ^{
        [me fetchNextPage];
    };
    [req start];
    self.request = req;
}

- (void)cancelFetch {
    [self.request cancel];
    self.fetching = NO;
}

- (void)processResults:(NSData *)data {
    __weakSelf me = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSArray *results = dict[self.resultArrayKey];

        NSMutableOrderedSet *newItems = NSMutableOrderedSet.orderedSet;
        for (NSDictionary *itemDict in results) {
            [newItems addObject:[self itemForDict:itemDict]];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            me.meta = dict[@"meta"];
            NSMutableOrderedSet *reallyNewItems;
            if (me.items) {
                reallyNewItems = newItems.mutableCopy;
                [reallyNewItems minusOrderedSet:me.items];
                [me.items unionOrderedSet:newItems];
            } else {
                me.items = newItems;
                reallyNewItems = newItems;
            }
            me.fetching = NO;
            if (self.onPageLoaded) {
                self.onPageLoaded(reallyNewItems);
            }
        });
    });
}

#pragma mark - Setters

- (void)setMeta:(NSDictionary *)meta {
    _meta = meta;
    self.lastFetchedPage = [meta[@"page"] intValue];
}

#pragma mark - Getters

- (BOOL)lastPageAlreadyFetched {
    if (!self.meta) {
        return NO;
    }
    return self.lastFetchedPage == self.totalPages || !self.totalPages;
}

- (BOOL)fetching {
    return _fetching;
}

- (int)lastFetchedPage {
    return _lastFetchedPage;
}

- (int)totalPages {
    if (![self.meta[@"per_page"] intValue]) {
        return 0;
    }
    return (int)ceilf([self.meta[@"total"] floatValue] / [self.meta[@"per_page"] intValue]);
}

#pragma mark - Subscripting

- (id)objectAtIndexedSubscript:(NSUInteger)index {
    return self.items[index];
}

#pragma mark - Set Duckness

- (NSArray *)array {
    return self.items.array;
}

- (NSOrderedSet *)orderdSet {
    return self.items;
}

- (id)firstObject {
    return self.items.firstObject;
}

- (id)lastObject {
    return self.items.lastObject;
}

- (NSUInteger)count {
    return self.items.count;
}

@end
