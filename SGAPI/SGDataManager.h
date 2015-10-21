//
//  SGDataManager.h
//  SeatGeek
//
//  Created by David McNerney on 10/5/15.
//  Copyright © 2015 SeatGeek. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SGItemSet;

/**
Abstract base class. SGDataManagers do the following:

- fetch objects from server endpoints
- keep those objects in memory for the use of client code that needs them throughout the app
- possibly save objects and associated resources for offline access
- emit events so that client code can update UI etc
 */
@interface SGDataManager : NSObject

@property (nonnull, nonatomic, strong) SGItemSet *itemSet;

+ (nonnull instancetype)managerForItemSet:(nonnull SGItemSet *)itemSet;

- (nullable NSArray *)resultItems;

#pragma mark - Refreshing data

/**
 * Refetch any data marked as `needsRefresh`. Should keep the old data until
 * a successful server response replaces it.
 */
- (void)refresh;

/**
* Returns YES if the last refresh failed.
*/
- (BOOL)lastRefreshFailed;

#pragma mark - Flagging data as in need of refresh

/**
 * Mark a specific item as `needsRefresh`. Will be refetched on next `refresh` call.
 */
- (void)needToRefreshItemOfKind:(nonnull Class)itemClass withID:(nonnull NSString *)itemID;

@end
