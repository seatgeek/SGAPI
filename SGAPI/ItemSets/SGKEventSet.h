//
//  Created by matt on 18/01/14.
//

#import "SGItemSet.h"
#import "SGQuery.h"
#import "SGKEvent.h"

/**
`SGKEventSet` provides paginated results of `SGKEvent` items by quering the
[/events](http://platform.seatgeek.com/#events) and
[/recommendations](http://platform.seatgeek.com/#recommendations) endpoints. `SGKEventSet` extends from <SGItemSet>, which provides the base result
fetching and pagination interface.

 SGKEventSet *events = SGKEventSet.eventsSet;
    events.query.search = @"new york mets";

    events.onPageLoaded = ^(NSOrderedSet *results) {
        for (SGKEvent *event in results) {
            NSLog(@"event: %@", event.title);
        }
    };

    [events fetchNextPage];
*/

@interface SGKEventSet : SGItemSet

/** @name Creating a set */

/**
Returns a new `SGKEventSet` instance for the
[/events](http://platform.seatgeek.com/#events) endpoint. Modify the
[query](-[SGItemSet query]) to add parameters and filters.

    SGKEventSet *events = SGKEventSet.eventsSet;
    events.query.search = @"new york mets";
*/
+ (instancetype)eventsSet;

/**
Returns a new `SGKEventSet` instance for the
[/recommendations](http://platform.seatgeek.com/#recommendations) endpoint. A recommendations query should be seeded with an event or one or more performers.

Events similar to Taylor Swift in New York:

    SGKEventSet *events = SGKEventSet.recommendationsSet;
    [events.query addFilter:@"performers.id" value:@(35)];
    [events.query addFilter:@"postal_code" value:@(10014)];

Events similar to an event in New York:

    SGKEventSet *events = SGKEventSet.recommendationsSet;
    [events.query addFilter:@"events.id" value:@(1162104)];
    [events.query addFilter:@"postal_code" value:@(10014)];

@warning The [/recommendations](http://platform.seatgeek.com/#recommendations)
endpoint requires an API key. See [SGQuery.clientId](+[SGQuery setClientId:])
for details.
*/
+ (instancetype)recommendationsSet;

/** @name Creating a set with a base filter */

/**
* Returns a new `SGKEventSet` instance for the
* [/events](http://platform.seatgeek.com/#events) endpoint with a venue filter
* applied.
*/
+ (instancetype)setForVenue:(SGVenue *)venue;

/**
* Returns a new `SGKEventSet` instance for the
* [/events](http://platform.seatgeek.com/#events) endpoint with a performer filter
* applied.
*/
+ (instancetype)setForPerformer:(SGPerformer *)performer;

@end
