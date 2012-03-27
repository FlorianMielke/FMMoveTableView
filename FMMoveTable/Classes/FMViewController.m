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

@synthesize movies = _movies;

#define kRowNameOfMovie		0
#define kRowYearOfMovie		1



#pragma mark -
#pragma mark Controller life cycle

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [[[self movies] objectAtIndex:section] count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return [NSString stringWithFormat:@"Section %i", section];
}


- (UITableViewCell *)tableView:(FMMoveTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *cellIdentifier = @"MoveCell";
	FMMoveTableViewCell *cell = (FMMoveTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	
	/******************************** NOTE ********************************
	 * Implement this check in your table view data source to ensure that the moving 
	 * row's content is reseted
	 **********************************************************************/
	if ([tableView indexPathIsMovingIndexPath:indexPath]) 
	{
		[cell prepareForMove];
	}
	else 
	{
		NSMutableArray *moviesOfSection = [[self movies] objectAtIndex:[indexPath section]];
		NSArray *movie = [moviesOfSection objectAtIndex:[indexPath row]];
		
		[[cell textLabel] setText:[movie objectAtIndex:kRowNameOfMovie]];
		[[cell detailTextLabel] setText:[movie objectAtIndex:kRowYearOfMovie]];
		[cell setShouldIndentWhileEditing:NO];
		[cell setShowsReorderControl:NO];
	}
	
	return cell;
}



#pragma mark -
#pragma mark Table view data source

- (void)moveTableView:(FMMoveTableView *)tableView moveRowFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	NSArray *movie = [[[self movies] objectAtIndex:[fromIndexPath section]] objectAtIndex:[fromIndexPath row]];
	[[[self movies] objectAtIndex:[fromIndexPath section]] removeObjectAtIndex:[fromIndexPath row]];
	[[[self movies] objectAtIndex:[toIndexPath section]] insertObject:movie atIndex:[toIndexPath row]];
}


- (NSIndexPath *)moveTableView:(FMMoveTableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if ([sourceIndexPath section] != [proposedDestinationIndexPath section]) {
		proposedDestinationIndexPath = sourceIndexPath;
	}
	
	return proposedDestinationIndexPath;
}



#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	DLog(@"Did select row at %@", indexPath);
}



#pragma mark -
#pragma mark Accessor methods

- (NSMutableArray *)movies
{
	if (!_movies) 
	{
		NSString *path = [[NSBundle mainBundle] pathForResource:@"Movies" ofType:@"plist"];
		NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:path];
		
		NSMutableArray *sectionOne = [[dict valueForKey:@"Movies"] mutableCopy];
		NSMutableArray *sectionTwo = [[dict valueForKey:@"Movies"] mutableCopy];
		
		_movies = [NSMutableArray arrayWithObjects:sectionOne, sectionTwo, nil];
	}
	
	return _movies;
}


@end
