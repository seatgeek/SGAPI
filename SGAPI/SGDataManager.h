//
//  SGDataManager.h
//  SeatGeek
//
//  Created by David McNerney on 10/5/15.
//  Copyright © 2015 SeatGeek. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SGItemSet, SGItem;

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

#pragma mark - Used by subclasses

/**
 * Code that has caused the server to create an object, and received it back in
 * the response to its POST, can add the new object to the manager with this method, so
 * it's included before the next item set fetch completes.
 */
- (void)addResultItem:(nonnull SGItem *)item;

/**
 * Similar to above, for when you've received an updated version of one of our result items.
 */
- (void)replaceResultItem:(nonnull SGItem *)updatedItem;

/**
 * Code that has caused or noted a change that would remove an item from the result set
 * can use this method to remove it immediately, rather than waiting for a refetch
 * of the item set to complete.
 */
- (void)removeResultItem:(nonnull SGItem *)item;

@end
