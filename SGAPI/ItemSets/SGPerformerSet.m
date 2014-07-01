//
//  Created by matt on 18/01/14.
//

#import "SGPerformerSet.h"

@implementation SGPerformerSet

+ (instancetype)performersSet {
    SGPerformerSet *performers = self.new;
    performers.query = SGQuery.performersQuery;
    performers.resultArrayKey = @"performers";
    return performers;
}

#pragma mark - Item Factory

- (id)itemForDict:(NSDictionary *)dict {
    return dict[@"performer"]
          ? [SGPerformer itemForDict:dict[@"performer"]]
          : [SGPerformer itemForDict:dict];
}

@end
