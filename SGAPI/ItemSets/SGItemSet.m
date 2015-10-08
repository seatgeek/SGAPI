//
//  Created by matt on 18/01/14.
//

#import <SGImageCache/SGCache.h>
#import "SGItemSet.h"
#import "SGHTTPRequest.h"
#import "SGQuery.h"
#import "SGItem.h"

@interface SGItemSet ()
@property (nonatomic, strong) NSMutableOrderedSet *items;
@property (nonatomic, strong) NSDictionary *meta;
@property (nonatomic, assign) BOOL fetching;
@property (nonatomic, assign) int lastFetchedPage;
@property (nonatomic, strong) SGHTTPRequest *request;
@property (nonatomic, assign) BOOL itemsAreFromCache;
@property (nonatomic, strong) NSDictionary *lastResponseDict;
@property (nonatomic, strong) NSDate *lastFetched;
@end

@implementation SGItemSet

- (id)init {
    self = [super init];
    self.allowStatusBarSpinner = YES;
    return self;
}

// abstract. implemented in subclasses
- (id)itemForDict:(NSDictionary *)dict {
#ifdef DEBUG
    NSAssert(NO, @"Called the abstract itemForDict: on SGItemSet. Don't do that.");
#endif
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

    SGHTTPRequest *req = [self.query requestWithMethod:SGHTTPRequestMethodGet];
    req.showActivityIndicator = self.allowStatusBarSpinner;

    if (SGQuery.consoleLogging) {
        req.logging = req.logging | (SGHTTPLogRequests | SGHTTPLogErrors);
    }

    __weakSelf me = self;
    req.onSuccess = ^(SGHTTPRequest *_req) {
        [me processResults:_req.responseData url:_req.url.absoluteString];
    };
    req.onFailure = ^(SGHTTPRequest *_req) {
        me.fetching = NO;
        if (me.onPageLoadFailed) {
            me.onPageLoadFailed(_req.error);
        }
    };
    req.onNetworkReachable = ^{
        if (me.onPageLoadRetry) {
            me.onPageLoadRetry();
        }
        [me fetchNextPage];
    };
    [req start];
    self.request = req;
}

- (void)cancelFetch {
    [self.request cancel];
    self.fetching = NO;
}

- (void)processResults:(NSData *)data url:(NSString *)url {
    __weakSelf me = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = nil;
        NSDictionary *dict = [SGJSONSerialization JSONObjectWithData:data error:&error logURL:url];
        me.lastResponseDict = dict;

        if (error) {
            if (me.onPageLoadFailed) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    me.onPageLoadFailed(error);
                });
            }
            return;
        }

        NSArray *results = dict[me.resultArrayKey];
        if (![results isKindOfClass:NSArray.class]) {
            results = nil;
        }

        NSDictionary *metaDict = dict[@"meta"];
        if (!metaDict) {
            // assume this endpoint cannot be paginated.
            metaDict = @{@"per_page" : @(me.query.perPage ?: results.count),
                         @"total" : @(results.count),
                         @"page" : @(1)}.copy;
        }

        NSMutableOrderedSet *newItems = NSMutableOrderedSet.orderedSet;
        for (NSDictionary *itemDict in results) {
            SGItem *item = [me itemForDict:itemDict];
            item.lastFetched = NSDate.date;
            if (item) {
                [newItems addObject:item];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            me.meta = metaDict;
            if (me.itemsAreFromCache) {
                me.itemsAreFromCache = NO;
                [me.items removeAllObjects];    // blitz over it with fresh data
            }
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
            me.lastFetched = NSDate.date;
            if (me.onPageLoaded) {
                me.onPageLoaded(reallyNewItems);
            }
        });
    });
}

#pragma mark - Caching

- (void)cacheItemsWithCacheKey:(NSString *)cacheKey {
    if (!cacheKey.length) {
        return;
    }

    cacheKey = [NSString stringWithFormat:@"%@:%@", self.class, cacheKey];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.items];
    [SGCache addData:data forCacheKey:cacheKey];
}

- (BOOL)hasCachedItemsForCacheKey:(NSString *)cacheKey {
    cacheKey = [NSString stringWithFormat:@"%@:%@", self.class, cacheKey];
    return [SGCache haveFileForCacheKey:cacheKey];
}

- (void)loadCachedItemsForCacheKey:(NSString *)cacheKey {
    if (![self hasCachedItemsForCacheKey:cacheKey]) {
        return;
    }

    cacheKey = [NSString stringWithFormat:@"%@:%@", self.class, cacheKey];
    NSData *data = [SGCache fileForCacheKey:cacheKey];
    NSOrderedSet *orderedSet = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    self.items = orderedSet.mutableCopy;
    self.itemsAreFromCache = (self.items.count > 0);
}

#pragma mark - Setters

- (void)setMeta:(NSDictionary *)meta {
    _meta = meta;
    self.lastFetchedPage = [meta[@"page"] intValue];
}

#pragma mark - Getters

- (BOOL)lastPageAlreadyFetched {
    if (self.items && self.items.count == 0) {
        return YES;
    }
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

- (NSOrderedSet *)orderedSet {
    return self.items;
}

- (NSOrderedSet *)orderdSet {
    return self.orderedSet;
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
