//
//  Created by matt on 30/05/14.
//

#import "SGVenueSet.h"

@implementation SGVenueSet

+ (instancetype)venuesSet {
    SGVenueSet *venues = self.new;
    venues.query = SGQuery.venuesQuery;
    venues.resultArrayKey = @"venues";
    return venues;
}

+ (instancetype)setForCity:(NSString *)city {
    SGVenueSet *venues = self.venuesSet;
    [venues.query addFilter:@"city" value:city];
    return venues;
}

+ (instancetype)setForState:(NSString *)state {
    SGVenueSet *venues = self.venuesSet;
    [venues.query addFilter:@"state" value:state];
    return venues;
}

+ (instancetype)setForCountry:(NSString *)country {
    SGVenueSet *venues = self.venuesSet;
    [venues.query addFilter:@"country" value:country];
    return venues;
}

+ (instancetype)setForPostalCode:(NSString *)postalCode {
    SGVenueSet *venues = self.venuesSet;
    [venues.query addFilter:@"postal_code" value:postalCode];
    return venues;
}

#pragma mark - Item Factory

- (id)itemForDict:(NSDictionary *)dict {
    return dict[@"venue"]
          ? [SGVenue itemForDict:dict[@"venue"]]
          : [SGVenue itemForDict:dict];
}

@end
