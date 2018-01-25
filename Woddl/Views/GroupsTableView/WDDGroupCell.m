//
//  WDDGroupCell.m
//  Woddl
//
//  Created by Sergii Gordiienko on 27.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDGroupCell.h"

@implementation WDDGroupCell


- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.groupNameLabel.text = nil;
    
    [self.groupStatusButton setImage:nil forState:UIControlStateNormal];
}

- (IBAction)groupStatusButtonPressed:(id)sender
{
    [self.delegate groupCelldidTapGroupStatusButton:self];
}

@end
