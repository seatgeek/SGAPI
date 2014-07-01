//
//  Created by matt on 18/01/14.
//

#import "SGItemSet.h"
#import "SGQuery.h"
#import "SGPerformer.h"

/**
`SGPerformerSet` provides paginated results of `SGPerformer` items by quering the
[/performers](http://platform.seatgeek.com/#performers) endpoint. `SGPerformerSet`
extends from <SGItemSet>, which provides the base result fetching and pagination
interface.

    SGPerformerSet *performers = SGPerformerSet.performersSet;
    performers.query.search = @"imagine dragons";

    performers.onPageLoaded = ^(NSOrderedSet *results) {
        for (SGPerformer *performer in results) {
            NSLog(@"performer: %@", performer.name);
        }
    };

    [performers fetchNextPage];
*/

@interface SGPerformerSet : SGItemSet

/**
Returns a new `SGPerformerSet` instance for the
[/performers](http://platform.seatgeek.com/#performers) endpoint. Modify the
[query](-[SGItemSet query]) to add parameters and filters.

    SGPerformerSet *performers = SGPerformerSet.performersSet;
    performers.query.search = @"imagine dragons";
*/
+ (instancetype)performersSet;

@end
