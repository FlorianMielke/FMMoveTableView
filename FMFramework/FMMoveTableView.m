//
//  FMMoveTableView.m
//  FMFramework
//
//  Created by Florian Mielke.
//  Copyright 2012 Florian Mielke. All rights reserved.
//  

#import "FMMoveTableView.h"
#import "FMMoveTableViewCell.h"


/**
 * We need a little helper to cancel the current touch of the long press gesture recognizer
 * in the case the user does not tap on a row but on a section or table header
 */
@interface UIGestureRecognizer (FMUtilities)

- (void)cancelTouch;

@end


@implementation UIGestureRecognizer (FMUtilities)

- (void)cancelTouch
{
    self.enabled = NO;
    self.enabled = YES;
}

@end


@interface FMMoveTableView ()

@property (nonatomic, assign) CGPoint touchOffset;
@property (nonatomic, strong) UIView *snapShotOfMovingCell;
@property (nonatomic, strong) UILongPressGestureRecognizer *movingGestureRecognizer;

@property (nonatomic, strong) NSTimer *autoscrollTimer;
@property (nonatomic, assign) NSInteger autoscrollDistance;
@property (nonatomic, assign) NSInteger autoscrollThreshold;

@end



/**
 * The autoscroll methods are based on Apple's sample code 'ScrollViewSuite'
 */
@interface FMMoveTableView (Autoscrolling)

- (void)maybeAutoscrollForSnapShot:(UIView *)snapShot;
- (void)autoscrollTimerFired:(NSTimer *)timer;
- (void)legalizeAutoscrollDistance;
- (float)autoscrollDistanceForProximityToEdge:(float)proximity;
- (void)stopAutoscrolling;

@end



@implementation FMMoveTableView

@dynamic dataSource;
@dynamic delegate;



#pragma mark - View life cycle

- (void)prepareGestureRecognizer
{
	UILongPressGestureRecognizer *movingGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	[movingGestureRecognizer setDelegate:self];
	[self addGestureRecognizer:movingGestureRecognizer];
	[self setMovingGestureRecognizer:movingGestureRecognizer];
}


- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self prepareGestureRecognizer];
}


- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
	self = [super initWithFrame:frame style:style];
	
	if (self) {
		[self prepareGestureRecognizer];
	}
	
	return self;
}



#pragma mark - Helper methods

- (BOOL)indexPathIsMovingIndexPath:(NSIndexPath *)indexPath
{
	return ([indexPath compare:self.movingIndexPath] == NSOrderedSame);
}


