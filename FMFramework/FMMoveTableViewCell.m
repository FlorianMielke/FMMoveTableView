//
//  FMMoveTableViewCell.m
//  FMFramework
//
//  Created by Florian Mielke.
//  Copyright 2012 Florian Mielke. All rights reserved.
//  


#import "FMMoveTableViewCell.h"

@implementation FMMoveTableViewCell


- (void)prepareForMove
{
	UIView *coverView = [[UIView alloc] initWithFrame:self.contentView.frame];
	coverView.backgroundColor = [UIColor whiteColor];
	
	[self.contentView addSubview:coverView];
}


@end
