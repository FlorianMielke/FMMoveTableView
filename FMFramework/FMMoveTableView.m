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
 * When the long press gesture recognizer began, we create a snap shot of the touched
 * cell so the user thinks that he is moving the cell itself. Instead we clear out the
 * touched cell and just move snap shot.
 */

@interface FMSnapShotImageView : UIImageView

- (void)moveByOffset:(CGPoint)offset;

@end


@implementation FMSnapShotImageView


#pragma mark -
#pragma mark Autoscroll utilites

- (void)moveByOffset:(CGPoint)offset 
{
    CGRect frame = [self frame];
    frame.origin.x += offset.x;
    frame.origin.y += offset.y;
    [self setFrame:frame];
}

@end



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
	[self setEnabled:NO];
	[self setEnabled:YES];
}

@end



@interface FMMoveTableView ()

@property (nonatomic, assign) CGPoint touchOffset;
@property (nonatomic, strong) FMSnapShotImageView *snapShotImageView;
@property (nonatomic, strong) UILongPressGestureRecognizer *movingGestureRecognizer;

@property (nonatomic, strong) NSTimer *autoscrollTimer;
@property (nonatomic, assign) NSInteger autoscrollDistance;
@property (nonatomic, assign) NSInteger autoscrollThreshold;

@end



/**
 * The autoscroll methods are based on Apple's sample code 'ScrollViewSuite'
 */

@interface FMMoveTableView (AutoscrollingMethods)

- (void)maybeAutoscrollForSnapShotImageView:(FMSnapShotImageView *)snapShot;
- (void)autoscrollTimerFired:(NSTimer *)timer;
- (void)legalizeAutoscrollDistance;
- (float)autoscrollDistanceForProximityToEdge:(float)proximity;
- (void)stopAutoscrolling;

@end




@implementation FMMoveTableView

@dynamic dataSource;
@dynamic delegate;
@synthesize initialIndexPathForMovingRow = _initialIndexPathForMovingRow;
@synthesize movingIndexPath = _movingIndexPath;
@synthesize touchOffset = _touchOffset;
@synthesize snapShotImageView = _snapShotImageView;
@synthesize movingGestureRecognizer = _movingGestureRecognizer;

@synthesize autoscrollTimer = _autoscrollTimer;
@synthesize autoscrollDistance = _autoscrollDistance;
@synthesize autoscrollThreshold = _autoscrollThreshold;



#pragma mark -
#pragma mark View life cycle

- (void)setup
{
	UILongPressGestureRecognizer *movingGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	[movingGestureRecognizer setDelegate:self];
	[self addGestureRecognizer:movingGestureRecognizer];
	[self setMovingGestureRecognizer:movingGestureRecognizer];
}


- (void)awakeFromNib
{
	[super awakeFromNib];
	
	[self setup];
}


- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
	self = [super initWithFrame:frame style:style];
	
	if (self) {
		[self setup];
	}
	
	return self;
}



#pragma mark -
#pragma mark Helper methods

- (BOOL)indexPathIsMovingIndexPath:(NSIndexPath *)indexPath
{
	return ([indexPath compare:[self movingIndexPath]] == NSOrderedSame);
}


