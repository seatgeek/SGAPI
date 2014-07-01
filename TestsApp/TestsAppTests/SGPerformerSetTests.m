//
//  SGPerformerSetTests.m
//  TestsApp
//
//  Created by Matt Greenfield on 27/06/14.
//  Copyright (c) 2014 SeatGeek. All rights reserved.
//

#define EXP_SHORTHAND YES

#import <XCTest/XCTest.h>
#import <Expecta/Expecta.h>
#import <SGAPI/SGAPI.h>

@interface SGPerformerSetTests : XCTestCase

@end

@implementation SGPerformerSetTests

+ (void)setUp {
    [super setUp];
    Expecta.asynchronousTestTimeout = 10;
}

- (void)testYankees {
    __block NSOrderedSet *results = nil;
    
    SGPerformerSet *performers = SGPerformerSet.performersSet;
    performers.query.search = @"yankees";
    
    performers.onPageLoaded = ^(NSOrderedSet *_results) {
        NSLog(@"results:%@", _results);
        results = _results;
    };
    
    [performers fetchNextPage];
    expect(performers.fetching).to.beTruthy();
    
    // async tests
    expect(results.count).will.beGreaterThan(0);
    expect([results.firstObject name]).will.equal(@"New York Yankees");
}

@end
