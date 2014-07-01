## SGAPI

SGAPI is an iOS SDK for querying the [SeatGeek Platform API](http://platform.seatgeek.com),
a comprehensive directory of live events in the United States and Canada.

### CocoaPods Setup

```
pod 'SGAPI'
```

### Example Usage

`SGAPI` provides model classes `SGEvent`, `SGPerformer`, `SGVenue`, and item set 
classes `SGEventSet`, `SGPerformerSet`, `SGVenueSet` for paginated fetching.

```objc
#import <SGAPI/SGAPI>
```

### Fetching Events 

Create `SGEventSet` instances to fetch paginated `SGEvent` results. See the 
[SeatGeek Platform docs](http://platform.seatgeek.com/#events) for available query parameters.

```objc
// find all 'new york mets' events
SGEventSet *events = SGEventSet.eventsSet;
events.query.search = @"new york mets";
events.query.perPage = 30;
```

The `onPageLoaded` block property is called on successful page load. The `onPageLoadFailed`
block property is called when a request fails. 
   
```objc
events.onPageLoaded = ^(NSOrderedSet *results) {
    for (SGEvent *event in results) {
        NSLog(@"event: %@", event.title);
    }
};

events.onPageLoadFailed = ^(NSError *error) {
    NSLog(@"error: %@", error);
};
```

```
[events fetchNextPage];
```

### Fetching Performers

Create `SGPerformerSet` instances to fetch paginated `SGPerformer` results. See the 
[SeatGeek Platform docs](http://platform.seatgeek.com/#performers) for available query 
parameters.

```objc
// find all performers matching 'imagine dragons'
SGPerformerSet *performers = SGPerformerSet.performersSet;
performers.query.search = @"imagine dragons";
```

```objc
performers.onPageLoaded = ^(NSOrderedSet *results) {
    if (results.count) {
        SGPerformer *performer = results[0];
        NSLog(@"performer: %@", performer.name);
    }
};
```

```
[performers fetchNextPage];
```

### Fetching Venues

Create `SGVenueSet` instances to fetch paginated `SGVenue` objects. See the 
[SeatGeek Platform docs](http://platform.seatgeek.com/#venues) for available query parameters.

```objc
// find all venues matching 'new york' 
SGVenueSet *venues = SGVenueSet.venuesSet;
venues.query.search = @"new york";
```

```objc
venues.onPageLoaded = ^(NSOrderedSet *results) {
    for (SGVenue *venue in results) {
        NSLog(@"venue: %@", venue.name);
    }
};
```

```
[performers fetchNextPage];
```

### Familiar Item Set Properties

Item sets (`SGEventSet`, `SGPerformerSet`, `SGVenueSet`) support subscripting and common set
properties.

```objc
// count, firstObject, and lastObject
if (events.count) {
    NSLog(@"first event: %@", [events.firstObject title]);
    NSLog(@"last event: %@", [events.lastObject title]);
}

// subscripting
if (events.count >= 3) {
    NSLog(@"third event: %@", [events[2] title]);
}

// iterate over an NSArray of SGEvents in the set
for (SGEvent *event in events.array) {
    NSLog(@"event: %@", event.title);
}

// iterate over an NSOrderedSet of SGEvents in the set
for (SGEvent *event in events.orderedSet) {
    NSLog(@"event: %@", event.title);
}
```

### SGQuery

You can modify the `query` of each set to change default values and filters.

```objc
events.query.perPage = 100;
events.query.location = CLLocationCoordinate2DMake(40.752, -73.972) // New York City 
events.query.range = @"200mi" // 200 mile search range
```

If you would rather use your own network fetching code, you can construct standalone `SGQuery`
instances for URL construction.

```objc
SGQuery *query = SGQuery.eventsQuery;
[query addFilter:@"taxonomies.name" value:@"sports"];
query.search = @"new york";

NSLog(@"%@", query.URL);
// http://api.seatgeek.com/2/events?q=new+york&taxonomies.name=sports
```
