//
//  SAMHUDWindowViewController.m
//  SAMHUDView
//
//  Created by Sam Soffes on 3/30/14.
//  Copyright 2014 Sam Soffes. All rights reserved.
//

#import "SAMHUDWindowViewController.h"

@implementation SAMHUDWindowViewController

@synthesize statusBarStyle = _statusBarStyle;

- (UIStatusBarStyle)preferredStatusBarStyle {
	return self.statusBarStyle;
}

#pragma mark - Rotation support

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
