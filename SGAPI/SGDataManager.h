//
//  SGDataManager.h
//  SeatGeek
//
//  Created by David McNerney on 10/5/15.
//  Copyright © 2015 SeatGeek. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SGDataManagerRefreshStarted @"SGDataManagerRefreshStarted"
#define SGDataManagerRefreshSucceeded @"SGDataManagerRefreshSucceeded"
#define SGDataManagerRefreshFailed @"SGDataManagerRefreshFailed"

@class SGItemSet;

/**
Abstract base class. SGDataManagers do the following:

- fetch objects from server endpoints
- keep those objects in memory for the use of client code that needs them throughout the app
- possibly save objects and associated resources for offline access
- emit events so that client code can update UI etc
 */
@interface SGDataManager : NSObject

@property (nonatomic, strong) SGItemSet *itemSet;

+ (instancetype)managerForItemSet:(SGItemSet *)itemSet;

#pragma mark - Refreshing data

/**
 * Refetch any data marked as `needsRefresh`. Should keep the old data until
 * a successful server response replaces it.
 */
- (void)refresh;

/**
* Returns YES if a refresh is in progress.
*/
- (BOOL)refreshing;

/**
* Returns YES if the last refresh failed.
*/
- (BOOL)lastRefreshFailed;

#pragma mark - Flagging data as in need of refresh

/**
 * Mark a specific item as `needsRefresh`. Will be refetched on next `refresh` call.
 */
- (void)needToRefreshItemOfKind:(Class)itemClass withID:(NSString *)itemID;

#pragma mark - Fetching more paginated data

/**
 * Calls `fetchNextPage` on the `itemSet`.
 */
- (void)fetchMoreIfAvailable;

/**
 * Returns `itemSet.perPage`.
 */
- (NSUInteger)pageSize;

- (SGItemSet *)itemSet;

@end
