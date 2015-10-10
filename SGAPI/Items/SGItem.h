//
//  Created by matt on 7/01/13.
//

@class SGItemSet;

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

/**
 * The date of last successful fetch
 */
@property (nullable, nonatomic, strong) NSDate *lastFetched;

#pragma mark - Composite properties

@property (nonatomic, weak) SGItemSet *parentSet;
@property (nonatomic, weak) SGItem *parentItem;

#pragma mark - Raw results

/** @name Raw result data */

/**
* The raw API result dictionary.
*/
@property (nullable, nonatomic, strong) NSDictionary *dict;

+ (nonnull NSDateFormatter *)localDateParser;
+ (nonnull NSDateFormatter *)utcDateParser;

#pragma mark - Ignore plz

+ (nonnull NSDictionary *)resultFields;
+ (nonnull id)itemForDict:(nullable NSDictionary *)dict;
+ (nullable id)valueFor:(nullable id)value withType:(nonnull Class)requiredType;
- (void)setNeedsRefresh;
- (BOOL)needsRefresh;

@end
