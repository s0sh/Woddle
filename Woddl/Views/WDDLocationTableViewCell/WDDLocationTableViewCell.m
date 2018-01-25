//
//  WDDLocationTableViewCell.m
//  Woddl
//
//  Created by Sergii Gordiienko on 16.04.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "WDDLocationTableViewCell.h"

NSString * const WDDLocationTableViewCellIdentifier = @"LocationCell";

@implementation WDDLocationTableViewCell

- (void)prepareForReuse
{
    self.locationLabel.text = nil;
    
    [super prepareForReuse];
}

@end
