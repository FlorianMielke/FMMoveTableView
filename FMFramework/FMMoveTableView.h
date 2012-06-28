//
//  FMMoveTableView.h
//  FMFramework
//
//  Created by Florian Mielke.
//  Copyright 2012 Florian Mielke. All rights reserved.
//  


@class FMMoveTableView;


@protocol FMMoveTableViewDelegate <NSObject, UITableViewDelegate>

@optional
/*
 If you don't want user put a cell which was lifted from sourceIndexPath to the proposedDestinationIndexPath,
 then return another index path which is allowed to put cell in.
*/
- (NSIndexPath *)moveTableView:(FMMoveTableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath;

//This method will be called when cell being "lifted"
- (void)moveTableView:(FMMoveTableView *)tableView willMoveRowAtIndexPath:(NSIndexPath *)indexPath;

@end



@protocol FMMoveTableViewDataSource <NSObject, UITableViewDataSource>

@required
//This method will be called during each cell moving.Use this to update your data source. 
- (void)moveDataInDataSourceFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

//This method will be called when cell draging finished. You may need update data source in this method.
- (void)moveTableView:(FMMoveTableView *)tableView moveRowFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

@end



@interface FMMoveTableView : UITableView <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <FMMoveTableViewDataSource> dataSource;
@property (nonatomic, weak) id <FMMoveTableViewDelegate> delegate;
@property (nonatomic, strong) NSIndexPath *movingIndexPath;

- (BOOL)indexPathIsMovingIndexPath:(NSIndexPath *)indexPath;

@end
