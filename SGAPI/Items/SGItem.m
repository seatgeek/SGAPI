//
//  Created by matt on 7/01/13.
//

#import <objc/runtime.h>
#import "SGItem.h"
#import "SGQuery.h"
#import <SGHTTPRequest/NSObject+SGHTTPRequest.h>
#import <MGEvents/NSObject+MGEvents.h>

static NSDateFormatter *_formatterLocal, *_formatterUTC;

@interface SGItem ()
@property (nonatomic, assign) BOOL fetching;
@property (nonatomic, assign) BOOL needsRefresh;
@property (nonatomic, strong) SGHTTPRequest *request;
@end

@implementation SGItem {
    NSDictionary *_dict;
}

// abstract. implemented in subclass
+ (NSDictionary *)resultFields {
    return @{};
}

+ (id)itemForDict:(NSDictionary *)dict {
    SGItem *item = self.new;
    item.dict = dict;
    return item;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    self = [super init];
    self.dict = [[coder decodeObjectForKey:@"dict"] sghttp_nullCleansedWithLoggingURL:nil];
    self.lastFetched = [coder decodeObjectForKey:@"lastFetched"];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.dict forKey:@"dict"];
    [coder encodeObject:self.lastFetched forKey:@"lastFetched"];
}

#pragma mark - Fetching

- (void)fetch {
    if (self.fetching) {
        return;
    }

    if (!self.query || !self.resultItemKey) {
#ifdef DEBUG
        NSAssert(NO, @"Called fetch on an SGitem that doesn't know how to fetch. Don't do that.");
#endif
        return;
    }

    self.fetching = YES;

    SGHTTPRequest *req = [self.query requestWithMethod:SGHTTPRequestMethodGet];
    if (SGQuery.consoleLogging || YES) {
        req.logging = req.logging | (SGHTTPLogRequests | SGHTTPLogErrors);
    }

    __weakSelf me = self;
    req.onSuccess = ^(SGHTTPRequest *_req) {
        NSDictionary *responseDict = [SGJSONSerialization JSONObjectWithData:_req.responseData];
        NSDictionary *itemDict = responseDict[self.resultItemKey];
        if (!itemDict) {
            [me trigger:SGItemFetchFailed];
        }
        me.dict = itemDict;
        me.fetching = NO;
        [me trigger:SGItemFetchSucceeded withContext:me];
    };

    req.onFailure = ^(SGHTTPRequest *_req) {
        me.fetching = NO;
        [me trigger:SGItemFetchFailed withContext:_req.error];
    };

    req.onNetworkReachable = ^{
        [me fetch];
    };

    [req start];
    self.request = req;
    [self trigger:SGItemFetchStarted withContext:self];
}

#pragma mark - Setters

- (void)setDict:(NSDictionary *)dict {
    _dict = dict;

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

    if ([_dict[@"childItems"] isKindOfClass:NSDictionary.class]) {
        self.childItemsDict = _dict[@"childItems"];
    }

    self.needsRefresh = NO;
}

- (void)setChildItemsDict:(NSDictionary *)itemsDict {
    for (NSString *propertyName in itemsDict) {
        id propertyValue = itemsDict[propertyName];
        if ([propertyValue isKindOfClass:NSDictionary.class]) { // an SGItem
            NSDictionary *propertyDict = propertyValue;
            Class itemClass = NSClassFromString(propertyDict[@"class"]);
            [self setValue:[itemClass itemForDict:propertyDict[@"dict"]] forKey:propertyName];

        } else if ([propertyValue isKindOfClass:NSArray.class]) { // an NSArray of SGItems
            NSMutableArray *items = @[].mutableCopy;
            for (NSDictionary *itemDict in propertyValue) {
                Class itemClass = NSClassFromString(itemDict[@"class"]);
                [items addObject:[itemClass itemForDict:itemDict[@"dict"]]];
            }
            [self setValue:items forKey:propertyName];
        }
    }
}

- (void)setNeedsRefresh {
    self.needsRefresh = YES;
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

+ (nullable id)valueFor:(nullable id)value withType:(nonnull Class)requiredType {

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

- (BOOL)fetching {
    return _fetching;
}

- (NSString *)title {
    return nil;
}

- (NSDictionary *)dict {
    if (!self.childItems.count) {
        return _dict;
    }
    NSMutableDictionary *dict = _dict.mutableCopy;
    dict[@"childItems"] = self.childItemsDict;
    return dict;
}

/**
 * can contain SGItem subclasses and NSArrays of SGItem subclasses, keyed by their property name
 * eg @{@"venue":self.venue, @"performers":self.performers}
 */
- (nonnull NSDictionary *)childItems {
    return @{};
}

// returns the contents of childItems in encodeable dict form
- (NSDictionary *)childItemsDict {
    NSDictionary *childItems = self.childItems;
    NSMutableDictionary *childItemsDict = @{}.mutableCopy;
    for (NSString *key in childItems) {
        if ([childItems[key] isKindOfClass:SGItem.class]) {
            SGItem *child = childItems[key];
            childItemsDict[key] = @{@"class":NSStringFromClass(child.class), @"dict":child.dict};
        } else if ([childItems[key] isKindOfClass:NSArray.class]) {
            NSArray *children = childItems[key];
            NSMutableArray *childDicts = @[].mutableCopy;
            for (SGItem *child in children) {
                [childDicts addObject:@{@"class":NSStringFromClass(child.class), @"dict":child.dict}];
            }
            childItemsDict[key] = childDicts;
        }
    }
    return childItemsDict;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ id:%@ title:%@ score:%@>",
                                      NSStringFromClass(self.class), self.ID, self.title,
                                      self.score];
}

@end
