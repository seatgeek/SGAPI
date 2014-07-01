//
//  SGEventSetTests.m
//  SGPlatformTests
//
//  Created by Matt Greenfield on 27/06/14.
//  Copyright (c) 2014 SeatGeek. All rights reserved.
//

#define EXP_SHORTHAND YES

#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>
#import <SGAPI/SGAPI.h>

@interface SGEventSetTests : XCTestCase

@end

@implementation SGEventSetTests

+ (void)setUp {
    [super setUp];
    Expecta.asynchronousTestTimeout = 10;
}

+ (void)tearDown {
    [super tearDown];
}

- (void)testMetsEvents {
    SGEventSet *events = SGEventSet.eventsSet;
    events.query.search = @"new york mets";

    __weak SGEventSet *wEvents = events;
    events.onPageLoaded = ^(NSOrderedSet *results) {
        expect(wEvents.fetching).to.beFalsy();
        expect(wEvents.count).will.beGreaterThan(0);
    };

    [events fetchNextPage];

    expect(events.fetching).to.beTruthy();
}

@end
