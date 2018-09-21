//
//  Created by matt on 27/05/14.
//

#import <CoreLocation/CoreLocation.h>
#ifndef SGHTTPREQUEST
#define SGHTTPREQUEST <SGHTTPRequest/SGHTTPRequest.h>
#endif
#import SGHTTPREQUEST

#define SGAPI_BASEFORMAT @"https://api.%@/2"
#define SGAPI_BASEDOMAIN @"seatgeek.com"

#ifndef __weakSelf
#define __weakSelf __weak typeof(self)
#endif

/**
* `SGQuery` builds URLs for querying the SeatGeek Platform. See the
* [SeatGeek Platform docs](http://platform.seatgeek.com/) for available endpoints
* and parameters.
*/

@interface SGQuery : NSObject

/** @name Setup */

/**
Some SeatGeek Platform endpoints require an
[API key](https://seatgeek.com/account/develop). Set `clientId` to your API key
in your AppDelegate's `application:didFinishLaunchingWithOptions:`

    SGQuery.clientId = @"my_API_key";
*/
+ (void)setClientId:(nonnull NSString *)clientId;

/**
 Some SeatGeek Platform endpoints require an
 [API key](https://seatgeek.com/account/develop). Set `clientSecret` to your client secret
 in your AppDelegate's `application:didFinishLaunchingWithOptions:`

 SGQuery.clientSecret = @"my_client_secret";
 */
+ (void)setClientSecret:(nonnull NSString *)clientSecret;

/**
An optional `aid` value to append to all queries. Set this value in your
AppDelegate's `application:didFinishLaunchingWithOptions:`

    SGQuery.aid = @"my_aid";
*/
+ (void)setAid:(nonnull NSString *)aid;

/**
 An optional `pid` value to append to all queries. Set this value in your
 AppDelegate's `application:didFinishLaunchingWithOptions:`

 SGQuery.pid = @"my_pid";
 */
+ (void)setPid:(nonnull NSString *)pid;

/**
An optional `rid` value to append to all queries. Set this value in your
AppDelegate's `application:didFinishLaunchingWithOptions:`

     SGQuery.rid = @"my_rid";
*/
+ (void)setRid:(nonnull NSString *)rid;

/**
* Output debug information to console. Default is NO.
*/
+ (void)setConsoleLogging:(BOOL)logging;
+ (BOOL)consoleLogging;

#pragma mark - Events

/** @name Event queries */

/**
* Returns a new `SGQuery` instance for the
* [/events](http://platform.seatgeek.com/#events) endpoint.
*/
+ (nonnull SGQuery *)eventsQuery;

/**
* Returns a new `SGQuery` instance for the `/recommendations` endpoint.
* @warning The [/recommendations](http://platform.seatgeek.com/#recommendations)
* endpoint requires an API key. See <setClientId:> for details.
*/
+ (nonnull SGQuery *)recommendationsQuery;

/**
* Returns a new `SGQuery` instance for fetching a single event by id.
*/
+ (nonnull SGQuery *)eventQueryForId:(nonnull NSNumber *)eventId;

#pragma mark - Performers

/** @name Performer queries */

/**
* Returns a new `SGQuery` instance for the
* [/performers](http://platform.seatgeek.com/#performers) endpoint.
*/
+ (nonnull SGQuery *)performersQuery;

/**
* Returns a new `SGQuery` instance for fetching a single performer by id.
*/
+ (nonnull SGQuery *)performerQueryForId:(nonnull NSNumber *)performerId;

/**
* Returns a new `SGQuery` instance for fetching a single performer by slug.
*/
+ (nonnull SGQuery *)performerQueryForSlug:(nonnull NSString *)slug;

#pragma mark - Venues

/** @name Venue queries */

/**
* Returns a new `SGQuery` instance for the
* [/venues](http://platform.seatgeek.com/#venues) endpoint.
*/
+ (nonnull SGQuery *)venuesQuery;

/**
* Returns a new `SGQuery` instance for fetching a single venue by id.
*/
+ (nonnull SGQuery *)venueQueryForId:(nonnull NSNumber *)venueId;

#pragma mark - The Payoff

/** @name The payoff */

/**
Returns an `NSURL` for the constructed API query.

    SGQuery *query = SGQuery.eventsQuery;
    query.search = @"imagine dragons";

    NSLog(@"%@", query.URL);
    // https://api.seatgeek.com/2/events?q=imagine+dragons
*/
@property (nonnull, readonly) NSURL *URL;

- (nonnull SGHTTPRequest *)requestWithMethod:(SGHTTPRequestMethod)method;

#pragma mark - Pagination

/** @name Pagination */

/**
* The results page to fetch. Page numbers start from 1.
*/
@property (nonatomic, assign) NSUInteger page;

/**
* The number of results to return per page. Default is 10.
*/
@property (nonatomic, assign) NSUInteger perPage;

#pragma mark - Keyword searches

/** @name Keyword searches */

/**
Apply a keyword search to the query.

    SGQuery *query = SGQuery.eventsQuery;
    query.search = @"imagine dragons";
*/
@property (nonatomic, copy, nullable) NSString *search;

#pragma mark - Location Parameters (for 'events' and 'venues')

/** @name Geolocation filters */

/**
* Filter results by a location coordinate.
*/
@property (nonatomic, assign) CLLocationCoordinate2D location;

/**
* Clears the location parameter
*/
- (void)clearLocation;

/**
* Specify a range for location based filters. Accepts miles ("mi") and kilometres
* ("km"). Default is "30mi".
*/
@property (nonatomic, copy, nullable) NSString *range;

#pragma mark - Date Range Parameters (for 'events')

/**
 * Specify a from date (inclusive) for results
 */
@property (nonatomic, copy, nullable) NSDate *fromDate;

/**
 * Specify a to date (inclusive) for results
 */
@property (nonatomic, copy, nullable) NSDate *toDate;

#pragma mark - Freeform Parameters and Filters

/** @name Other parameters and filters */

/**
Set a query parameter. Setting a parameter will override its previous value.
See the [API docs](http://platform.seatgeek.com/) for available parameters.

    [query setParameter:@"format" value:@"xml"];
    [query setParameter:@"sort" value:@"announce_date.desc"];
*/
- (void)setParameter:(nonnull NSString *)param value:(nullable id)value;

/**
Add a results filter. Filters are stacked, and the same filters can be applied multiple times with different values. See the
[API docs](http://platform.seatgeek.com/) for available filters.

    [query addFilter:@"performers.slug" value:@"new-york-mets"];
    [query addFilter:@"performers.slug" value:@"new-york-yankees"];
*/
- (void)addFilter:(nonnull NSString *)filter value:(nullable id)value;

@property (nonatomic, strong, nullable) NSDictionary *requestHeaders;

// ignore plz
// note: these constructors truncate query params!
+ (nonnull SGQuery *)queryWithPath:(nonnull NSString *)path;
+ (nonnull SGQuery *)queryWithBaseUrl:(nonnull NSString *)baseUrl;
+ (nonnull SGQuery *)queryWithBaseUrl:(nullable NSString *)baseUrl path:(nullable NSString *)path;
+ (nonnull NSMutableDictionary *)globalParameters;
+ (nonnull NSString *)defaultBaseDomain;
+ (nonnull NSString *)baseURL;
+ (void)setBaseURL:(nonnull NSString *)url;
- (void)setPath:(nullable NSString *)path;
- (void)rebuildQuery;

@end
