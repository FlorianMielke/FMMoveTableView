//
//  FMMoveTableViewCell.h
//  FMFramework
//
//  Created by Florian Mielke.
//  Copyright 2012 Florian Mielke. All rights reserved.
//  


@protocol FMMoveTableViewCell <NSObject>

- (void)prepareForMoveSnapshot;
- (void)prepareForMove;

@end
