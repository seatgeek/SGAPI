//
//  Created by matt on 25/06/14.
//

#import "NSDictionary+NullCleanse.h"

@implementation NSDictionary (NullCleanse)

- (NSDictionary *)nullCleansed {
    return [self nullCleanse:self];
}

- (NSDictionary *)nullCleanse:(NSDictionary *)dict {
    NSMutableDictionary *cleansed = dict.mutableCopy;
    for (id key in dict) {
        if ([dict[key] isKindOfClass:NSNull.class]) {
            [cleansed removeObjectForKey:key];
        } else if ([dict[key] isKindOfClass:NSDictionary.class]) {
            cleansed[key] = [self nullCleanse:dict[key]];
        }
    }
    return cleansed;
}

@end
