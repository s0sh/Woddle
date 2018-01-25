//
//  UIView+ScrollToTopDisabler.m
//  Woddl
//
//  Created by Sergii Gordiienko on 13.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "UIView+ScrollToTopDisabler.h"

@implementation UIView (ScrollToTopDisabler)

- (void)disableScrollToTopForSubviews
{
    for (UIScrollView *view in self.subviews )
    {
        if ([view isKindOfClass:[UIScrollView class]])
        {
            view.scrollsToTop = NO;
        }
    }
}

- (void)disableDeeplyScrollToTopForSubviews
{
    for (UIScrollView *view in self.subviews )
    {
        if ([view isKindOfClass:[UIScrollView class]])
        {
            view.scrollsToTop = NO;
        }
        [view disableDeeplyScrollToTopForSubviews];
    }
}
@end
