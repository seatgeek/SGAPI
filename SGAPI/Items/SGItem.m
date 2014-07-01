//
//  Created by matt on 7/01/13.
//

#import "SGItem.h"
#import "NSDictionary+NullCleanse.h"

static NSDateFormatter *_formatterLocal, *_formatterUTC;

@implementation SGItem

// abstract. implemented in subclass
+ (NSDictionary *)resultFields {
    return nil;
}

+ (id)itemForDict:(NSDictionary *)dict {
    SGItem *item = self.new;
    item.dict = dict;
    return item;
}

#pragma mark - Setters

- (void)setDict:(NSDictionary *)dict {
    _dict = dict.nullCleansed;

    NSDictionary *dataKeys = self.class.resultFields;

    for (NSString *key in self.class.resultFields.allKeys) {
        [self setValue:dict[dataKeys[key]] forKey:key];
    }

    // ID should be a string but sometimes it comes back from the JSON parser as a number
    if (![self.ID isKindOfClass:NSString.class]) {
        _ID = [(id)self.ID stringValue];
    }
}

#pragma mark - Shared Date Parsers

+ (NSDateFormatter *)localDateParser {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _formatterLocal = [[NSDateFormatter alloc] init];
        _formatterLocal.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
        _formatterLocal.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    });
    return _formatterLocal;
}

+ (NSDateFormatter *)utcDateParser {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _formatterUTC = [[NSDateFormatter alloc] init];
        _formatterUTC.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
        _formatterUTC.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        _formatterUTC.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    });
    return _formatterUTC;
}

#pragma mark - Comparisons

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    if ([other class] == self.class && [[other ID] isEqualToString:self.ID]) {
        return YES;
    }
    return NO;
}

- (NSUInteger)hash {
    return self.ID.hash;
}

#pragma mark - Getters

- (NSString *)title {
    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ id:%@ title:%@ score:%@>",
                                      NSStringFromClass(self.class), self.ID, self.title,
                                      self.score];
}

@end
