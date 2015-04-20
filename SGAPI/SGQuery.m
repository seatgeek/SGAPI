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
@property (nonatomic, strong) NSURLComponents *bits;
@property (nonatomic, strong) NSMutableDictionary *parameters;
@property (nonatomic, copy) NSString *filters;
@end

@implementation SGQuery

+ (void)initialize {
    self.baseURL = SGAPI_BASEURL;
}

+ (SGQuery *)queryWithString:(NSString *)string {
    SGQuery *query = self.new;
    query.bits = [NSURLComponents componentsWithString:string];
    [query rebuildQuery];
    return query;
}

#pragma mark - Events Query Factories

+ (SGQuery *)eventsQuery {
    return [self queryWithString:[NSString stringWithFormat:@"%@/events", _gBaseURL]];
}

+ (SGQuery *)recommendationsQuery {
    return [self queryWithString:[NSString stringWithFormat:@"%@/recommendations", _gBaseURL]];
}

+ (SGQuery *)eventQueryForId:(NSNumber *)eventId {
    id url = [NSString stringWithFormat:@"%@/events/%@", _gBaseURL, eventId];
    return [self queryWithString:url];
}

#pragma mark - Performers Query Factories

+ (SGQuery *)performersQuery {
    return [self queryWithString:[NSString stringWithFormat:@"%@/performers", _gBaseURL]];
}

+ (SGQuery *)performerQueryForId:(NSNumber *)performerId {
    id url = [NSString stringWithFormat:@"%@/performers/%@", _gBaseURL, performerId];
    return [self queryWithString:url];
}

+ (SGQuery *)performerQueryForSlug:(NSString *)slug {
    SGQuery *query = self.performersQuery;
    [query setParameter:@"slug" value:slug];
    return query;
}

#pragma mark - Venues Query Factories

+ (SGQuery *)venuesQuery {
    return [self queryWithString:[NSString stringWithFormat:@"%@/venues", _gBaseURL]];
}

+ (SGQuery *)venueQueryForId:(NSNumber *)venueId {
    id url = [NSString stringWithFormat:@"%@/venues/%@", _gBaseURL, venueId];
    return [self queryWithString:url];
}

#pragma mark - Query Rebuilding

- (void)setParameter:(NSString *)param value:(id)value {
    // todo: parse the value into a suitable string
    if (value) {
        self.parameters[param] = value;
    } else {
        [self.parameters removeObjectForKey:param];
    }
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
    return self.bits.URL;
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

+ (NSMutableDictionary *)globalParameters {
    if (!_globalParams) {
        _globalParams = @{}.mutableCopy;
    }
    return _globalParams;
}

@end
