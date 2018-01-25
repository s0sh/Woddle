//
//  WDDAddFriendCell.m
//  Woddl
//
//  Created by Sergii Gordiienko on 26.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDAddFriendCell.h"

@implementation WDDAddFriendCell




- (void)prepareForReuse
{
    [super prepareForReuse];
    [self resetCellViews];
}


- (void)resetCellViews
{
    self.usernameLabel.text = nil;
    self.avatarImageView.image = nil;
    self.snIconImageView.image = nil;
}
@end
