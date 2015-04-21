//
//  Created by matt on 7/01/13.
//

#import "SGPerformer.h"

@implementation SGPerformer

+ (NSDictionary *)resultFields {
    return @{
            @"ID":@"id",
            @"name":@"name",
            @"url":@"url",
            @"score":@"score",
            @"shortName":@"short_name",
            @"slug":@"slug",
            @"type":@"type",
            @"imageURL":@"image",
            @"stats":@"stats",
            @"taxonomies":@"taxonomies",
            @"images":@"images",
            @"links":@"links",
            @"homeVenueId":@"home_venue_id"
    };
}
#pragma mark - Setters

- (void)setDict:(NSDictionary *)dict {
    super.dict = dict;

    _hasUpcomingEvents = [self.dict[@"has_upcoming_events"] boolValue];
}

#pragma mark - Getters

- (NSString *)title {
    return self.name;
}

@end
