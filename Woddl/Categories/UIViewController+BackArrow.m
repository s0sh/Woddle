//
//  UIViewController+BackArrow.m
//  Woddl
//
//  Created by Sergii Gordiienko on 19.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "UIViewController+BackArrow.h"

@implementation UIViewController (BackArrow)

- (void)customizeBackButton
{
    UIImage *backButtonImage = [UIImage imageNamed:kBackButtonArrowImageName];
    UIButton *customBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customBackButton.bounds = CGRectMake( 0, 0, backButtonImage.size.width, backButtonImage.size.height );
    [customBackButton setImage:backButtonImage forState:UIControlStateNormal];
    SEL backActionSelector = ([self.navigationController.viewControllers indexOfObject:self] ? @selector(popBackViewController) : @selector(dismissViewController) );
    [customBackButton addTarget:self action:backActionSelector forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:customBackButton];
}

- (void)popBackViewController
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)dismissViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
