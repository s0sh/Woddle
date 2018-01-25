//
//  UIPlaceholderTextView.h
//  AnsaMessenger
//
//  Created by Petro Korenev on 8/26/13.
//  Copyright (c) 2013 IDS Outsource. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIPlaceholderTextView : UITextView
{
    UILabel *_placeholderLabel;
}

- (void)setupFrame;
- (UILabel*)placeholderLabel;

@property (nonatomic) BOOL caretHidden;

- (id)initWithFrame:(CGRect)frame delegate:(id)delegate;

@end