- (void)moveRowToLocation:(CGPoint)location 
{
	NSIndexPath *newIndexPath = [self indexPathForRowAtPoint:location];
	
	// Analyze the new moving index path
	// 1. It's a valid index path
	// 2. It's not the current index path of the cell
	if ([newIndexPath section] != NSNotFound && [newIndexPath row] != NSNotFound && [newIndexPath compare:self.movingIndexPath] != NSOrderedSame) 
	{
		if ([self.delegate respondsToSelector:@selector(moveTableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]) 
		{
			NSIndexPath *proposedDestinationIndexPath = [self.delegate moveTableView:self targetIndexPathForMoveFromRowAtIndexPath:self.movingIndexPath toProposedIndexPath:newIndexPath];
			
			// If the delegate does not allow moving to the new index path cancel moving row
			if ([newIndexPath compare:proposedDestinationIndexPath] != NSOrderedSame) {
				return;
			}
		}
		
		[self beginUpdates];
		
		// Move the row
		[self deleteRowsAtIndexPaths:@[self.movingIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
		
		// Update the moving index path
        self.movingIndexPath = newIndexPath;
		[self endUpdates];
	}
}


- (NSIndexPath *)adaptedIndexPathForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Skip further calulations
    // 1. There's no row in a moving state
    // 2. Index path is in a different section than the moving row
    if (self.movingIndexPath == nil) {
        return indexPath;
    }
    
    CGFloat adaptedRow = NSNotFound;
    NSInteger movingRowOffset = 1;

    // It's the moving row so return the initial index path
    if ([indexPath compare:self.movingIndexPath] == NSOrderedSame)
    {
        indexPath = self.initialIndexPathForMovingRow;
    }
    // Moving row is still in it's inital section
    else if (self.movingIndexPath.section == self.initialIndexPathForMovingRow.section)
    {
        // 1. Index path comes after initial row or is at initial row
        // 2. Index path comes before moving row
        if (indexPath.row >= self.initialIndexPathForMovingRow.row && indexPath.row < self.movingIndexPath.row)
        {
            adaptedRow = indexPath.row + movingRowOffset;
        }
        // 1. Index path comes before initial row or is at initial row
        // 2. Index path comes after moving row
        else if (indexPath.row <= self.initialIndexPathForMovingRow.row && indexPath.row > self.movingIndexPath.row)
        {
            adaptedRow = indexPath.row - movingRowOffset;
        }
    }
    // Moving row is no longer in it's inital section
    else if (self.movingIndexPath.section != self.initialIndexPathForMovingRow.section)
    {
        // 1. Index path is in the moving rows initial section
        // 2. Index path comes after initial row or is at initial row
        if (indexPath.section == self.initialIndexPathForMovingRow.section && indexPath.row >= self.initialIndexPathForMovingRow.row)
        {
            adaptedRow = indexPath.row + movingRowOffset;
        }
        // 1. Index path is in the moving rows current section
        // 2. Index path comes before moving row
        else if (indexPath.section == self.movingIndexPath.section && indexPath.row > self.movingIndexPath.row)
        {
            adaptedRow = indexPath.row - movingRowOffset;
        }
    }

    // We finally need to create an adapted index path
    if (adaptedRow != NSNotFound)
    {
        indexPath = [NSIndexPath indexPathForRow:adaptedRow inSection:indexPath.section];
    }
    
	return indexPath;
}



#pragma mark - Handle long press

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	BOOL shouldBegin = YES;
	
	if ([gestureRecognizer isEqual:self.movingGestureRecognizer])
	{
		// Ask the data source if we are allowed to move the touched row
		if ([self.dataSource respondsToSelector:@selector(moveTableView:canMoveRowAtIndexPath:)]) 
		{
			// Grap the touched index path
			CGPoint touchPoint = [gestureRecognizer locationInView:self];
			NSIndexPath *touchedIndexPath = [self indexPathForRowAtPoint:touchPoint];
			shouldBegin = [self.dataSource moveTableView:self canMoveRowAtIndexPath:touchedIndexPath];
		}
	}
	
	return shouldBegin;
}


- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
	switch (gestureRecognizer.state)
	{
		case UIGestureRecognizerStateBegan:
		{
			CGPoint touchPoint = [gestureRecognizer locationInView:self];
			
			// Grap the touched index path
			NSIndexPath *touchedIndexPath = [self indexPathForRowAtPoint:touchPoint];
			
			// Check for a valid index path, otherwise cancel the touch
			if (touchedIndexPath == nil || touchedIndexPath.section == NSNotFound || touchedIndexPath.row == NSNotFound) {
				[gestureRecognizer cancelTouch];
				break;
			}

            self.initialIndexPathForMovingRow = touchedIndexPath;
            self.movingIndexPath = touchedIndexPath;
			
            [self prepareSnapShotForRowAtIndexPath:touchedIndexPath touchPoint:touchPoint];
			
			// Inform the delegate about the beginning of the move
			if ([self.delegate respondsToSelector:@selector(moveTableView:willMoveRowAtIndexPath:)]) {
				[self.delegate moveTableView:self willMoveRowAtIndexPath:touchedIndexPath];
			}
			
			// Set a threshold for autoscrolling and reset the autoscroll distance
            self.autoscrollThreshold = CGRectGetHeight(self.snapShotOfMovingCell.frame) * 0.6;
            self.autoscrollDistance = 0.0;
			
			break;
		}
			
		case UIGestureRecognizerStateChanged:
		{
			CGPoint touchPoint = [gestureRecognizer locationInView:self];
			
			// Update the snap shot's position
			CGPoint currentCenter = self.snapShotOfMovingCell.center;
			self.snapShotOfMovingCell.center = CGPointMake(currentCenter.x, touchPoint.y + self.touchOffset.y);
			
			// Check if the table view has to scroll
			[self maybeAutoscrollForSnapShot:self.snapShotOfMovingCell];
			
			// If the table view does not scroll, compute a new index path for the moving cell
			if (self.autoscrollDistance == 0) {
				[self moveRowToLocation:touchPoint];
			}
			
			break;
		}
			
		case UIGestureRecognizerStateEnded:
		{
			[self stopAutoscrolling];
			
			// Get to final index path
			CGRect finalFrame = [self rectForRowAtIndexPath:self.movingIndexPath];
			
			// Place the snap shot to it's final position and fade it out
			[UIView animateWithDuration:0.2
							 animations:^{
								 
								 self.snapShotOfMovingCell.frame = finalFrame;
								 self.snapShotOfMovingCell.alpha = 1.0;
								 
							 }
							 completion:^(BOOL finished) {
								 
								 if (finished) 
								 {
									 // Clean up snap shot
									 [self.snapShotOfMovingCell removeFromSuperview];
                                     self.snapShotOfMovingCell = nil;
									 
									 // Inform the data source about the new position if necessary
									 if ([self.initialIndexPathForMovingRow compare:self.movingIndexPath] != NSOrderedSame) {
										 [self.dataSource moveTableView:self moveRowFromIndexPath:self.initialIndexPathForMovingRow toIndexPath:self.movingIndexPath];
									 }
									 
									 // Reload row at moving index path to reset it's content
									 NSIndexPath *movingIndexPath = [self.movingIndexPath copy];
									 self.movingIndexPath = nil;
                                     self.initialIndexPathForMovingRow = nil;
									 [self reloadRowsAtIndexPaths:@[movingIndexPath] withRowAnimation:UITableViewRowAnimationNone];
								 }
								 
							 }];			
			
			break;
		}
			
		default:
		{
            [self resetToInitialStateIfNeeded];
			break;
		}
	}
}


