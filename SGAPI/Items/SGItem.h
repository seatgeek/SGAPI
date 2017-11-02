//
//  Created by matt on 7/01/13.
//

#define SGItemFetchStarted @"SGItemFetchStarted"
#define SGItemFetchSucceeded @"SGItemFetchSucceeded"
#define SGItemFetchFailed @"SGItemFetchFailed"

@class SGItemSet, SGQuery, SGDataManager, SGFileCache;

/**
* `SGItem` is the abstract model class for result items. The concrete models
* are <SGEvent>, <SGPerformer>, <SGVenue>.
*/

@interface SGItem : NSObject <NSCoding>

#pragma mark - Fields

/** @name Properties common to all item types */

/**
* The type specific unique ID for the API result item.
*/
@property (nullable, nonatomic, readonly, strong) NSString *ID;

/**
* The item's [seatgeek.com](http://seatgeek.com) website URL.
*/
@property (nullable, nonatomic, readonly, copy) NSString *url;

/**
* `score` indicates the item's relative popularity within its type. Scores are
* floating point values in the range of 0 to 1. See
* [SeatGeek Platform docs](http://platform.seatgeek.com) for further details.
*/
@property (nullable, nonatomic, readonly, strong) NSNumber *score;

/**
* Type specific statistics for the result item. For example an event item might
* include a listing count and average/high/low price values.
*/
@property (nullable, nonatomic, readonly, strong) NSDictionary *stats;

/**
* Some result items have a `title` value and some a `name`. For convenience
* both can be accessed via `title`.
*/
- (nullable NSString *)title;

#pragma mark - Fetching and caching

/** @name Fetching and caching */

@property (nullable, nonatomic, strong) SGQuery *query;
- (nullable NSString *)cacheKey;

/**
* Fetch the results based on the item's ID. If the item is already <fetching>
* `fetch` will do nothing.
*/
- (void)fetch;

/**
 * Calls `fetch` on the item and recursively on all of its child items.
 * If one of these items is already <fetching> or does not <needsRefresh>,
 * then its `fetch` will do nothing.
 */
- (void)fetchItemAndChildrenIfNeeded;

/**
* Returns YES if a fetch is in progress.
*/
- (BOOL)fetching;

/**
 * The date of last successful fetch
 */
@property (nullable, nonatomic, strong) NSDate *lastFetched;

/**
 * Seconds since `lastFetched`
 */
- (NSTimeInterval)fetchAge;

/**
 * Some endpoints return partial item documents when returning arrays.
 * This property will be true in those cases.
 */
- (BOOL)hasPartialContents;

/**
 * Replace current contents with contents from cache. Returns NO if nothing found in cache.
 */
- (BOOL)loadCachedContents;

/**
 * Force the item contents to be cached again. Requires `cacheKey` to be set.
 */
- (void)cacheContents;

/**
 * If this method returns YES (the default) item sets will cache their contents on successful fetch,
 * when a cache key has been provided.
 */
- (BOOL)shouldCacheOnFetch;

/**
 * The date for cached items to expire.
 * Defaults to 1 month.
 */
@property (nonatomic, strong, nullable) NSDate *cacheExpiryDate;

/// the SGFileCache for this class
+ (nonnull SGFileCache *)cache;

#pragma mark - Composite properties

/** @name Composite properties */

@property (nonatomic, weak, nullable) SGItemSet *parentSet;
@property (nonatomic, weak, nullable) SGItem *parentItem;
- (nullable NSArray *)childItems;

#pragma mark - Raw results

/** @name Raw result data */

/**
* The raw API result dictionary.
*/
@property (nullable, nonatomic, strong) NSDictionary *dict;

+ (nonnull NSDateFormatter *)localDateParser;
+ (nonnull NSDateFormatter *)utcDateParser;

#pragma mark - Data Manager

@property (nullable, nonatomic, weak) SGDataManager *dataManager;
- (void)setNeedsRefresh;
- (BOOL)needsRefresh;

#pragma mark - Ignore plz

+ (nonnull NSDictionary *)resultFields;
@property (nonnull, nonatomic, copy) NSString *resultItemKey;
+ (nonnull id)itemForDict:(nullable NSDictionary *)dict;
+ (nullable id)valueFor:(nullable id)value withType:(nonnull Class)requiredType;
- (nullable NSError *)lastFetchError;

@end