- (void)moveRowToLocation:(CGPoint)location 
{
	NSIndexPath *newIndexPath = [self indexPathForRowAtPoint:location];
	
	// Analyze the new moving index path
	// 1. It's a valid index path
	// 2. It's not the current index path of the cell
	if ([newIndexPath section] != NSNotFound && [newIndexPath row] != NSNotFound && [newIndexPath compare:[self movingIndexPath]] != NSOrderedSame) 
	{
		if ([[self delegate] respondsToSelector:@selector(moveTableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]) 
		{
			NSIndexPath *proposedDestinationIndexPath = [[self delegate] moveTableView:self targetIndexPathForMoveFromRowAtIndexPath:[self movingIndexPath] toProposedIndexPath:newIndexPath];
			
			// If the delegate does not allow moving to the new index path cancel moving row
			if ([newIndexPath compare:proposedDestinationIndexPath] != NSOrderedSame) {
				return;
			}
		}
		
		[self beginUpdates];
		
		// Move the row
		[self deleteRowsAtIndexPaths:[NSArray arrayWithObject:[self movingIndexPath]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		
		// Update the moving index path
		[self setMovingIndexPath:newIndexPath];
		[self endUpdates];
	}
}


- (NSIndexPath *)adaptedIndexPathForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Skip further calulations
    // 1. There's no row in a moving state
    // 2. Index path is in a different section than the moving row
    if (![self movingIndexPath]) {
        return indexPath;
    }
    
    CGFloat adaptedRow = NSNotFound;

    // It's the moving row so return the initial index path
    if ([indexPath compare:[self movingIndexPath]] == NSOrderedSame)
    {
        indexPath = [self initialIndexPathForMovingRow];
    }
    // Moving row is still in it's inital section
    else if ([[self movingIndexPath] section] == [[self initialIndexPathForMovingRow] section])
    {
        // 1. Index path comes after initial row or is at initial row
        // 2. Index path comes before moving row
        if ([indexPath row] >= [[self initialIndexPathForMovingRow] row] && [indexPath row] < [[self movingIndexPath] row])
        {
            adaptedRow = [indexPath row] + 1;
        }
        // 1. Index path comes before initial row or is at initial row
        // 2. Index path comes after moving row
        else if ([indexPath row] <= [[self initialIndexPathForMovingRow] row] && [indexPath row] > [[self movingIndexPath] row])
        {
            adaptedRow = [indexPath row] - 1;
        }
    }
    // Moving row is no longer in it's inital section
    else if ([[self movingIndexPath] section] != [[self initialIndexPathForMovingRow] section])
    {
        // 1. Index path is in the moving rows initial section
        // 2. Index path comes after initial row or is at initial row
        if ([indexPath section] == [[self initialIndexPathForMovingRow] section] && [indexPath row] >= [[self initialIndexPathForMovingRow] row])
        {
            adaptedRow = [indexPath row] + 1;
        }
        // 1. Index path is in the moving rows current section
        // 2. Index path comes before moving row
        else if ([indexPath section] == [[self movingIndexPath] section] && [indexPath row] > [[self movingIndexPath] row])
        {
            adaptedRow = [indexPath row] - 1;
        }
    }

    // We finally need to create an adapted index path
    if (adaptedRow != NSNotFound)
    {
        indexPath = [NSIndexPath indexPathForRow:adaptedRow inSection:[indexPath section]];
    }
    
	return indexPath;
}



#pragma mark -
#pragma mark Handle long press

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	BOOL shouldBegin = YES;
	
	if ([gestureRecognizer isEqual:[self movingGestureRecognizer]])
	{
		// Ask the data source if we are allowed to move the touched row
		if ([[self dataSource] respondsToSelector:@selector(moveTableView:canMoveRowAtIndexPath:)]) 
		{
			// Grap the touched index path
			CGPoint touchPoint = [gestureRecognizer locationInView:self];
			NSIndexPath *touchedIndexPath = [self indexPathForRowAtPoint:touchPoint];
			
			shouldBegin = [[self dataSource] moveTableView:self canMoveRowAtIndexPath:touchedIndexPath];
		}
	}
	
	return shouldBegin;
}


- (void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
	switch ([gestureRecognizer state]) 
	{
		case UIGestureRecognizerStateBegan:
		{
			CGPoint touchPoint = [gestureRecognizer locationInView:self];
			
			// Grap the touched index path
			NSIndexPath *touchedIndexPath = [self indexPathForRowAtPoint:touchPoint];
			
			// Check for a valid index path, otherwise cancel the touch
			if (!touchedIndexPath || [touchedIndexPath section] == NSNotFound || [touchedIndexPath row] == NSNotFound) {
				[gestureRecognizer cancelTouch];
				break;
			}

			[self setInitialIndexPathForMovingRow:touchedIndexPath];
			[self setMovingIndexPath:touchedIndexPath];

			
			// Get the touched cell and reset it's selection state
			FMMoveTableViewCell *touchedCell = (FMMoveTableViewCell *)[self cellForRowAtIndexPath:touchedIndexPath];
			[touchedCell setSelected:NO];
			[touchedCell setHighlighted:NO];
			
			// Compute the touch offset from the cell's center
			CGPoint touchOffset = CGPointMake([touchedCell center].x - touchPoint.x, [touchedCell center].y - touchPoint.y);
			[self setTouchOffset:touchOffset];
			
			
			// Create a snap shot of the touched cell and store it
			CGRect cellFrame = [touchedCell bounds];
			
			if ([[UIScreen mainScreen] scale] == 2.0) {
				UIGraphicsBeginImageContextWithOptions(cellFrame.size, NO, 2.0);
			} else {
				UIGraphicsBeginImageContext(cellFrame.size);
			}
			
			[[touchedCell layer] renderInContext:UIGraphicsGetCurrentContext()];
			UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
			
			FMSnapShotImageView *snapShotOfMovingCell = [[FMSnapShotImageView alloc] initWithImage:image];
			CGRect snapShotFrame = [self rectForRowAtIndexPath:touchedIndexPath];
			snapShotFrame.size = cellFrame.size;
			[snapShotOfMovingCell setFrame:snapShotFrame];
			[snapShotOfMovingCell setAlpha:0.95];
			
			[self setSnapShotImageView:snapShotOfMovingCell];
			[self addSubview:[self snapShotImageView]];
			
			
			// Prepare the cell for moving (e.g. clear it's labels and imageView)
			[touchedCell prepareForMove];
			
			// Inform the delegate about the beginning of the move
			if ([[self delegate] respondsToSelector:@selector(moveTableView:willMoveRowAtIndexPath:)]) {
				[[self delegate] moveTableView:self willMoveRowAtIndexPath:touchedIndexPath];
			}
			
			// Set a threshold for autoscrolling and reset the autoscroll distance
			[self setAutoscrollThreshold:([[self snapShotImageView] frame].size.height * 0.6)];
			[self setAutoscrollDistance:0.0];
			
			break;
		}
			
		case UIGestureRecognizerStateChanged:
		{
			CGPoint touchPoint = [gestureRecognizer locationInView:self];
			
			// Update the snap shot's position
			CGPoint currentCenter = [[self snapShotImageView] center];
			[[self snapShotImageView] setCenter:CGPointMake(currentCenter.x, touchPoint.y + [self touchOffset].y)];
			
			// Check if the table view has to scroll
			[self maybeAutoscrollForSnapShotImageView:[self snapShotImageView]];
			
			// If the table view does not scroll, compute a new index path for the moving cell
			if ([self autoscrollDistance] == 0) {
				[self moveRowToLocation:touchPoint];
			}
			
			break;
		}
			
		case UIGestureRecognizerStateEnded:
		{
			[self stopAutoscrolling];
			
			// Get to final index path
			CGRect finalFrame = [self rectForRowAtIndexPath:[self movingIndexPath]];
			
			// Place the snap shot to it's final position and fade it out
			[UIView animateWithDuration:0.2
							 animations:^{
								 
								 [[self snapShotImageView] setFrame:finalFrame];
								 [[self snapShotImageView] setAlpha:1.0];
								 
							 }
							 completion:^(BOOL finished) {
								 
								 if (finished) 
								 {
									 // Clean up snap shot
									 [[self snapShotImageView] removeFromSuperview];
									 [self setSnapShotImageView:nil];
									 
									 // Inform the data source about the new position if necessary
									 if ([[self initialIndexPathForMovingRow] compare:[self movingIndexPath]] != NSOrderedSame) {
										 [[self dataSource] moveTableView:self moveRowFromIndexPath:[self initialIndexPathForMovingRow] toIndexPath:[self movingIndexPath]];
									 }
									 
									 // Reload row at moving index path to reset it's content
									 NSIndexPath *movingIndexPath = [[self movingIndexPath] copy];
									 [self setMovingIndexPath:nil];
									 [self setInitialIndexPathForMovingRow:nil];
									 [self reloadRowsAtIndexPaths:[NSArray arrayWithObject:movingIndexPath] withRowAnimation:UITableViewRowAnimationNone];
								 }
								 
							 }];			
			
			break;
		}
			
		default:
		{
			// Do some cleanup if necessary
			if ([self movingIndexPath]) 
			{
				[self stopAutoscrolling];
				
				[[self snapShotImageView] removeFromSuperview];
				[self setSnapShotImageView:nil];
				
				NSIndexPath *movingIndexPath = [self movingIndexPath];
				[self setMovingIndexPath:nil];
				[self setInitialIndexPathForMovingRow:nil];
				[self reloadRowsAtIndexPaths:[NSArray arrayWithObject:movingIndexPath] withRowAnimation:UITableViewRowAnimationNone];
			}
			
			break;
		}
	}
}



#pragma mark -
#pragma mark Autoscrolling

- (void)maybeAutoscrollForSnapShotImageView:(FMSnapShotImageView *)snapShot
{
    [self setAutoscrollDistance:0];
    
	// Check for autoscrolling
	// 1. The content size is bigger than the frame's
	// 2. The snap shot is still inside the table view's bounds
    if ([self frame].size.height < [self contentSize].height && CGRectIntersectsRect([snapShot frame], [self bounds])) 
	{
		CGPoint touchLocation = [[self movingGestureRecognizer] locationInView:self];
		touchLocation.y += [self touchOffset].y;
		
        float distanceToTopEdge  = touchLocation.y - CGRectGetMinY([self bounds]);
        float distanceToBottomEdge = CGRectGetMaxY([self bounds]) - touchLocation.y;
		
        if (distanceToTopEdge < [self autoscrollThreshold]) 
		{
            [self setAutoscrollDistance:[self autoscrollDistanceForProximityToEdge:distanceToTopEdge] * -1];
        } 
		else if (distanceToBottomEdge < [self autoscrollThreshold]) 
		{
            [self setAutoscrollDistance:[self autoscrollDistanceForProximityToEdge:distanceToBottomEdge]];
        }
    }
    
    if ([self autoscrollDistance] == 0) 
	{
        [[self autoscrollTimer] invalidate];
        [self setAutoscrollTimer:nil];
    } 
    else if (![self autoscrollTimer]) 
	{
        NSTimer *autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0) target:self selector:@selector(autoscrollTimerFired:) userInfo:snapShot repeats:YES];
		[self setAutoscrollTimer:autoscrollTimer];
    } 
}