- (void)prepareSnapShotForRowAtIndexPath:(NSIndexPath *)touchedIndexPath touchPoint:(CGPoint)touchPoint
{
    // Get the touched cell and reset it's selection state
    FMMoveTableViewCell *touchedCell = (FMMoveTableViewCell *)[self cellForRowAtIndexPath:touchedIndexPath];
    touchedCell.selected = NO;
    touchedCell.highlighted = NO;
    
    // Create a snap shot of the touched cell and prepare it
    self.snapShotOfMovingCell = [touchedCell snapshotViewAfterScreenUpdates:YES];
    self.snapShotOfMovingCell.frame = touchedCell.frame;
    self.snapShotOfMovingCell.alpha = 0.95;
    self.snapShotOfMovingCell.layer.shadowOpacity = 0.7;
    self.snapShotOfMovingCell.layer.shadowRadius = 3.0;
    self.snapShotOfMovingCell.layer.shadowOffset = CGSizeZero;
    self.snapShotOfMovingCell.layer.shadowPath = [[UIBezierPath bezierPathWithRect:self.snapShotOfMovingCell.layer.bounds] CGPath];
    
    [self addSubview:self.snapShotOfMovingCell];
    
    // Prepare the cell for moving (e.g. clear it's labels and imageView)
    [touchedCell prepareForMove];

    // Compute the touch offset from the cell's center
    self.touchOffset = CGPointMake(touchedCell.center.x - touchPoint.x, touchedCell.center.y - touchPoint.y);
}


