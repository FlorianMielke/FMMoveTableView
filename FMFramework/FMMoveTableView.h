//
//  FMMoveTableView.h
//  FMFramework
//
//  Created by Florian Mielke.
//  Copyright 2012 Florian Mielke. All rights reserved.
//  


@class FMMoveTableView;


@protocol FMMoveTableViewDelegate <NSObject, UITableViewDelegate>

- (NSIndexPath *)moveTableView:(FMMoveTableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;
@optional
- (void)moveTableView:(FMMoveTableView *)tableView willMoveRowAtIndexPath:(NSIndexPath *)indexPath;

@end



@protocol FMMoveTableViewDataSource <NSObject, UITableViewDataSource>

- (void)moveTableView:(FMMoveTableView *)tableView moveRowFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

@end



@interface FMMoveTableView : UITableView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <FMMoveTableViewDataSource> dataSource;
@property (nonatomic, weak) id <FMMoveTableViewDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *movingIndexPath;

- (BOOL)indexPathIsMovingIndexPath:(NSIndexPath *)indexPath;

@end
