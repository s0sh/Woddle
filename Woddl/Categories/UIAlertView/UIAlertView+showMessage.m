//
//  UIAlertView+showMessage.m
//  Woddl
//
//  Created by Sergii Gordiienko on 16.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "UIAlertView+showMessage.h"

@implementation UIAlertView (showMessage)
+ (void)showAlertWithMessage:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:nil
                                message:message
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"lskOK", @"")
                      otherButtonTitles:nil] show];
}
@end
