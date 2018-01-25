//
//  WDDSlidingViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 22.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDSlidingViewController.h"

@interface WDDSlidingViewController ()

@end

@implementation WDDSlidingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.topViewController = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDMainScreenNavigationViewController];
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
