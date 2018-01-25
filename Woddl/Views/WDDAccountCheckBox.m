//
//  WDDAccountCheckBox.m
//  Woddl
//
//  Created by Sergii Gordiienko on 30.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDAccountCheckBox.h"

static NSString * const kStateChecked = @"Sidebar_account_enabled";
static NSString * const kStateUnchecked = @"Sidebar_account_disabled";


@interface WDDAccountCheckBox()
@property (strong, nonatomic) UIImageView *stateImageView;
@end

@implementation WDDAccountCheckBox


#pragma mark - getters

- (UIImageView *)stateImageView
{
    if (!_stateImageView)
    {
        UIImage *stateImage = [UIImage imageNamed:kStateUnchecked];
        _stateImageView = [[UIImageView alloc] initWithImage:stateImage];
    }
    return _stateImageView;
}

#pragma mark - setters

- (void)setChecked:(BOOL)checked
{
    _checked = checked;
    [self changeImageForState:checked];
}

#pragma mark - logic methods

- (UIImage *)imageForState:(BOOL)checked
{
    UIImage *resultImage;
    if (checked)
    {
        resultImage = [UIImage imageNamed:kStateChecked];
    }
    else
    {
        resultImage = [UIImage imageNamed:kStateUnchecked];
    }
    return resultImage;
}

- (void)changeImageForState:(BOOL)checked
{
    [UIView animateWithDuration:0.2f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.stateImageView.image = [self imageForState:checked];
                     } completion:nil];
}

#pragma mark - init

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        [self setupImageView];
    }
    return self;
}

- (id)init
{
    if (self = [super init])
    {
        self.backgroundColor = [UIColor clearColor];
        [self setupImageView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        self.backgroundColor = [UIColor clearColor];
        [self setupImageView];
    }
    return self;
}

- (void)setupImageView
{
    CGRect frame = self.stateImageView.frame;
    CGRect selfFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, frame.size.width, frame.size.height);
    self.frame = selfFrame;
    [self addSubview:self.stateImageView];
}

#pragma mark - event actions on touch

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    self.checked = !self.isChecked;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
