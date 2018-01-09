//
//  Created by matt on 18/01/14.
//

#import <Foundation/Foundation.h>
#import <SGAPI/SGItem.h>

#define SGItemSetFetchStarted @"SGItemSetFetchStarted"
#define SGItemSetFetchSucceeded @"SGItemSetFetchSucceeded"
#define SGItemSetFetchFailed @"SGItemSetFetchFailed"

@class SGQuery, SGDataManager;

/**
* `SGItemSet` is the abstract base class for item sets, providing the core
* request handling and pagination. Create instances of `SGEventSet`,
* `SGPerformerSet`, and `SGVenueSet` to fetch paginated results.
*/

@interface SGItemSet : SGItem

#pragma mark - Subclasses implement / override

/** Subclasses must implement this */
- (nonnull id)itemForDict:(nonnull NSDictionary *)dict;

/**
 * Subclasses can implement this method to pull other data out of the server
 * response and set their properties.
 */
- (void)doAdditionalProcessingWithServerResponseDict:(nonnull NSDictionary *)dict;

#pragma mark - Modifying the API query

/** @name Modifying the API query */

/**
An <SGQuery> instance for defining the parameters and filters of the API query.

    SGEventSet *events = SGEventSet.eventsQuery;
    events.query.search = @"new york mets";
    events.query.perPage = 30;
*/
@property (nullable, nonatomic, strong) SGQuery *query;

#pragma mark - State change callbacks

/** @name State change callbacks */

/**
A block assigned to `onPageLoaded` will be called after each result page
request has completed.

    events.onPageLoaded = ^(NSOrderedSet *results) {
        for (SGEvent *event in results) {
            NSLog(@"event: %@", event.title);
        }
    };
*/
@property (nullable, nonatomic, copy) void (^onPageLoaded)(NSOrderedSet* __nonnull newItems);

/**
 A block assigned to `onPageLoadFailed` will be called after a page request
 failed to load.

 events.onPageLoadFailed = ^(NSError *error) {
 NSLog(@"error: %@", error);
 };
 */
@property (nullable, nonatomic, copy) void (^onPageLoadFailed)(NSError* __nonnull error);

/**
 A block assigned to `onPageLoadRetry` will be called after a page request
 failed to load, and then begins to fetch again due to network reachability

 events.onPageLoadRetry = ^ {
 [self showLoadingSpinner];
 };
 */
@property (nullable, nonatomic, copy) void (^onPageLoadRetry)(void);

#pragma mark - Fetching results

/** @name Fetching results */

/**
* Fetch the next page of results. If the set is already <fetching>
* `fetchNextPage` will do nothing. If all results have already been fetched
* (<lastPageAlreadyFetched>) `fetchNextPage` will do nothing.
*/
- (void)fetchNextPage;

/**
* Fetch a specific page of results. Usually you will want to call
* `fetchNextPage` instead, but in some cases you may want to refetch a specific
* page.
*
* Note that item sets contain only unique items, so a page refetch will only
* add any new results to the set, without duplicates. If the <query> hasn't
* been modified then most likely no new items will be added.
*/
- (void)fetchPage:(int)page;

/**
* Cancel an in progress results fetch.
*/
- (void)cancelFetch;

/**
* Returns YES if the last page of results has already been fetched.
*/
- (BOOL)lastPageAlreadyFetched;

/**
* Returns YES if a results fetch is in progress.
*/
- (BOOL)fetching;

#pragma mark - Content inspection

/** @name Content inspection */

/**
 * The date of last successful fetch
 */
- (nullable NSDate *)lastFetched;

/**
* Returns the page number of the last fetched page.
*/
- (int)lastFetchedPage;

/**
* Returns the total number of pages available for the <query>. Note that if
* no pages have been fetched yet, `totalPages` will return 0.
*/
- (int)totalPages;

/**
* Returns an `NSArray` of the items in the set.
*/
- (nullable NSArray *)array;

/**
* Returns an `NSOrderedSet` of the items in the set.
*/
- (nullable NSOrderedSet *)orderedSet;

/**
* Returns the first item in the set.
*/
- (nullable id)firstObject;

/**
* Returns the last item in the set.
*/
- (nullable id)lastObject;

/**
* Returns a count of the items in the set so far. Note that this is not the
* total available for the query, but instead the number of items fetched so far.
*/
- (NSUInteger)count;

/**
 * Returns a total number of the items in the set. Note that this is not the
 * number of items received so far, but instead the total number of items in all pages.
 */
- (NSUInteger)total;

#pragma mark - Caching results

/** @name Caching results */

/**
 * Set cacheKey to a unique value within the item set class's context and the item set
 * will immediately restore any matching previous results from cache, and will save
 * any future results to cache, for restoring between sessions.
 */
@property (nullable, nonatomic, strong) NSString *cacheKey;

/**
 * Force the result items to be cached again. Requires `cacheKey` to be set.
 */
- (void)cacheContents;

/** @name Resetting internal state */

/**
* Reset the internal state of the set. Note that this doesn't reset the <query>
* parameters. After being reset, a subsequent <fetchNextPage> will fetch the
* first page of results.
*/
- (void)reset;

#pragma mark - Status bar indicator

/** @name Status bar indicator */

/**
* Whether to show a status bar activity indicator while fetching results.
* Default is YES.
*/
@property (nonatomic, assign) BOOL allowStatusBarSpinner;

#pragma mark - Composite properties

@property (nonatomic, weak, nullable) SGItemSet *parentSet;
@property (nonatomic, weak, nullable) SGItem *parentItem;

#pragma mark - Ignore plz

@property (nonnull, nonatomic, copy) NSString *resultArrayKey;
@property (nullable, nonatomic, strong, readonly) NSDictionary *meta;
- (nullable id)objectAtIndexedSubscript:(NSUInteger)index;
- (nullable NSDictionary *)lastResponseDict;
@property (nullable, nonatomic, weak) SGDataManager *dataManager;
- (void)setNeedsRefresh;
- (BOOL)needsRefresh;

@end
