//
//  Created by matt on 7/01/13.
//

#import <CoreLocation/CoreLocation.h>
#import "SGItem.h"

/**
* The `SGVenue` model wraps individual item results from the
* [/venues](http://platform.seatgeek.com/#events) endpoint.
* `SGVenue` extends from <SGItem>, which contains properties common to all item
* types.
*/

@interface SGVenue : SGItem

/** @name Performer properties */

/**
* The venue name.
*/
@property (nonatomic, readonly, copy) NSString *name;

/**
* A unique [slug](http://en.wikipedia.org/wiki/Slug_(web_publishing)#Slug) for the
* venue.
*/
@property (nonatomic, readonly, copy) NSString *slug;

/**
* The venue's street address.
*/
@property (nonatomic, readonly, copy) NSString *address;

/**
* A second line of the venue's address, if one exists.
*/
@property (nonatomic, readonly, copy) NSString *extendedAddress;

/**
* The venue's city.
*/
@property (nonatomic, readonly, copy) NSString *city;

/**
* The venue's state.
*/
@property (nonatomic, readonly, copy) NSString *state;

/**
* The venue's country.
*/
@property (nonatomic, readonly, copy) NSString *country;

/**
* The venues postal code.
*/
@property (nonatomic, readonly, strong) NSString *postalCode;

/**
* A string of the format "<city>, <state>, <postalCode>" for US/Canada
* and "<city>, <country>" for everywhere else.
*/
@property (nonatomic, readonly, copy) NSString *displayLocation;

/**
* The venue's location coordinate, if known.
*/
@property (nonatomic, readonly, assign) CLLocationCoordinate2D location;

/**
* A timezone string for the venue. eg "America/New_York".
*/
@property (nonatomic, readonly, copy) NSString *timezone;

/**
* A URL for an image of the venue, if one is available.
*/
@property (nonatomic, readonly, copy) NSString *imageURL;

#pragma mark - Helpers

/** @name Helpers */

/**
* Returns YES if the location isn't {0, 0}.
*/
- (BOOL)locationIsValid;

@end
