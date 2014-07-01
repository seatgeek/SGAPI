//
//  SGQueryTests.m
//  TestsApp
//
//  Created by Matt Greenfield on 27/06/14.
//  Copyright (c) 2014 SeatGeek. All rights reserved.
//

#define EXP_SHORTHAND YES

#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>
#import <SGAPI/SGAPI.h>

@interface SGQueryTests : XCTestCase

@end

@implementation SGQueryTests

- (void)setUp {
    [super setUp];
    Expecta.asynchronousTestTimeout = 10;
}

- (void)testEventsQuery {
    SGQuery *query = SGQuery.eventsQuery;
    expect(query.URL.absoluteString).to.equal(@"http://api.seatgeek.com/2/events");
}

@end
