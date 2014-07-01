//
//  Created by matt on 7/01/13.
//

#import "SGItem.h"

/**
* The `SGPerformer` model wraps individual item results from the
* [/performers](http://platform.seatgeek.com/#events) endpoint.
* `SGPerformer` extends from <SGItem>, which contains properties common to all item
* types.
*/

@interface SGPerformer : SGItem

/** @name Performer properties */

/**
* The performer's name.
*/
@property (nonatomic, readonly, copy) NSString *name;

/**
Either the same as <name> or a shortened name if one is available.

    name = "New York Mets"
    shortName = "Mets"
*/
@property (nonatomic, readonly, copy) NSString *shortName;

/**
* A unique [slug](http://en.wikipedia.org/wiki/Slug_(web_publishing)#Slug) for the
* performer.
*/
@property (nonatomic, readonly, copy) NSString *slug;

/**
* The performers's most specific [taxonomy](<taxonomies>).
*/
@property (nonatomic, readonly, copy) NSString *type;

/**
* An array of taxonomies, from least specific to most specific.
*/
@property (nonatomic, readonly, strong) NSArray *taxonomies;

/**
* A URL for an image of the performer.
*/
@property (nonatomic, readonly, copy) NSString *imageURL;

/**
* URLs for images of the performer at varying sizes.
*/
@property (nonatomic, readonly, strong) NSDictionary *images;

/**
* Links to the performer on other services across the web.
*/
@property (nonatomic, readonly, strong) NSArray *links;

/**
* Will be YES if the performer has upcoming events.
*/
@property (nonatomic, readonly, assign) BOOL hasUpcomingEvents;

/**
* The ID for the performer's home venue, if one exists.
*/
@property (nonatomic, readonly, strong) NSNumber *homeVenueId;

@end
