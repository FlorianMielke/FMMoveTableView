//
//  FMMoveTableViewCell.m
//  FMFramework
//
//  Created by Florian Mielke.
//  Copyright 2012 Florian Mielke. All rights reserved.
//  

#import "FMMoveTableViewCell.h"


@implementation FMMoveTableViewCell


- (void)prepareForMoveSnapshot
{
    
}


- (void)prepareForMove
{
    self.textLabel.text = @"";
    self.detailTextLabel.text = @"";
    self.imageView.image = nil;
}


@end
