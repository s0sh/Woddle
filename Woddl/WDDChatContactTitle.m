//
//  WDDChatContactTitle.m
//  Woddl
//
//  Created by Oleg Komaristov on 30.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDChatContactTitle.h"

#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/SDWebImageManager.h>
#import "UIImage+ResizeAdditions.h"

static const CGFloat defaultMaxNameLength = 120.f;
static const CGFloat avatarMaskSize = 44.f;
static const CGFloat contactsAvatarSize = 44.f;
static const CGFloat webViewAvatarSize = 22.f;
static const CGFloat contactsAvatarToNameOffset = 8.f;
static const CGFloat webViewAvatarToNameOffset = -5.f;
static const CGFloat contactInfoHeight = 45.f;
static const CGFloat avatatLeftSideOffset = 4.0f;

@interface WDDChatContactTitle ()

@property (nonatomic, strong) NSLayoutConstraint *avatarMaskHeight;
@property (nonatomic, strong) NSLayoutConstraint *avatarMaskWidth;

@property (nonatomic, strong) NSLayoutConstraint *avatarHeight;
@property (nonatomic, strong) NSLayoutConstraint *avatarWidth;

@property (nonatomic, strong) NSLayoutConstraint *avatarToTextOffset;

//@property (nonatomic, strong) NSLayoutConstraint *selfHeight;

@end

@implementation WDDChatContactTitle

- (id)initWithAvatar:(id)avatar name:(NSString *)name style:(TitleStyle)style;
{
    CGFloat avatarToNameOffset = (style == FacebookTitleStyle ? contactsAvatarToNameOffset : webViewAvatarToNameOffset);
    
    return [self initWithAvatar:avatar name:name maximumWidth:(defaultMaxNameLength + avatarMaskSize + avatarToNameOffset) style:style];
}

- (id)initWithAvatar:(id)avatar name:(NSString *)name maximumWidth:(CGFloat)maximumWidth style:(TitleStyle)style;
{
    self.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    
    UIFont *nameLableFont = [UIFont boldSystemFontOfSize:16.f];
    CGSize nameSize = [self sizeForText:name withFont:nameLableFont];
    CGFloat avatarSize = (style == FacebookTitleStyle ? contactsAvatarSize : webViewAvatarSize);
    CGFloat avatarToNameOffset = (style == FacebookTitleStyle ? contactsAvatarToNameOffset : webViewAvatarToNameOffset);
    
    CGFloat maxNameLength = maximumWidth - avatarSize - avatarToNameOffset;
    CGRect selfFrame = (CGRect){CGPointZero, CGSizeMake(avatarMaskSize + avatarToNameOffset + MIN(nameSize.width, maxNameLength), contactInfoHeight)};
    
    self = [super initWithFrame:selfFrame];
    if (self)
    {
        UIImageView *contactAvatareVeiw = [[UIImageView alloc] initWithFrame:CGRectMake(avatatLeftSideOffset + (avatarMaskSize - avatarSize) / 2.f, (avatarMaskSize - avatarSize) / 2.f,
                                                                                        avatarSize, avatarSize)];
        CGRect maskFrame = CGRectZero;
        UIImageView *avatarMask = [[UIImageView alloc] initWithFrame:maskFrame];
        avatarMask.contentMode = UIViewContentModeScaleAspectFit;
        
        NSString *maskImageName;
        if (style == FacebookTitleStyle)
        {
            maskImageName = kContactsSectionAvatarMask;
        }
        else
        {
            maskImageName =  kWebViewTitleAvatarMask;
        }
        
        avatarMask.image = [UIImage imageNamed:maskImageName];
        avatarMask.backgroundColor = [UIColor clearColor];
        
        contactAvatareVeiw.contentMode = UIViewContentModeScaleToFill;
        if ([avatar isKindOfClass:[UIImage class]])
        {
            contactAvatareVeiw.image = avatar;
        }
        else if ([avatar isKindOfClass:[NSURL class]])
        {
            contactAvatareVeiw.image = [UIImage imageNamed:kAvatarPlaceholderImageName];
            
            __weak UIImageView *weakAvatarView = contactAvatareVeiw;
            static const NSInteger tagLoadingIndicator = 1024;
            
            UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            activityIndicator.tag = tagLoadingIndicator;
            activityIndicator.center = CGPointMake(CGRectGetWidth(contactAvatareVeiw.frame) / 2.f,
                                                   CGRectGetHeight(contactAvatareVeiw.frame) / 2.f);
            [activityIndicator startAnimating];
            [contactAvatareVeiw addSubview:activityIndicator];
            
            [[SDWebImageManager sharedManager] downloadWithURL:avatar
                                                       options:SDWebImageRetryFailed
                                                      progress:nil
                                                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                                         
                                                         if (finished && !error)
                                                         {
                                                             [[weakAvatarView viewWithTag:tagLoadingIndicator] removeFromSuperview];
                                                             CGFloat width = avatarSize * [UIScreen mainScreen].scale;
                                                             
                                                             image = [image thumbnailImage:width
                                                                         transparentBorder:1.f
                                                                              cornerRadius:3.f
                                                                      interpolationQuality:kCGInterpolationMedium];
                                                             
                                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                                 weakAvatarView.image = image;
                                                             });
                                                         }
                                                     }];
        }
        
        UILabel *contactLabelView = [[UILabel alloc] initWithFrame:CGRectMake(/*avatarMaskSize + avatarToNameOffset*/0.f, 0.f, MIN(nameSize.width, maxNameLength), contactInfoHeight)];
        contactLabelView.font = nameLableFont;
        contactLabelView.backgroundColor = [UIColor clearColor];
        if (style == FacebookTitleStyle)
        {
            contactLabelView.textColor = [UIColor whiteColor];
        }
        else
        {
            contactLabelView.textColor = [UIColor blackColor];
        }
        contactLabelView.text = name;
        
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:contactAvatareVeiw];
        [self addSubview:avatarMask];
        [self addSubview:contactLabelView];
        
        [contactLabelView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [avatarMask setTranslatesAutoresizingMaskIntoConstraints:NO];

        NSLayoutConstraint *maskLeftLayout = [NSLayoutConstraint constraintWithItem:avatarMask
                                                                          attribute:NSLayoutAttributeLeft
                                                                          relatedBy:NSLayoutRelationEqual
                                                                             toItem:self
                                                                          attribute:NSLayoutAttributeLeft
                                                                         multiplier:1.f
                                                                           constant:0];

        self.avatarToTextOffset = [NSLayoutConstraint constraintWithItem:contactLabelView
                                                               attribute:NSLayoutAttributeLeft
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:avatarMask
                                                               attribute:NSLayoutAttributeRight
                                                              multiplier:1.f
                                                                constant:avatarToNameOffset];
        
        NSLayoutConstraint *maskCenterLayout = [NSLayoutConstraint constraintWithItem:avatarMask
                                                                            attribute:NSLayoutAttributeCenterY
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:self
                                                                            attribute:NSLayoutAttributeCenterY
                                                                           multiplier:1.f
                                                                             constant:0];
        
        NSLayoutConstraint *avatarCenterLayout = [NSLayoutConstraint constraintWithItem:contactAvatareVeiw
                                                                              attribute:NSLayoutAttributeCenterY
                                                                              relatedBy:NSLayoutRelationEqual
                                                                                 toItem:self
                                                                              attribute:NSLayoutAttributeCenterY
                                                                             multiplier:1.f
                                                                               constant:0.f];
        NSLayoutConstraint *avatarHorizontalLayout = [NSLayoutConstraint constraintWithItem:contactAvatareVeiw
                                                                                  attribute:NSLayoutAttributeCenterX
                                                                                  relatedBy:NSLayoutRelationEqual
                                                                                     toItem:avatarMask
                                                                                  attribute:NSLayoutAttributeCenterX
                                                                                 multiplier:1.f
                                                                                   constant:0.f];
        [self addConstraints:@[maskLeftLayout, self.avatarToTextOffset, maskCenterLayout, maskCenterLayout, avatarCenterLayout, avatarHorizontalLayout]];
        
        self.avatarMaskWidth = [NSLayoutConstraint constraintWithItem:avatarMask
                                                            attribute:NSLayoutAttributeWidth
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:nil
                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                           multiplier:1
                                                             constant:avatarMaskSize];
        self.avatarMaskHeight = [NSLayoutConstraint constraintWithItem:avatarMask
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeNotAnAttribute
                                                            multiplier:1
                                                              constant:avatarMaskSize];
        [avatarMask addConstraints:@[self.avatarMaskWidth, self.avatarMaskHeight]];
        
        [contactAvatareVeiw setTranslatesAutoresizingMaskIntoConstraints:NO];
        self.avatarWidth = [NSLayoutConstraint constraintWithItem:contactAvatareVeiw
                                                        attribute:NSLayoutAttributeWidth
                                                        relatedBy:NSLayoutRelationEqual
                                                           toItem:nil
                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                       multiplier:1
                                                         constant:avatarSize];
        self.avatarHeight = [NSLayoutConstraint constraintWithItem:contactAvatareVeiw
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:nil
                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                        multiplier:1
                                                          constant:avatarSize];
        
        [contactAvatareVeiw addConstraints:@[self.avatarHeight, self.avatarWidth]];
        
        if (style == WebViewTitleStyle)
        {
            [self didRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
        }
    }
    
    return self;
}

