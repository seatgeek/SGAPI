//
//  Created by matt on 27/05/14.
//

#import "SGQuery.h"
#import "NSDate+ISO8601.h"

NSString *_gBaseURL;
BOOL _gConsoleLogging;
NSMutableDictionary *_globalParams;

@interface SGQuery ()
@property (nonatomic, strong) NSString *baseUrl;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSArray *queryItems;
/// parameters that were baked in to the path at creation time
@property (nonatomic, strong) NSMutableDictionary *bakedParameters;
@property (nonatomic, strong) NSMutableDictionary *parameters;
@property (nonatomic, strong) NSMutableDictionary *filters;
@end

@implementation SGQuery

+ (void)initialize {
    self.baseURL = [NSString stringWithFormat:self.baseFormat, self.defaultBaseDomain];
}

+ (NSString *)defaultBaseDomain {
    return SGAPI_BASEDOMAIN;
}

+ (NSString *)baseFormat {
    return SGAPI_BASEFORMAT;
}

+ (SGQuery *)queryWithPath:(NSString *)path {
    return [SGQuery queryWithBaseUrl:nil path:path];
}

+ (SGQuery *)queryWithBaseUrl:(NSString *)baseUrl {
    return [SGQuery queryWithBaseUrl:baseUrl path:nil];
}

+ (SGQuery *)queryWithBaseUrl:(NSString *)baseUrl path:(NSString *)path {
    SGQuery *query = self.new;
    query.baseUrl = baseUrl;
    query.path = path;
    [query rebuildQuery];
    return query;
}

#pragma mark - Events Query Factories

+ (SGQuery *)eventsQuery {
    return [self queryWithPath:@"/events"];
}

+ (SGQuery *)recommendationsQuery {
    return [self queryWithPath:@"/recommendations"];
}

+ (SGQuery *)eventQueryForId:(NSNumber *)eventId {
    id path = [NSString stringWithFormat:@"/events/%@", eventId];
    return [self queryWithPath:path];
}

#pragma mark - Performers Query Factories

+ (SGQuery *)performersQuery {
    return [self queryWithPath:@"/performers"];
}

+ (SGQuery *)performerQueryForId:(NSNumber *)performerId {
    id path = [NSString stringWithFormat:@"/performers/%@", performerId];
    return [self queryWithPath:path];
}

+ (SGQuery *)performerQueryForSlug:(NSString *)slug {
    SGQuery *query = self.performersQuery;
    [query setParameter:@"slug" value:slug];
    return query;
}

#pragma mark - Venues Query Factories

+ (SGQuery *)venuesQuery {
    return [self queryWithPath:@"/venues"];
}

+ (SGQuery *)venueQueryForId:(NSNumber *)venueId {
    id path = [NSString stringWithFormat:@"/venues/%@", venueId];
    return [self queryWithPath:path];
}

#pragma mark - Query Rebuilding

- (void)setParameter:(NSString *)param value:(id)value {
    if (value) {
        self.parameters[param] = value;
        if (self.bakedParameters[param]) {
            [self.bakedParameters removeObjectForKey:param];
        }
    } else {
        [self.parameters removeObjectForKey:param];
        [self.bakedParameters removeObjectForKey:param];
    }
    [self rebuildQuery];
}

- (void)addFilter:(NSString *)filter value:(id)value {
    if (value) {
        self.filters[filter] = value;
        if (self.bakedParameters[filter]) {
            [self.bakedParameters removeObjectForKey:filter];
        }
    } else {
        [self.filters removeObjectForKey:filter];
        [self.bakedParameters removeObjectForKey:filter];
    }
    [self rebuildQuery];
}

- (NSArray *)queryItemsForParameters:(NSDictionary *)parameters {
    NSMutableArray *queryItems = NSMutableArray.new;
    for (NSString *key in parameters) {
        id value = parameters[key];
        if ([value isKindOfClass:NSArray.class]) {
            for (id arrayValue in value) {
                NSString *arrayValueString = [self queryItemValueAsString:arrayValue];
                [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:arrayValueString]];
            }
        } else {
            value = [self queryItemValueAsString:value];
            [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
        }
    }
    return queryItems;
}

- (NSString *)queryItemValueAsString:(id)value {
    return [value isKindOfClass:NSString.class] ? value : [NSString stringWithFormat:@"%@", value];
}

