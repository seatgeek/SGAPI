//
//  Created by matt on 18/01/14.
//

#import "SGEventSet.h"
#import "SGPerformer.h"
#import "SGVenue.h"

@implementation SGEventSet

#pragma mark - Set Factories

+ (instancetype)eventsSet {
    SGEventSet *events = self.new;
    events.query = SGQuery.eventsQuery;
    events.resultArrayKey = @"events";
    return events;
}

+ (instancetype)recommendationsSet {
    SGEventSet *events = self.new;
    events.query = SGQuery.recommendationsQuery;
    events.resultArrayKey = @"recommendations";
    return events;
}

+ (instancetype)setForVenue:(SGVenue *)venue {
    SGEventSet *events = self.eventsSet;
    [events.query addFilter:@"venue.id" value:venue.ID];
    return events;
}

+ (instancetype)setForPerformer:(SGPerformer *)performer {
    SGEventSet *events = self.eventsSet;
    [events.query addFilter:@"performers.id" value:performer.ID];
    return events;
}

#pragma mark - Item Factory

- (id)itemForDict:(NSDictionary *)dict {
    return dict[@"event"]
          ? [SGEvent itemForDict:dict[@"event"]]
          : [SGEvent itemForDict:dict];
}

@end
