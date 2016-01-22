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
            @"links":@"links",
            @"generalAdmission":@"general_admission",
            @"timeTbd":@"time_tbd",
            @"dateTbd":@"date_tbd"

    };
}

- (void)setupRelationships {
    self.venue = [SGVenue itemForDict:self.dict[@"venue"]];
    self.venue.parentItem = self;

    NSMutableArray *performers = @[].mutableCopy;
    for (NSDictionary *performerDict in self.dict[@"performers"]) {
        SGPerformer *performer = [SGPerformer itemForDict:performerDict];
        performer.parentItem = self;
        [performers addObject:performer];
        if (performerDict[@"primary"]) {
            self.primaryPerformer = performer;
        }
    }
    self.performers = performers;
}

#pragma mark - Setters

- (void)setDict:(NSDictionary *)dict {
    super.dict = dict;

    @synchronized (self.class.localDateParser) {
        _localDate = [self.class.localDateParser dateFromString:self.dict[@"datetime_local"]];
        _utcDate = [self.class.utcDateParser dateFromString:self.dict[@"datetime_utc"]];
        _announceDate = [self.class.utcDateParser dateFromString:self.dict[@"announce_date"]];
        _visibleUntil = [self.class.utcDateParser dateFromString:self.dict[@"visible_until_utc"]];
        _createdAt = [self.class.utcDateParser dateFromString:self.dict[@"created_at"]];
    }

    [self setupRelationships];
}

@end
