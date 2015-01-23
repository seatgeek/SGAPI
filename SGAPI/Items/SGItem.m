//
//  Created by matt on 7/01/13.
//

#import <objc/runtime.h>
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

    NSDictionary *keys = self.class.resultFields;

    for (NSString *key in self.class.resultFields.allKeys) {
        if (_dict[keys[key]]) {

            // get the property's class, for type enforcement
            objc_property_t prop = class_getProperty(self.class, key.UTF8String);
            NSString *attribs = [NSString stringWithUTF8String:property_getAttributes(prop)];
            NSArray *bits = [attribs componentsSeparatedByString:@"\""];
            Class requiredType = NSClassFromString(bits[1]);

            [self setValue:[self.class valueFor:_dict[keys[key]] withType:requiredType]
                  forKey:key];
        }
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

#pragma mark - Type Conversion

+ (id)valueFor:(id)value withType:(Class)requiredType {

    // nil or correct type, so send it back
    if (!value || [value isKindOfClass:requiredType]) {
        return value;
    }

    // NSNull? who ever thought that was a good idea? kill it with fire
    if ([value isKindOfClass:NSNull.class]) {
        return nil;
    }

    if (requiredType == NSString.class) { // wanted a string
        if ([value isKindOfClass:NSNumber.class]) { // got a number
            return [value stringValue];
        }
    } else if (requiredType == NSNumber.class) { // wanted a number
        if ([value isKindOfClass:NSString.class]) { // got a string
            return @([value floatValue]);
        }
    }

    return nil; // can't help you. nil's all you're gonna get
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
