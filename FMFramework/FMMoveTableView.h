//
//  FMMoveTableView.h
//  FMFramework
//
//  Created by Florian Mielke.
//  Copyright 2012 Florian Mielke. All rights reserved.
//  


#import <QuartzCore/QuartzCore.h>


@class FMMoveTableView;


@protocol FMMoveTableViewDelegate <NSObject, UITableViewDelegate>

@optional

// Allows customization of the target row for a particular row as it is being moved
- (NSIndexPath *)moveTableView:(FMMoveTableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;

// Called before the particular row is about to change to a moving state
- (void)moveTableView:(FMMoveTableView *)tableView willMoveRowAtIndexPath:(NSIndexPath *)indexPath;

@end



@protocol FMMoveTableViewDataSource <NSObject, UITableViewDataSource>

// Called after the particular row is being dropped to it's new index path
- (void)moveTableView:(FMMoveTableView *)tableView moveRowFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

@optional

// Allows to reorder a particular row
- (BOOL)moveTableView:(FMMoveTableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath;

@end



@interface FMMoveTableView : UITableView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <FMMoveTableViewDataSource> dataSource;
@property (nonatomic, weak) id <FMMoveTableViewDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *movingIndexPath;
@property (nonatomic, strong) NSIndexPath *initialIndexPathForMovingRow;

- (BOOL)indexPathIsMovingIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)adaptedIndexPathForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
