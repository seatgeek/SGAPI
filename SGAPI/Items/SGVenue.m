//
//  Created by matt on 7/01/13.
//

#import "SGVenue.h"

@implementation SGVenue

+ (NSDictionary *)resultFields {
    return @{
            @"ID":@"id",
            @"name":@"name",
            @"slug":@"slug",
            @"url":@"url",
            @"score":@"score",
            @"address":@"address",
            @"extendedAddress":@"extended_address",
            @"city":@"city",
            @"state":@"state",
            @"country":@"country",
            @"postalCode":@"postal_code",
            @"imageURL":@"image",
            @"displayLocation":@"display_location",
            @"timezone":@"timezone",
            @"stats":@"stats"
    };
}

#pragma mark - Setters

- (void)setDict:(NSDictionary *)dict {
    super.dict = dict;

    if ([self.dict[@"location"][@"lat"] isKindOfClass:NSNumber.class]
          && [self.dict[@"location"][@"lon"] isKindOfClass:NSNumber.class]) {
        _location.latitude = [self.dict[@"location"][@"lat"] doubleValue];
        _location.longitude = [self.dict[@"location"][@"lon"] doubleValue];
    } else {
        _location = CLLocationCoordinate2DMake(0, 0);
    }
}

#pragma mark - Getters

- (NSString *)title {
    return self.name;
}

- (BOOL)locationIsValid {
    return self.location.latitude || self.location.longitude;
}

@end
