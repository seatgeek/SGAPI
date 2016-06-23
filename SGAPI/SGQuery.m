//
//  Created by matt on 27/05/14.
//

#import "SGQuery.h"
#import "NSString+URLEncode.h"
#import "NSDate+ISO8601.h"

NSString *_gBaseURL;
BOOL _gConsoleLogging;
NSMutableDictionary *_globalParams;

@interface SGQuery ()
@property (nonatomic, strong) NSString *baseUrl;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *query;
@property (nonatomic, strong) NSMutableDictionary *parameters;
@property (nonatomic, strong) NSMutableDictionary *filters;
@end

@implementation SGQuery

+ (void)initialize {
    self.baseURL = SGAPI_BASEURL;
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
    } else {
        [self.parameters removeObjectForKey:param];
    }
    [self rebuildQuery];
}

- (void)addFilter:(NSString *)filter value:(id)value {
    if (value) {
        self.filters[filter] = value;
    } else {
        [self.filters removeObjectForKey:filter];
    }
    [self rebuildQuery];
}

- (NSArray *)queryItemsForParameters:(NSDictionary *)parameters {
    NSMutableArray *queryItems = NSMutableArray.new;
    for (NSString *key in parameters) {
        id value = parameters[key];
        if ([value isKindOfClass:NSString.class]) {
            [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
        } else if ([value isKindOfClass:NSArray.class]) {
            for (id arrayValue in value) {
                NSString *arrayValueString = [NSString stringWithFormat:@"%@", arrayValue];
                [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:arrayValueString]];
            }
        } else {
            value = [NSString stringWithFormat:@"%@", value];
            [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
        }
    }
    return queryItems;
}

- (void)rebuildQuery {
    self.query = nil;

    NSURLComponents *components = [NSURLComponents componentsWithURL:self.URL resolvingAgainstBaseURL:NO];
    NSMutableArray *queryItems = NSMutableArray.array;
    [queryItems addObjectsFromArray:[self queryItemsForParameters:self.class.globalParameters]];
    [queryItems addObjectsFromArray:[self queryItemsForParameters:self.parameters]];
    [queryItems addObjectsFromArray:[self queryItemsForParameters:self.filters]];
    components.queryItems = queryItems;    
    self.query = components.query;
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

+ (void)setAid:(NSString *)aid {
    self.globalParameters[@"aid"] = aid;
}

+ (void)setRid:(NSString *)rid {
    self.globalParameters[@"rid"] = rid;
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
    bits.query = self.query;
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
