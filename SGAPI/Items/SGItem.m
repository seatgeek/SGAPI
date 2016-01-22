//
//  Created by matt on 7/01/13.
//

#import <objc/runtime.h>
#import "SGItem.h"
#import "SGQuery.h"
#import <SGHTTPRequest/NSObject+SGHTTPRequest.h>
#import <MGEvents/NSObject+MGEvents.h>
#import <SGImageCache/SGCache.h>

static NSDateFormatter *_formatterLocal, *_formatterUTC;

@interface SGItem ()
@property (nonatomic, assign) BOOL fetching;
@property (nonatomic, assign) BOOL needsRefresh;
@property (nonatomic, assign) BOOL hasPartialContents;
@property (nonatomic, strong) SGHTTPRequest *request;
@property (nonatomic, strong) NSError *lastFetchError;
@end

@implementation SGItem

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

#pragma mark - Fetching and caching

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
    if (SGQuery.consoleLogging) {
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
        me.lastFetchError = nil;
        me.fetching = NO;
        me.hasPartialContents = NO;
        me.lastFetched = NSDate.date;
        if ([self shouldCacheOnFetch]) {
            [me cacheContents];
        }
        [me trigger:SGItemFetchSucceeded withContext:me];
    };

    req.onFailure = ^(SGHTTPRequest *_req) {
        me.fetching = NO;
        me.lastFetchError = _req.error;
        [me trigger:SGItemFetchFailed withContext:_req.error];
    };

    req.onNetworkReachable = ^{
        [me fetch];
    };

    [req start];
    self.request = req;
    [self trigger:SGItemFetchStarted withContext:self];
}

- (NSString *)internalCacheKey {
    return self.cacheKey.length ? [NSString stringWithFormat:@"%@:%@", self.class, self.cacheKey] : nil;
}

- (void)cacheContents {
    if (!self.internalCacheKey.length || self.hasPartialContents || !self.lastFetched) {
        return;
    }
    NSDictionary *cacheDict = @{@"dict":self.dict, @"lastFetched":self.lastFetched};
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cacheDict];
    [SGCache addData:data forCacheKey:self.internalCacheKey];
}

- (BOOL)haveCachedContents {
    return [SGCache haveFileForCacheKey:self.internalCacheKey];
}

- (BOOL)loadCachedContents {
    if (!self.haveCachedContents) {
        return NO;
    }
    NSData *data = [SGCache fileForCacheKey:self.internalCacheKey];
    NSDictionary *cachedContents = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (![cachedContents isKindOfClass:NSDictionary.class]) {
        return NO;
    }
    self.dict = cachedContents[@"dict"];
    self.lastFetched = cachedContents[@"lastFetched"];
    self.hasPartialContents = NO;
    return YES;
}

- (BOOL)shouldCacheOnFetch {
    return YES;
}

#pragma mark - Setters

- (void)setDict:(NSDictionary *)dict {
    _dict = dict;

    NSDictionary *keys = self.class.resultFields;

    for (NSString *key in self.class.resultFields.allKeys) {
        if (_dict[keys[key]]) {

            const char * type = property_getAttributes(class_getProperty(self.class, key.UTF8String));
            NSString * typeString = [NSString stringWithUTF8String:type];
            NSArray * attributes = [typeString componentsSeparatedByString:@","];
            NSString * typeAttribute = [attributes objectAtIndex:0];

            if ([typeAttribute hasPrefix:@"T@"] && [typeAttribute length] > 1) {
                NSString * typeClassName = [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length]-4)];  //turns @"NSDate" into NSDate
                Class typeClass = NSClassFromString(typeClassName);
                if (typeClass != nil) {
                    [self setValue:[self.class valueFor:_dict[keys[key]] withType:typeClass]
                            forKey:key];
                }
#ifdef DEBUG
                NSAssert(typeClass != nil, @"%@ could not find class with name %@ for property", NSStringFromClass(self.class), typeClassName);
#endif
            } else {
                // the property is a primitive.  Let cocoa handle it for us:
                /***
                 Similarly, setValue:forKey: determines the data type required by the appropriate accessor 
                 or instance variable for the specified key. If the data type is not an object, then the 
                 value is extracted from the passed object using the appropriate -<type>Value method.
                 **/
                [self setValue:_dict[keys[key]] forKey:key];
            }
        }
    }

    self.needsRefresh = NO;
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

- (NSTimeInterval)fetchAge {
    if (!self.lastFetched) {
        return -NSDate.distantPast.timeIntervalSinceNow;
    } else {
        return -self.lastFetched.timeIntervalSinceNow;
    }
}

- (NSString *)title {
    return nil;
}

- (NSArray *)childItems {
    return nil;
}

- (NSString *)cacheKey {
    return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ id:%@ title:%@ score:%@>",
                                      NSStringFromClass(self.class), self.ID, self.title,
                                      self.score];
}

@end
