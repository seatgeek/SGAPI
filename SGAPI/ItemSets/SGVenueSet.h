//
//  Created by matt on 30/05/14.
//

#import "SGItemSet.h"
#import "SGQuery.h"
#import "SGVenue.h"

/**
`SGVenueSet` provides paginated results of `SGVenue` items by quering the
[/venues](http://platform.seatgeek.com/#venues) endpoint. `SGVenueSet`
extends from <SGItemSet>, which provides the base result fetching and pagination
interface.

    SGVenueSet *venues = [SGVenueSet setForCity:@"rockford"];

    venues.onPageLoaded = ^(NSOrderedSet *results) {
        for (SGVenue *venue in results) {
            NSLog(@"venue: %@", venue.name);
        }
    };

    [venues fetchNextPage];
*/

@interface SGVenueSet : SGItemSet

/** @name Creating a set */

/**
Returns a new `SGVenueSet` instance for the
[/venues](http://platform.seatgeek.com/#venues) endpoint. Modify the
[query](-[SGItemSet query]) to add parameters and filters.

    SGVenueSet *venues = SGVenueSet.venuesSet;
    venues.query.search = @"yankee stadium";
*/
+ (instancetype)venuesSet;

/** @name Creating a set with a base filter */

/**
Returns a new `SGVenueSet` instance for the
[/venues](http://platform.seatgeek.com/#venues) endpoint with a city filter
applied.

    SGVenueSet *venues = [SGVenueSet setForCity:@"rockford"];
*/
+ (instancetype)setForCity:(NSString *)city;

/**
Returns a new `SGVenueSet` instance for the
[/venues](http://platform.seatgeek.com/#venues) endpoint with a state filter
applied.

    SGVenueSet *venues = [SGVenueSet setForState:@"IL"];
*/
+ (instancetype)setForState:(NSString *)state;

/**
Returns a new `SGVenueSet` instance for the
[/venues](http://platform.seatgeek.com/#venues) endpoint with a country filter
applied.

    SGVenueSet *venues = [SGVenueSet setForCountry:@"US"];
*/
+ (instancetype)setForCountry:(NSString *)country;

/**
Returns a new `SGVenueSet` instance for the
[/venues](http://platform.seatgeek.com/#venues) endpoint with a postal code filter
applied.

    SGVenueSet *venues = [SGVenueSet setForPostalCode:@(90210)];
*/
+ (instancetype)setForPostalCode:(NSString *)postalCode;

@end
