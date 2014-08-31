//
//  Created by matt on 7/01/13.
//

#import "SGItem.h"

@class SGVenue, SGPerformer;

/**
* The `SGEvent` model wraps individual item results from the
* [/events](http://platform.seatgeek.com/#events) and
* [/recommendations](http://platform.seatgeek.com/#recommendations) endpoints.
* `SGEvent` extends from <SGItem>, which contains properties common to all item
* types.
*/

@interface SGEvent : SGItem

#pragma mark - Relationships

/** @name Relationships */

/**
* An <SGVenue> instance for the event's venue.
*/
@property (nonatomic, strong) SGVenue *venue;

/**
* An array of <SGPerformer> instances for performers performing at the event.
*/
@property (nonatomic, strong) NSArray *performers;

/**
* An <SGPerformer> for the event's primary performer.
*/
@property (nonatomic, strong) SGPerformer *primaryPerformer;

- (void)setupRelationships;

#pragma mark - Fields

/** @name Event properties */

/**
* The event title.
*/
@property (nonatomic, readonly, copy) NSString *title;

/**
Either the same as <title> or a shortened event title if one is available.

    title      = "Milwaukee Brewers at New York Mets"
    shortTitle = "Brewers at Mets"
*/
@property (nonatomic, readonly, copy) NSString *shortTitle;

/**
* The event's most specific [taxonomy](<taxonomies>). eg `concert`,
* `music_festival`, `mlb`.
*/
@property (nonatomic, readonly, copy) NSString *type;

/**
* The event's date and time as at its location. For example an event advertised
* as starting at 6pm in NYC will have an 6pm `localDate`.
*/
@property (nonatomic, readonly, strong) NSDate *localDate;

/**
* The event's UTC date and time. For example  an event advertised as starting at 6pm
* in NYC will have an 11pm `utcDate` (EST == UTC - 5).
*/
@property (nonatomic, readonly, strong) NSDate *utcDate;

/**
* The UTC date for when the event was announced.
*/
@property (nonatomic, readonly, strong) NSDate *announceDate;

/**
* The UTC date for when the event will expire.
*/
@property (nonatomic, readonly, strong) NSDate *visibleUntil;

/**
* The UTC date for when the event was added to the database.
*/
@property (nonatomic, readonly, strong) NSDate *createdAt;

/**
* Whether the event is allocated seating or general admission.
*/
@property (nonatomic, readonly, assign) BOOL generalAdmission;

/**
* Will be YES if an exact start time is not yet known.
*/
@property (nonatomic, readonly, assign) BOOL timeTbd;

/**
* Will be YES if an exact date is not yet known.
*/
@property (nonatomic, readonly, assign) BOOL dateTbd;

/**
* An array of taxonomies, from least specific to most specific.
*/
@property (nonatomic, readonly, strong) NSArray *taxonomies;

/**
* Links to the event on other services across the web.
*/
@property (nonatomic, readonly, strong) NSArray *links;

@end