- (void)didRotateToInterfaceOrientation:(UIInterfaceOrientation)uiOrientation
{
    CGFloat navigationBarSize = (UIDeviceOrientationIsPortrait(uiOrientation) ? 44.f : 32.f);
    CGFloat avatarSize = (UIDeviceOrientationIsPortrait(uiOrientation) ? 32.f : 17.f);
    
    self.avatarMaskHeight.constant = navigationBarSize;
    self.avatarMaskWidth.constant = navigationBarSize;
    self.avatarWidth.constant = avatarSize;
    self.avatarHeight.constant = avatarSize;
    
    self.avatarToTextOffset.constant = (UIDeviceOrientationIsPortrait(uiOrientation) ? webViewAvatarToNameOffset : 0);
    
    [(UIImageView *)self.avatarMaskHeight.firstItem setImage:[UIImage imageNamed:(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? kWebViewTitleAvatarMask : [kWebViewTitleAvatarMask stringByAppendingString:@"~Landsacepe"])]];
}

#pragma mark - Utility methods

- (CGSize)sizeForText:(id)text withFont:(UIFont *)font
{
    CGSize textSize;
    if (!IS_IOS7)
    {
        NSString *textString = [text isKindOfClass:[NSAttributedString class]] ? [text string] : text;
        
        textSize = [textString sizeWithFont:font];
    }
    else
    {
        if ([text isKindOfClass:[NSAttributedString class]])
        {
            textSize = [(NSAttributedString *)text boundingRectWithSize:CGSizeMake(INFINITY, 20.f)
                                                                options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                                context:nil].size;
        }
        else
        {
            textSize = [(NSString *)text boundingRectWithSize:CGSizeMake(INFINITY, 20.f)
                                                      options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:@{UITextAttributeFont : font}
                                                      context:nil].size;
        }
    }
    
    return textSize;
}

@end
