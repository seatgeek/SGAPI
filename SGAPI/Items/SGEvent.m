//
//  Created by matt on 7/01/13.
//

#import "SGEvent.h"
#import "SGVenue.h"
#import "SGPerformer.h"

@implementation SGEvent

+ (NSDictionary *)resultFields {
    return @{
            @"ID":@"id",
            @"title":@"title",
            @"shortTitle":@"short_title",
            @"score":@"score",
            @"url":@"url",
            @"type":@"type",
            @"taxonomies":@"taxonomies",
            @"stats":@"stats",
            @"links":@"links"
    };
}

#pragma mark - Setters

- (void)setDict:(NSDictionary *)dict {
    super.dict = dict;

    @synchronized (self.class.localDateParser) {
        _localDate = [self.class.localDateParser dateFromString:dict[@"datetime_local"]];
        _utcDate = [self.class.utcDateParser dateFromString:dict[@"datetime_utc"]];
        _announceDate = [self.class.utcDateParser dateFromString:dict[@"announce_date"]];
        _visibleUntil = [self.class.utcDateParser dateFromString:dict[@"visible_until_utc"]];
        _createdAt = [self.class.utcDateParser dateFromString:dict[@"created_at"]];
    }

    _generalAdmission = [dict[@"general_admission"] boolValue];
    _timeTbd = [dict[@"time_tbd"] boolValue];
    _dateTbd = [dict[@"date_tbd"] boolValue];

    self.venue = [SGVenue itemForDict:dict[@"venue"]];

    NSMutableArray *performers = @[].mutableCopy;
    for (NSDictionary *performerDict in dict[@"performers"]) {
        SGPerformer *performer = [SGPerformer itemForDict:performerDict];
        [performers addObject:performer];
        if (performerDict[@"primary"]) {
            self.primaryPerformer = performer;
        }
    }
    self.performers = performers;
}

@end
