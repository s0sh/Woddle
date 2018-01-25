//
//  UITextView+fixScrollForIOS7.m
//  Woddl
//
//  Created by Sergii Gordiienko on 30.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "UITextView+fixScrollForIOS7.h"

@implementation UITextView (fixScrollForIOS7)

- (void)fixSrollingToLastLineBugInIOS7withText:(NSString *)text
{
    
    CGRect textRect = [self.layoutManager usedRectForTextContainer:self.textContainer];
    CGFloat sizeAdjustment = self.font.lineHeight * [UIScreen mainScreen].scale;
    
    if (textRect.size.height >= self.frame.size.height - self.contentInset.bottom - sizeAdjustment)
    {
        if ([text isEqualToString:@"\n"])
        {
            [UIView animateWithDuration:0.2 animations:^{
                [self setContentOffset:CGPointMake(self.contentOffset.x, self.contentOffset.y + sizeAdjustment)];
            }];
        }
    }
}

@end