- (void)rebuildQuery {
    self.queryItems = @[];
    if (!self.URL) {
        return;
    }

    NSMutableArray *queryItems = NSMutableArray.array;
    [queryItems addObjectsFromArray:[self queryItemsForParameters:self.bakedParameters]];
    [queryItems addObjectsFromArray:[self queryItemsForParameters:self.class.globalParameters]];
    [queryItems addObjectsFromArray:[self queryItemsForParameters:self.parameters]];
    [queryItems addObjectsFromArray:[self queryItemsForParameters:self.filters]];
    self.queryItems = queryItems.copy;
}

#pragma mark - Parameter Setters

- (void)setPath:(NSString *)path {
    _path = path;

    [self.bakedParameters removeAllObjects];
    if ([path rangeOfString:@"?"].location == NSNotFound) {
        return;
    }
    NSString *query = [path componentsSeparatedByString:@"?"].lastObject;
    NSArray *queryComponents = [query componentsSeparatedByString:@"&"];
    for (NSString *component in queryComponents) {
        NSArray *paramValuePair = [component componentsSeparatedByString:@"="];
        if (paramValuePair.count != 2) {
            continue;
        }
        self.bakedParameters[paramValuePair.firstObject] = paramValuePair.lastObject;
    }
}

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

- (void)clearLocation {
    _location = (CLLocationCoordinate2D){.latitude = 0, .longitude = 0};
    [self setParameter:@"lat" value:nil];
    [self setParameter:@"lon" value:nil];
}

- (void)setRange:(NSString *)range {
    // todo: validate
    _range = range.copy;
    [self setParameter:@"range" value:range];
}

- (void)setFromDate:(NSDate *)fromDate {
    _fromDate = fromDate.copy;
    [self setParameter:@"datetime_local.gte" value:fromDate.ISO8601];
}

- (void)setToDate:(NSDate *)toDate {
    _toDate = toDate.copy;
    [self setParameter:@"datetime_local.lte" value:toDate.ISO8601];
}

- (void)setSearch:(NSString *)search {
    _search = search;
    [self setParameter:@"q" value:search];
}

+ (void)setClientId:(NSString *)clientId {
    self.globalParameters[@"client_id"] = clientId;
}

+ (void)setClientSecret:(NSString *)clientSecret {
    self.globalParameters[@"client_secret"] = clientSecret;
}

+ (void)setAid:(NSString *)aid {
    self.globalParameters[@"aid"] = aid;
}

+ (void)setPid:(NSString *)pid {
    self.globalParameters[@"pid"] = pid;
}

+ (void)setRid:(NSString *)rid {
    self.globalParameters[@"rid"] = rid;
}

+ (NSString *)baseURL {
    return _gBaseURL;
}

+ (void)setBaseURL:(NSString *)url {
    _gBaseURL = url;
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
    NSString *baseUrl = self.baseUrl ?: _gBaseURL;
    NSString *path = self.path ?: @"";
    NSString *url = [baseUrl stringByAppendingString:path];
    NSURLComponents *bits = [NSURLComponents componentsWithString:url];
    bits.queryItems = self.queryItems;
    return bits.URL;
}

- (SGHTTPRequest *)requestWithMethod:(SGHTTPRequestMethod)method {
    SGHTTPRequest *request;
    switch (method) {
        case SGHTTPRequestMethodGet:
            request = [SGHTTPRequest requestWithURL:self.URL];
            break;
        case SGHTTPRequestMethodPost:
            request = [SGHTTPRequest postRequestWithURL:self.URL];
            break;
        case SGHTTPRequestMethodDelete:
            request = [SGHTTPRequest deleteRequestWithURL:self.URL];
            break;
        case SGHTTPRequestMethodPut:
            request = [SGHTTPRequest putRequestWithURL:self.URL];
            break;
        case SGHTTPRequestMethodPatch:
            request = [SGHTTPRequest patchRequestWithURL:self.URL];
            break;
        case SGHTTPRequestMethodMultipartPost:
            NSAssert(NO, @"SGQuery does not support multi-part post requests directly.");
            request = [SGHTTPRequest postRequestWithURL:self.URL];
            break;
    }
    request.requestHeaders = self.requestHeaders.copy;
    return request;
}

- (NSMutableDictionary *)parameters {
    if (!_parameters) {
        _parameters = @{}.mutableCopy;
    }
    return _parameters;
}

- (NSMutableDictionary *)bakedParameters {
    if (!_bakedParameters) {
        _bakedParameters = @{}.mutableCopy;
    }
    return _bakedParameters;
}

- (NSMutableDictionary *)filters {
    if (!_filters) {
        _filters = @{}.mutableCopy;
    }
    return _filters;
}

+ (NSMutableDictionary *)globalParameters {
    if (!_globalParams) {
        _globalParams = @{}.mutableCopy;
    }
    return _globalParams;
}

@end
