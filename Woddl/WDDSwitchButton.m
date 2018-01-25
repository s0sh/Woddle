//
//  WDDSwitchButton.m
//  Woddl
//
//  Created by Oleg Komaristov on 19.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDSwitchButton.h"

@implementation WDDSwitchButton

- (void)awakeFromNib
{
    [self initialize];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self initialize];
    }
    
    return self;
}

- (void)initialize
{
    [self setImage:[UIImage imageNamed:@"switchOff"] forState:UIControlStateNormal];
    [self setImage:[UIImage imageNamed:@"switchOn"] forState:UIControlStateSelected];
    [self addTarget:self action:@selector(pressed) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Setters / getters implementation

- (void)setOn:(BOOL)on
{
    self.selected = on;
}

- (BOOL)on
{
    return self.selected;
}

- (BOOL)isOn
{
    return self.selected;
}

#pragma mark - User actions processing

- (void)pressed
{
    self.selected = !self.selected;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
