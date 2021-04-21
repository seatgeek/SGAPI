//
//  SGKEventSetTests.m
//  SGPlatformTests
//
//  Created by Matt Greenfield on 27/06/14.
//  Copyright (c) 2014 SeatGeek. All rights reserved.
//

#define EXP_SHORTHAND YES

@import SGAPI;

#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>


@interface SGKEventSetTests : XCTestCase

@end

@implementation SGKEventSetTests

+ (void)setUp {
    [super setUp];
    Expecta.asynchronousTestTimeout = 10;
}

+ (void)tearDown {
    [super tearDown];
}

- (void)testMetsEvents {
    SGKEventSet *events = SGKEventSet.eventsSet;
    events.query.search = @"new york mets";

    __weak SGKEventSet *wEvents = events;
    events.onPageLoaded = ^(NSOrderedSet *results) {
        expect(wEvents.fetching).to.beFalsy();
        expect(wEvents.count).will.beGreaterThan(0);
    };

    [events fetchNextPage];

    expect(events.fetching).to.beTruthy();
}

@end