- (float)autoscrollDistanceForProximityToEdge:(float)proximity 
{
    return ceilf(([self autoscrollThreshold] - proximity) / 5.0);
}


- (void)legalizeAutoscrollDistance 
{
    float minimumLegalDistance = [self contentOffset].y * -1;
    float maximumLegalDistance = [self contentSize].height - ([self frame].size.height + [self contentOffset].y);
    [self setAutoscrollDistance:MAX([self autoscrollDistance], minimumLegalDistance)];
    [self setAutoscrollDistance:MIN([self autoscrollDistance], maximumLegalDistance)];
}


- (void)autoscrollTimerFired:(NSTimer *)timer 
{
    [self legalizeAutoscrollDistance];
    
    CGPoint contentOffset = [self contentOffset];
    contentOffset.y += [self autoscrollDistance];
    [self setContentOffset:contentOffset];

	// Move the snap shot appropriately
	FMSnapShotImageView *snapShot = (FMSnapShotImageView *)[timer userInfo];
	[snapShot moveByOffset:CGPointMake(0, [self autoscrollDistance])];
	
	// Even if we autoscroll we need to update the moved cell's index path
	CGPoint touchLocation = [[self movingGestureRecognizer] locationInView:self];
	[self moveRowToLocation:touchLocation];
}


- (void)stopAutoscrolling
{
	[self setAutoscrollDistance:0];
	[[self autoscrollTimer] invalidate];
	[self setAutoscrollTimer:nil];
}



#pragma mark -
#pragma mark Accessor methods

- (void)setSnapShotImageView:(FMSnapShotImageView *)snapShotImageView
{
	if (snapShotImageView)
	{
		// Create the shadow if a new snap shot is created
		[[snapShotImageView layer] setShadowOpacity:0.7];
		[[snapShotImageView layer] setShadowRadius:3];
		[[snapShotImageView layer] setShadowOffset:CGSizeZero];
		
		CGPathRef shadowPath = [[UIBezierPath bezierPathWithRect:[[snapShotImageView layer] bounds]] CGPath];
		[[snapShotImageView layer] setShadowPath:shadowPath];
	}
	
	_snapShotImageView = snapShotImageView;
}


@end