- (void)resetToInitialStateIfNeeded
{
    if (self.movingIndexPath != nil)
    {
        [self stopAutoscrolling];
        
        [self.snapShotOfMovingCell removeFromSuperview];
        self.snapShotOfMovingCell = nil;
        
        NSIndexPath *movingIndexPath = self.movingIndexPath;
        self.movingIndexPath = nil;
        self.initialIndexPathForMovingRow = nil;
        [self reloadRowsAtIndexPaths:@[movingIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}



#pragma mark - Autoscrolling

- (void)maybeAutoscrollForSnapShot:(UIView *)snapShot
{
    [self determineAutoscrollDistanceForSnapShot:snapShot];
    
    if (self.autoscrollDistance == 0)
	{
        [self.autoscrollTimer invalidate];
        self.autoscrollTimer = nil;
    } 
    else if (self.autoscrollTimer == nil)
	{
        self.autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0) target:self selector:@selector(autoscrollTimerFired:) userInfo:nil repeats:YES];
    }
}


- (void)determineAutoscrollDistanceForSnapShot:(UIView *)snapShot
{
    self.autoscrollDistance = 0;
    
	// Check for autoscrolling
	// 1. The content size is bigger than the frame's
	// 2. The snap shot is still inside the table view's bounds
    if ([self canScroll] && CGRectIntersectsRect(snapShot.frame, self.bounds))
	{
		CGPoint touchLocation = [self.movingGestureRecognizer locationInView:self];
		touchLocation.y += self.touchOffset.y;
		
        CGFloat distanceToTopEdge = touchLocation.y - CGRectGetMinY(self.bounds) - self.scrollIndicatorInsets.top;
        CGFloat distanceToBottomEdge = CGRectGetMaxY(self.bounds) - self.scrollIndicatorInsets.bottom - touchLocation.y;
        
        if (distanceToTopEdge < self.autoscrollThreshold)
		{
            self.autoscrollDistance = [self autoscrollDistanceForProximityToEdge:distanceToTopEdge] * -1;
        }
		else if (distanceToBottomEdge < self.autoscrollThreshold)
		{
            self.autoscrollDistance = [self autoscrollDistanceForProximityToEdge:distanceToBottomEdge];
        }
    }
}


- (CGFloat)autoscrollDistanceForProximityToEdge:(CGFloat)proximity
{
    return ceilf((self.autoscrollThreshold - proximity) / 5.0);
}


- (void)autoscrollTimerFired:(NSTimer *)timer
{
    [self legalizeAutoscrollDistance];
    
    // Autoscroll table view
    CGPoint contentOffset = self.contentOffset;
    contentOffset.y += self.autoscrollDistance;
    self.contentOffset = contentOffset;

	// Move the snap shot appropriately
    CGRect frame = self.snapShotOfMovingCell.frame;
    frame.origin.y += self.autoscrollDistance;
    self.snapShotOfMovingCell.frame = frame;
	
	// During autoscrolling we need to update the moved cell's index path
	CGPoint touchLocation = [self.movingGestureRecognizer locationInView:self];
	[self moveRowToLocation:touchLocation];
}


- (void)legalizeAutoscrollDistance
{
    CGFloat minimumLegalDistance = self.contentOffset.y * -1.0;
    CGFloat maximumLegalDistance = self.contentSize.height - (CGRectGetHeight(self.frame) + self.contentOffset.y);
    self.autoscrollDistance = MAX(self.autoscrollDistance, minimumLegalDistance);
    self.autoscrollDistance = MIN(self.autoscrollDistance, maximumLegalDistance);
}


- (void)stopAutoscrolling
{
    self.autoscrollDistance = 0.0;
	[self.autoscrollTimer invalidate];
	self.autoscrollTimer = nil;
}


- (BOOL)canScroll
{
    return (CGRectGetHeight(self.frame) < self.contentSize.height);
}


@end
