//
//  Created by matt on 18/01/14.
//

#import "SGKEventSet.h"
#import "SGPerformer.h"
#import "SGVenue.h"
#import "SGKEvent.h"
#import "SGQuery.h"

@implementation SGKEventSet

#pragma mark - Set Factories

+ (instancetype)eventsSet {
    SGKEventSet *events = self.new;
    events.query = SGQuery.eventsQuery;
    events.resultArrayKey = @"events";
    return events;
}

+ (instancetype)recommendationsSet {
    SGKEventSet *events = self.new;
    events.query = SGQuery.recommendationsQuery;
    events.resultArrayKey = @"recommendations";
    return events;
}

+ (instancetype)setForVenue:(SGVenue *)venue {
    SGKEventSet *events = self.eventsSet;
    [events.query addFilter:@"venue.id" value:venue.ID];
    return events;
}

+ (instancetype)setForPerformer:(SGPerformer *)performer {
    SGKEventSet *events = self.eventsSet;
    [events.query addFilter:@"performers.id" value:performer.ID];
    return events;
}

#pragma mark - Item Factory

- (id)itemForDict:(NSDictionary *)dict {
    return dict[@"event"]
          ? [SGKEvent itemForDict:dict[@"event"]]
          : [SGKEvent itemForDict:dict];
}

@end
