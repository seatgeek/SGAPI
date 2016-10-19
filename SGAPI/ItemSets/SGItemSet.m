//
//  Created by matt on 18/01/14.
//

#import <SGHTTPRequest/SGFileCache.h>
#import "SGItemSet.h"
#import "SGHTTPRequest.h"
#import "SGQuery.h"
#import "SGItem.h"
#import "SGDataManager.h"
#import <MGEvents/NSObject+MGEvents.h>

@interface SGItemSet ()
@property (nonatomic, strong) NSMutableOrderedSet *items;
@property (nonatomic, strong) NSDictionary *meta;
@property (nonatomic, assign) BOOL fetching;
@property (nonatomic, assign) int lastFetchedPage;
@property (nonatomic, strong) SGHTTPRequest *request;
@property (nonatomic, strong) NSDictionary *lastResponseDict;
@property (nonatomic, strong) NSDate *lastFetched;
@property (nonatomic, assign) BOOL needsRefresh;
@end

@implementation SGItemSet
// use the SGItem implementation of all these properties:
@dynamic query;
@dynamic parentSet;
@dynamic parentItem;
@dynamic dataManager;
@dynamic lastFetched;

- (id)init {
    self = [super init];
    self.allowStatusBarSpinner = YES;
    self.needsRefresh = YES;
    return self;
}

#pragma mark - For subclasses

// abstract. implemented in subclasses
- (nonnull id)itemForDict:(nonnull NSDictionary *)dict {
#ifdef DEBUG
    NSAssert(NO, @"Called the abstract itemForDict: on SGItemSet. Don't do that.");
#endif
    return nil;
}

- (void)doAdditionalProcessingWithServerResponseDict:(nonnull NSDictionary *)dict {
}

#pragma mark - Fetching and Processing

- (void)reset {
    self.items = nil;
    self.lastFetchedPage = 0;
    self.meta = nil;
    self.lastFetched = nil;
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
        [me trigger:SGItemSetFetchFailed withContext:_req.error];
    };

    req.onNetworkReachable = ^{
        if (me.onPageLoadRetry) {
            me.onPageLoadRetry();
        }
        [me fetchNextPage];
    };

    [req start];
    self.request = req;
    [self trigger:SGItemSetFetchStarted];
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
            dispatch_async(dispatch_get_main_queue(), ^{
                if (me.onPageLoadFailed) {
                    me.onPageLoadFailed(error);
                }
                [me trigger:SGItemSetFetchFailed withContext:error];
            });
            return;
        }

        NSArray *results = [dict valueForKeyPath:me.resultArrayKey];
        if (![results isKindOfClass:NSArray.class]) {
            results = nil;
        }

        NSDictionary *metaDict = dict[@"meta"] ?: me.meta;
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
            item.parentSet = me;
            if (me.dataManager) {
                item.dataManager = me.dataManager;
            }
            if (item) {
                [newItems addObject:item];
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            me.meta = metaDict;
            [me doAdditionalProcessingWithServerResponseDict:dict];
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
            me.needsRefresh = NO;
            me.lastFetched = NSDate.date;
            [me cacheContents];
            if (me.onPageLoaded) {
                me.onPageLoaded(reallyNewItems);
            }
            [me trigger:SGItemSetFetchSucceeded withContext:reallyNewItems];
        });
    });
}

#pragma mark - Caching

+ (SGFileCache *)cache {
    static SGFileCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [SGFileCache cacheFor:NSStringFromClass(self)];
        cache.maxDiskCacheSizeMB = 0;   // unlimited cache size
        [cache clearExpiredFiles];
    });
    return cache;
}

- (SGFileCache *)cache {
    return self.class.cache;
}

- (void)setCacheKey:(NSString *)cacheKey {
    _cacheKey = cacheKey;
    [self loadCachedContents];
}

- (NSString *)internalCacheKey {
    return self.cacheKey.length ? self.cacheKey : nil;
}

- (NSDate *)cacheExpiryDate {
    // expire after 1 month.  If it hasn't been used by then just get a fresh copy
    return [NSDate.date dateByAddingTimeInterval:2592000];
}

- (void)cacheContents {
    if (!self.internalCacheKey.length || !self.lastFetched) {
        return;
    }
    NSDictionary *cacheDict = @{@"items":self.items, @"lastFetched":self.lastFetched};
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cacheDict];
    [self.cache cacheData:data for:self.internalCacheKey expiryDate:self.cacheExpiryDate];
}

- (BOOL)haveCachedContents {
    return [self.cache hasCachedDataFor:self.internalCacheKey];
}

- (BOOL)loadCachedContents {
    if (!self.haveCachedContents) {
        return NO;
    }
    NSData *data = [self.cache cachedDataFor:self.internalCacheKey];
    NSDictionary *cachedContents = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (![cachedContents isKindOfClass:NSDictionary.class]) {
        return NO;
    }
    self.items = [cachedContents[@"items"] mutableCopy];
    self.lastFetched = cachedContents[@"lastFetched"];
    for (SGItem *item in self.items) {
        item.parentSet = self;
    }
    return YES;
}

#pragma mark - Setters

- (void)setMeta:(NSDictionary *)meta {
    _meta = meta;
    self.lastFetchedPage = [meta[@"page"] intValue];
}

- (void)setNeedsRefresh {
    self.needsRefresh = YES;
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

- (NSUInteger)total {
    return [self.meta[@"total"] unsignedIntegerValue];
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
