//
//  UITextView+fixScrollForIOS7.h
//  Woddl
//
//  Created by Sergii Gordiienko on 30.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextView (fixScrollForIOS7)
- (void)fixSrollingToLastLineBugInIOS7withText:(NSString *)text;
@end
