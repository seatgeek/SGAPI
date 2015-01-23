//
//  Created by matt on 7/01/13.
//

/**
* `SGItem` is the abstract model class for result items. The concrete models
* are <SGEvent>, <SGPerformer>, <SGVenue>.
*/

@interface SGItem : NSObject

#pragma mark - Fields

/** @name Properties common to all item types */

/**
* The type specific unique ID for the API result item.
*/
@property (nonatomic, readonly, strong) NSString *ID;

/**
* The item's [seatgeek.com](http://seatgeek.com) website URL.
*/
@property (nonatomic, readonly, copy) NSString *url;

/**
* `score` indicates the item's relative popularity within its type. Scores are
* floating point values in the range of 0 to 1. See
* [SeatGeek Platform docs](http://platform.seatgeek.com) for further details.
*/
@property (nonatomic, readonly, strong) NSNumber *score;

/**
* Type specific statistics for the result item. For example an event item might
* include a listing count and average/high/low price values.
*/
@property (nonatomic, readonly, strong) NSDictionary *stats;

/**
* Some result items have a `title` value and some a `name`. For convenience
* both can be accessed via `title`.
*/
- (NSString *)title;

#pragma mark - Raw results

/** @name Raw result data */

/**
* The raw API result dictionary.
*/
@property (nonatomic, strong) NSDictionary *dict;

+ (NSDateFormatter *)localDateParser;
+ (NSDateFormatter *)utcDateParser;

// ignore plz
+ (NSDictionary *)resultFields;
+ (id)itemForDict:(NSDictionary *)dict;
+ (id)valueFor:(id)value withType:(Class)requiredType;

@end
