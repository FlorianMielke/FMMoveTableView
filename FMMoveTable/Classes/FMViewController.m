//
//  FMViewController.m
//  FMMoveTableView Sample Code
//
//  Created by Florian Mielke.
//  Copyright 2012 Florian Mielke. All rights reserved.
//  


#import "FMViewController.h"
#import "FMMoveTableView.h"
#import "FMMoveTableViewCell.h"


@interface FMViewController ()

@property (nonatomic, strong) NSMutableArray *movies;

@end



@implementation FMViewController

static NSString *sCellIdentifier;

#define kIndexNameOfMovie		0
#define kIndexYearOfMovie		1
#define kIndexRowHeightOfMovie  2


+ (void)initialize
{
    sCellIdentifier = @"MoveCell";
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [self.movies count];
}


- (NSInteger)tableView:(FMMoveTableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger numberOfRows = [[self.movies objectAtIndex:section] count];
	
	#warning Implement this check in your table data source
	/******************************** NOTE ********************************
	 * Implement this check in your table view data source to ensure correct access to the data source
	 *
	 * The data source is in a dirty state when moving a row and is only being updated after the user 
	 * releases the moving row
	 **********************************************************************/
	
	// 1. A row is in a moving state
	// 2. The moving row is not in it's initial section
	if (tableView.movingIndexPath && tableView.movingIndexPath.section != tableView.initialIndexPathForMovingRow.section)
	{
		if (section == tableView.movingIndexPath.section) {
			numberOfRows++;
		}
		else if (section == tableView.initialIndexPathForMovingRow.section) {
			numberOfRows--;
		}
	}
	
	return numberOfRows;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [NSString stringWithFormat:@"Section %i", section];
}


- (UITableViewCell *)tableView:(FMMoveTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	FMMoveTableViewCell *cell = (FMMoveTableViewCell *)[tableView dequeueReusableCellWithIdentifier:sCellIdentifier];
	

	#warning Implement this check in your table view data source
	/******************************** NOTE ********************************
	 * Implement this check in your table view data source to ensure that the moving 
	 * row's content is being reseted
	 **********************************************************************/
	if ([tableView indexPathIsMovingIndexPath:indexPath]) 
	{
		[cell prepareForMove];
	}
	else 
	{
		#warning Implement this check in your table view data source
		/******************************** NOTE ********************************
		 * Implement this check in your table view data source to ensure correct access to the data source
		 *
		 * The data source is in a dirty state when moving a row and is only being updated after the user 
		 * releases the moving row
		 **********************************************************************/
		if (tableView.movingIndexPath != nil) {
            indexPath = [tableView adaptedIndexPathForRowAtIndexPath:indexPath];
		}
		
		
		NSMutableArray *moviesInSection = [self.movies objectAtIndex:indexPath.section];
		NSArray *movie = [moviesInSection objectAtIndex:indexPath.row];
		
        cell.textLabel.text = [movie objectAtIndex:kIndexNameOfMovie];
        cell.detailTextLabel.text = [movie objectAtIndex:kIndexYearOfMovie];
        cell.shouldIndentWhileEditing = NO;
        cell.showsReorderControl = NO;
	}

	return cell;
}


- (BOOL)moveTableView:(FMMoveTableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}


- (void)moveTableView:(FMMoveTableView *)tableView moveRowFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	NSArray *movie = [[self.movies objectAtIndex:fromIndexPath.section] objectAtIndex:fromIndexPath.row];
	[[self.movies objectAtIndex:fromIndexPath.section] removeObjectAtIndex:fromIndexPath.row];
	[[self.movies objectAtIndex:toIndexPath.section] insertObject:movie atIndex:toIndexPath.row];
	
	DLog(@"Moved row from %@ to %@", fromIndexPath, toIndexPath);
}



#pragma mark - Table view delegate

- (CGFloat)tableView:(FMMoveTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    #warning Implement this check in your table view delegate if necessary
    /******************************** NOTE ********************************
     * Implement this check in your table view delegate to ensure correct access to the row heights in 
     * data source. 
     *
     * SKIP this check if all of your rows have the same heigt!
     *
     * The data source is in a dirty state when moving a row and is only being updated after the user
     * releases the moving row
     **********************************************************************/
    indexPath = [tableView adaptedIndexPathForRowAtIndexPath:indexPath];
	
    NSArray *movie = [[self.movies objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    CGFloat heightForRow = [[movie objectAtIndex:kIndexRowHeightOfMovie] floatValue];

    return heightForRow;
}


- (NSIndexPath *)moveTableView:(FMMoveTableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	//	Uncomment these lines to enable moving a row just within it's current section
	//	if ([sourceIndexPath section] != [proposedDestinationIndexPath section]) {
	//		proposedDestinationIndexPath = sourceIndexPath;
	//	}
	
	return proposedDestinationIndexPath;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	DLog(@"Did select row at %@", indexPath);
}



#pragma mark - Accessor methods

- (NSMutableArray *)movies
{
	if (_movies != nil) {
        return _movies;
    }

    NSString *path = [[NSBundle mainBundle] pathForResource:@"Movies" ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:path];
    
    NSMutableArray *sampleData = [[dict valueForKey:@"Movies"] mutableCopy];
    NSRange rangeOne = NSMakeRange(0, 15);
    NSRange rangeTwo = NSMakeRange(15, 15);
    
    NSMutableArray *sectionOne = [[sampleData objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rangeOne]] mutableCopy];
    NSMutableArray *sectionTwo = [[sampleData objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:rangeTwo]] mutableCopy];
    
    _movies = [NSMutableArray arrayWithObjects:sectionOne, sectionTwo, nil];
	
	return _movies;
}


@end
