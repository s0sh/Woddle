//
//  UIPlaceholderTextView.m
//  AnsaMessenger
//
//  Created by Petro Korenev on 8/26/13.
//  Copyright (c) 2013 IDS Outsource. All rights reserved.
//

#import "UIPlaceholderTextView.h"

@implementation UIPlaceholderTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self doCustomInitialization];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self doCustomInitialization];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame delegate:(id)delegate
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delegate = delegate;
        [self doCustomInitialization];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
}

- (void)doCustomInitialization
{
    _placeholderLabel = [[UILabel alloc] initWithFrame:self.frame];
    _placeholderLabel.backgroundColor = [UIColor clearColor];
    _placeholderLabel.textColor = [UIColor lightGrayColor];
//    _placeholderLabel.font = [UIFont helveticaNeueWithTypeface:kFontTypefaceLight size:kMessageInputFontSize];
    _placeholderLabel.userInteractionEnabled = NO;
    [self addSubview:_placeholderLabel];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(textChanged:)
               name:UITextViewTextDidChangeNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(textChanged:)
               name:UITextViewTextDidEndEditingNotification
             object:nil];
    
//    self.font = [UIFont helveticaNeueWithTypeface:kFontTypefaceLight size:kMessageInputFontSize];
}

- (void)setupFrame
{
    CGRect newTextViewFrame = self.frame;
    newTextViewFrame.size = self.contentSize;
    self.frame = newTextViewFrame;
    newTextViewFrame.origin = CGPointZero;
    _placeholderLabel.frame = newTextViewFrame;
    CGRect oldSuperviewFrame = self.superview.frame;
    oldSuperviewFrame.size.height = self.frame.size.height;
    self.superview.frame = oldSuperviewFrame;
}

- (UILabel*)placeholderLabel
{
    return _placeholderLabel;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    return self.caretHidden ? CGRectZero : [super caretRectForPosition:position];
}

- (void)updatePlaceHolderVisibility
{
    _placeholderLabel.hidden = (self.text.length != 0);
}

#pragma mark - Notifications

- (void)textChanged:(NSNotification *)note
{
    if( [note.object isEqual:self] )
    {
        [self updatePlaceHolderVisibility];
    }
}

#pragma mark - Setters/Getters implementation

- (void)setText:(NSString *)text
{
    [super setText:text];
    
    [self updatePlaceHolderVisibility];
}

@end
