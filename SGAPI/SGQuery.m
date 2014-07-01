//
//  Created by matt on 27/05/14.
//

#import "SGQuery.h"
#import "NSString+URLEncode.h"

BOOL _gConsoleLogging;
NSMutableDictionary *_globalParams;

@interface SGQuery ()
@property (nonatomic, strong) NSURLComponents *bits;
@property (nonatomic, strong) NSMutableDictionary *parameters;
@property (nonatomic, copy) NSString *filters;
@end

@implementation SGQuery

+ (SGQuery *)queryWithString:(NSString *)string {
    SGQuery *query = self.new;
    query.bits = [NSURLComponents componentsWithString:string];
    [query rebuildQuery];
    return query;
}

#pragma mark - Events Query Factories

+ (SGQuery *)eventsQuery {
    return [self queryWithString:[NSString stringWithFormat:@"%@/events", SGAPI_ENDPOINT]];
}

+ (SGQuery *)recommendationsQuery {
    return [self queryWithString:[NSString stringWithFormat:@"%@/recommendations",
                                                            SGAPI_ENDPOINT]];
}

+ (SGQuery *)eventQueryForId:(NSNumber *)eventId {
    id url = [NSString stringWithFormat:@"%@/events/%@", SGAPI_ENDPOINT, eventId];
    return [self queryWithString:url];
}

#pragma mark - Performers Query Factories

+ (SGQuery *)performersQuery {
    return [self queryWithString:[NSString stringWithFormat:@"%@/performers", SGAPI_ENDPOINT]];
}

+ (SGQuery *)performerQueryForId:(NSNumber *)performerId {
    id url = [NSString stringWithFormat:@"%@/performers/%@", SGAPI_ENDPOINT, performerId];
    return [self queryWithString:url];
}

+ (SGQuery *)performerQueryForSlug:(NSString *)slug {
    SGQuery *query = self.performersQuery;
    [query setParameter:@"slug" value:slug];
    return query;
}

#pragma mark - Venues Query Factories

+ (SGQuery *)venuesQuery {
    return [self queryWithString:[NSString stringWithFormat:@"%@/venues", SGAPI_ENDPOINT]];
}

+ (SGQuery *)venueQueryForId:(NSNumber *)venueId {
    id url = [NSString stringWithFormat:@"%@/venues/%@", SGAPI_ENDPOINT, venueId];
    return [self queryWithString:url];
}

#pragma mark - Query Rebuilding

- (void)setParameter:(NSString *)param value:(id)value {
    // todo: parse the value into a suitable string

    self.parameters[param] = value;
    [self rebuildQuery];
}

- (void)addFilter:(NSString *)filter value:(id)value {
    // todo: parse the value into a suitable string

    if (self.filters.length) {
        NSString *appendage = [NSString stringWithFormat:@"&%@=%@", filter, value];
        self.filters = [self.filters stringByAppendingString:appendage];
    } else {
        self.filters = [NSString stringWithFormat:@"%@=%@", filter, value];
    }
    [self rebuildQuery];
}

- (void)rebuildQuery {
    self.bits.query = nil;
    for (id param in self.class.globalParameters) {
        [self addParameterToQuery:param value:self.class.globalParameters[param]];
    }
    for (id param in self.parameters) {
        [self addParameterToQuery:param value:self.parameters[param]];
    }
    if (self.filters.length) {
        if (self.bits.query.length) {
            NSString *appendage = [NSString stringWithFormat:@"&%@", self.filters];
            self.bits.query = [self.bits.query stringByAppendingString:appendage];
        } else {
            self.bits.query = [self.bits.query stringByAppendingString:self.filters];
        }
    }
}

- (void)addParameterToQuery:(NSString *)param value:(id)value {
    if (self.bits.query.length) {
        NSString *appendage = [NSString stringWithFormat:@"&%@=%@", param, value];
        self.bits.query = [self.bits.query stringByAppendingString:appendage];
    } else {
        self.bits.query = [NSString stringWithFormat:@"%@=%@", param, value];
    }
}

#pragma mark - Parameter Setters

- (void)setPerPage:(NSUInteger)perPage {
    _perPage = perPage;
    [self setParameter:@"per_page" value:@(perPage)];
}

- (void)setPage:(NSUInteger)page {
    _page = page;
    [self setParameter:@"page" value:@(page)];
}

- (void)setLocation:(CLLocationCoordinate2D)location {
    _location = location;
    [self setParameter:@"lat" value:@(location.latitude)];
    [self setParameter:@"lon" value:@(location.longitude)];
}

- (void)setRange:(NSString *)range {
    // todo: validate
    _range = range;
    [self setParameter:@"range" value:range];
}

- (void)setSearch:(NSString *)search {
    _search = search;
    search = [[search componentsSeparatedByCharactersInSet:NSCharacterSet.symbolCharacterSet]
          componentsJoinedByString:@" "];
    search = [[search componentsSeparatedByCharactersInSet:NSCharacterSet
          .punctuationCharacterSet] componentsJoinedByString:@" "];
    search = [search stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    [self setParameter:@"q" value:search.URLEncodedString];
}

+ (void)setClientId:(NSString *)clientId {
    self.globalParameters[@"client_id"] = clientId;
}

#pragma mark - Console Logging

+ (void)setConsoleLogging:(BOOL)logging {
    _gConsoleLogging = logging;
}

+ (BOOL)consoleLogging {
    return _gConsoleLogging;
}

#pragma mark - Getters

- (NSURL *)URL {
    SGPlatformLog(@"%@", self.bits.URL);
    return self.bits.URL;
}

- (NSMutableDictionary *)parameters {
    if (!_parameters) {
        _parameters = @{}.mutableCopy;
    }
    return _parameters;
}

+ (NSMutableDictionary *)globalParameters {
    if (!_globalParams) {
        _globalParams = @{}.mutableCopy;
    }
    return _globalParams;
}

@end
