//
//  WDDNavigationControllerPortrait.m
//  Woddl
//
//  Created by Oleg Komaristov on 19.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDNavigationControllerPortrait.h"

@interface WDDNavigationControllerPortrait ()

@end

@implementation WDDNavigationControllerPortrait

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end
