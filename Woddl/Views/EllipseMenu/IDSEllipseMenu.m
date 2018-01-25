//
//  IDSElipseMenu.m
//  ElipseMenu
//
//  Created by Sergii Gordiienko on 13.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "IDSEllipseMenu.h"
#import "UIImage+Blur.h"

static NSInteger const kNumberOfItemsInSide = 6;
static CGFloat const kDefaultARadius = 120.0f;
static CGFloat const kDefaultBRadius = 180.0f;
static CGFloat const kImageSize = 54.0f;
static CGFloat const kFadeAlpha = 0.25f;

static CGFloat const kShowButtonsAnmationDuration = 0.45f;
static CGFloat const kFadeInAnmationDuration = 0.15f;
static CGFloat const kFadeOutAnmationDuration = 0.25f;

@interface IDSEllipseMenu()
@property (assign, nonatomic) CGPoint center;
@property (strong, nonatomic) UIView *baseView;
@end

@implementation IDSEllipseMenu

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.startPosition = [self center];
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideMenu)];
        self.gestureRecognizers = @[tapGesture];
        self.likeAvailable = YES;
    }
    return self;
}

#pragma mark - Getters

- (NSInteger)leftButtonsTagBase
{
    NSAssert(![self isKindOfClass:[IDSEllipseMenu class]], @"Should be overloaded in sub class");
    return  -1000;
}

- (CGFloat)aRadius
{
    if (!_aRadius)
    {
        _aRadius = kDefaultARadius;
    }
    return _aRadius;
}

- (CGFloat)bRadius
{
    if (!_bRadius)
    {
        if ([[UIScreen mainScreen] bounds].size.height <= 480.0)
        {
            _bRadius = kDefaultBRadius * 0.8; // Scale for 3,5" display
        }
        else
        {
            _bRadius = kDefaultBRadius;
        }
    }
    return _bRadius;
}

#pragma mark - Public methods

- (void)showMenuForView:(UIView *)view
{
    [Heatmaps trackScreenWithKey:@"503395516a70d21a-545238e5"];
    
    //  There are no share options in Instagram SN
    //
    [self hideRighMenuIconsWithTag:kSocialNetworkInstagram|kSocialNetworkFoursquare|kSocialNetworkGooglePlus];
    
    self.baseView = view;
    
#ifdef SHOULD_FADE
    [self addFadeBackground];
#else
    [self addBlurBackground];
#endif

#if DEBUG
    DLog(@"Blur added");
#endif
    [self drawElipseWithButtons];
    
#if DEBUG
    DLog(@"Showed menu");
#endif

}

- (void)hideMenu
{
#if DEBUG
    DLog(@"Hidden!");
#endif
    
    [self fadeOutWithView:self completion:^(BOOL finished) {
        if ([self.delegate respondsToSelector:@selector(didHideMenu)])
        {
            [self.delegate didHideMenu];
        }
        [self removeFromSuperview];
    }];
}

#pragma mark - Logic

- (void)drawElipseWithButtons
{
    [self setupLeftSideButtons];
    [self setupRightSideButtons];
}

- (void)setupLeftSideButtons
{
    NSArray *leftSideButtonsImageNames = [self leftSideButtonsImageNames];
    
    NSInteger numberOfItemsInSide = (leftSideButtonsImageNames.count > kNumberOfItemsInSide ? leftSideButtonsImageNames.count : kNumberOfItemsInSide);
    
    float offsetInButtonSize = 1.0f;
    if (leftSideButtonsImageNames.count > 6)
    {
        offsetInButtonSize = 0.3f;
    }
    
    float angleStep = M_PI/(numberOfItemsInSide+offsetInButtonSize);   //  adding one for offset first button
    float startAngle = -M_PI_2;
    
    for (NSInteger i = 0 ; i < leftSideButtonsImageNames.count; i++)
    {
        float mod = 1.f;    // all connected to mod - hack to show 8 buttons.
        if (leftSideButtonsImageNames.count > 7)
        {
            mod = (float)(abs(leftSideButtonsImageNames.count / 2.f - i) - 2.f);
            mod /= leftSideButtonsImageNames.count / 2 > i ? 40.f : 150.f;
            mod += i ? 1 : 0.6;
            mod += (i > 0 && i < leftSideButtonsImageNames.count / 2.f) ? .07 : 0;
            mod += i == leftSideButtonsImageNames.count / 2 ? 0.030 : 0;
        }
        
        float angle = startAngle - angleStep * (i+offsetInButtonSize) * mod;    //  adding one for offset first button
        CGPoint position = [self calculatePostionForAngle:angle];
        
        UIButton *button = [self createButtonWithIndex:i
                                       usingImageNames:[self leftSideButtonsImageNames]];
        
        button.tag = [self tagForImageName:leftSideButtonsImageNames[i]];
        if (button)
        {
            [self addSubview:button];
            [UIView animateWithDuration:kShowButtonsAnmationDuration animations:^{
                button.center = position;
                [self addShadowToView:button];
            }];
        }
    }
}

- (void)setupRightSideButtons
{
    float angleStep = M_PI/(kNumberOfItemsInSide+1);
    float startAngle = M_PI_2;
    
    NSArray *rightSideButtonsImageNames = [self rightSideButtonsImageNames];
    for (NSInteger i = 0 ; i < rightSideButtonsImageNames.count; i++)
    {
        float angle = startAngle - angleStep * (i+1);    //  adding one for offset first button
        CGPoint position = [self calculatePostionForAngle:angle];
        
        UIButton *button = [self createButtonWithIndex:i
                                       usingImageNames:rightSideButtonsImageNames];
        
        button.tag = [self tagForImageName:rightSideButtonsImageNames[i]];
        if (button)
        {
            [self addSubview:button];
            [UIView animateWithDuration:kShowButtonsAnmationDuration animations:^{
                button.center = position;
                [self addShadowToView:button];
            }];
        }
    }
}

- (UIButton *)createButtonWithIndex:(NSInteger)index
                    usingImageNames:(NSArray *)imageNames
{
    UIButton *newButton;
    if (index < imageNames.count)
    {
        newButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kImageSize, kImageSize)];
        newButton.center = self.startPosition;
        [newButton setBackgroundImage:[UIImage imageNamed:imageNames[index]]
                             forState:UIControlStateNormal];
        [newButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return newButton;
}

- (CGPoint)calculatePostionForAngle:(float)angle
{
    CGFloat xPos = self.aRadius * cosf(angle);
    CGFloat yPos = self.bRadius * sinf(angle);
    
    CGPoint position = CGPointMake([self center].x + xPos, [self center].y + yPos);
    return position;
}


- (NSArray *)leftSideButtonsImageNames
{
    NSAssert(![self isKindOfClass:[IDSEllipseMenu class]], @"Should be overloaded in sub class");
    
    return @[];
}

- (NSArray *)rightSideButtonsImageNames
{
    NSMutableArray *rightImageNames = [[NSMutableArray alloc] init];
    
    if (self.availableSocialNetworks & kSocialNetworkFacebook)
    {
        [rightImageNames addObject:[self imageNameForTag:kSocialNetworkFacebook]];
    }
    
    if (self.availableSocialNetworks & kSocialNetworkTwitter)
    {
        [rightImageNames addObject:[self imageNameForTag:kSocialNetworkTwitter]];
    }
    
    if (self.availableSocialNetworks & kSocialNetworkGooglePlus)
    {
        [rightImageNames addObject:[self imageNameForTag:kSocialNetworkGooglePlus]];
    }
    
    if (self.availableSocialNetworks & kSocialNetworkFoursquare)
    {
        [rightImageNames addObject:[self imageNameForTag:kSocialNetworkFoursquare]];
    }
    
    if (self.availableSocialNetworks & kSocialNetworkInstagram)
    {
        [rightImageNames addObject:[self imageNameForTag:kSocialNetworkInstagram]];
    }
    
    if (self.availableSocialNetworks & kSocialNetworkLinkedIN)
    {
        [rightImageNames addObject:[self imageNameForTag:kSocialNetworkLinkedIN]];
    }
    
    return [rightImageNames copy];
}

#pragma mark - Appearance methods

- (void) addBlurBackground
{
    CGSize size = self.frame.size;
    
    if (CGRectIsEmpty(self.clearAreaRect))
    {
        UIImage *fullBlurBackgroundImage = [UIImage blurredImageForView:self.baseView];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:fullBlurBackgroundImage];
        imageView.frame = (CGRect){CGPointZero, size};
        [self fadeInWithView:imageView];
    }
    else
    {
        CGSize superViewSize = self.baseView.frame.size;
        CGRect topRect = CGRectMake(0, 0, size.width, self.clearAreaRect.origin.y);
        CGRect bottomRect = CGRectMake(0, CGRectGetMaxY(self.clearAreaRect), superViewSize.width, superViewSize.height- CGRectGetMaxY(self.clearAreaRect));
        
        UIImage *fullScreenImage = [UIImage imageWithView:self.superview];
        UIImage *fullImage = [fullScreenImage cropImageWithRect:scaleFrame(self.baseView.frame)];

        UIImage *fullBlurBackgroundImage = [UIImage blurredImageWithImage:fullImage];
        UIImage *topImage = [fullBlurBackgroundImage cropImageWithRect:scaleFrame(topRect)];
        UIImage *bottomImage = [fullBlurBackgroundImage cropImageWithRect:scaleFrame(bottomRect)];
        
        UIImageView *fullImageView = [[UIImageView alloc] initWithImage:fullImage];
        fullImageView.frame = (CGRect){CGPointZero, self.baseView.frame.size};
        UIImageView *topImageView = [[UIImageView alloc] initWithImage:topImage];
        topImageView.frame = topRect;
        UIImageView *bottomImageView = [[UIImageView alloc] initWithImage:bottomImage];
        bottomImageView.frame = bottomRect;
        
        [fullImageView setUserInteractionEnabled:YES];
        [topImageView setUserInteractionEnabled:YES];
        [bottomImageView setUserInteractionEnabled:YES];
        
        [self addSubview:fullImageView];
        [self fadeInWithView:topImageView];
        [self fadeInWithView:bottomImageView];
    }
}

- (void) addFadeBackground
{
    CGSize size = self.frame.size;
    
    if (CGRectIsEmpty(self.clearAreaRect))
    {
        UIView *fadeBackgroundView = [[UIView alloc] initWithFrame:self.baseView.bounds];
        fadeBackgroundView.backgroundColor = [UIColor blackColor];
        
        fadeBackgroundView.alpha = 0.0f;
        [self fadeInWithView:fadeBackgroundView maxAlpha:kFadeAlpha];
    }
    else
    {
        CGSize superViewSize = self.baseView.frame.size;
        CGRect topRect = CGRectMake(0, 0, size.width, self.clearAreaRect.origin.y);
        CGRect bottomRect = CGRectMake(0, CGRectGetMaxY(self.clearAreaRect), superViewSize.width, superViewSize.height- CGRectGetMaxY(self.clearAreaRect));
        
        UIImage *fullScreenImage = [UIImage imageWithView:self.superview];
        UIImage *fullImage = [fullScreenImage cropImageWithRect:scaleFrame(self.baseView.frame)];
        
        UIImageView *fullImageView = [[UIImageView alloc] initWithImage:fullImage];
        fullImageView.frame = (CGRect){CGPointZero, self.baseView.frame.size};

        UIView *topView = [[UIView alloc] initWithFrame:topRect];
        UIView *bottomView = [[UIView alloc] initWithFrame:bottomRect];
        topView.backgroundColor = bottomView.backgroundColor = [UIColor blackColor];
        
        [self addSubview:fullImageView];
        [self fadeInWithView:topView maxAlpha:kFadeAlpha];
        [self fadeInWithView:bottomView maxAlpha:kFadeAlpha];
    }
}

static CGRect scaleFrame(CGRect frame)
{
    static CGFloat scaleFactor = -1.f;
    
    if (scaleFactor < 0.f)
    {
        scaleFactor = [UIScreen mainScreen].scale;
    }
    
    frame.origin = CGPointMake(CGRectGetMinX(frame) * scaleFactor, CGRectGetMinY(frame) * scaleFactor);
    frame.size = CGSizeMake(CGRectGetWidth(frame) * scaleFactor, CGRectGetHeight(frame) * scaleFactor);
    
    return frame;
}

- (void)fadeInWithView:(UIView *)view
{
    [self fadeInWithView:view maxAlpha:1.0f];
}

- (void)fadeInWithView:(UIView *)view maxAlpha:(CGFloat)alpha
{
    view.alpha = 0.0f;
    [self addSubview:view];
    [UIView animateWithDuration:kFadeInAnmationDuration animations:^{
        view.alpha = alpha;
    }];
}

- (void)fadeOutWithView:(UIView *)view completion:(void (^)(BOOL finished))completion
{
    [UIView animateWithDuration:kFadeOutAnmationDuration
                     animations:^{
        view.alpha = 0.0f;
    }
                     completion:completion];
}

- (void)addShadowToView:(UIView *)view
{
    view.layer.masksToBounds = NO;
    view.layer.shadowOffset = CGSizeMake(0, 5);
    view.layer.shadowRadius = 3;
    view.layer.shadowOpacity = 0.5;
}

#pragma mark - Actions

- (void)buttonPressed:(UIButton *)sender
{
    DLog(@"Tag: %d", sender.tag);
    if ([self.delegate respondsToSelector:@selector(didPressedButtonWithTag:inMenu:)])
    {
        [self.delegate didPressedButtonWithTag:sender.tag
                                        inMenu:self];
    }
}

#pragma mark - Help methods

- (CGPoint)center
{
    return CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
}

- (void)hideRighMenuIconsWithTag:(NSInteger)tag
{
    NSInteger reversedTag = ~tag;
    self.availableSocialNetworks = self.availableSocialNetworks & reversedTag;
}

- (NSString *)imageNameForTag:(SocialNetworkType)imageTag
{
    NSString *imageName;
    
    switch (imageTag) {
        case kSocialNetworkFacebook:
            return kFacebookButtonImageName;
            break;
        case kSocialNetworkFoursquare:
            return kFoursquareButtonImageName;
            break;
        case kSocialNetworkGooglePlus:
            return kGooglePlusButtonImageName;
            break;
        case kSocialNetworkInstagram:
            return kInstagramButtonImageName;
            break;
        case kSocialNetworkLinkedIN:
            return kLinkedInButtonImageName;
            break;
        case kSocialNetworkTwitter:
            return kTwitterButtonImageName;
            break;
        case kSocialNetworkUnknown:
            return nil;
            break;
    }
    
    return imageName;
}


- (NSInteger)tagForImageName:(NSString *)imageName
{
    SocialNetworkType tag = kSocialNetworkUnknown;
    
    if ([imageName isEqualToString:kFacebookButtonImageName])
    {
        tag = kSocialNetworkFacebook;
    }
    else if ([imageName isEqualToString:kTwitterButtonImageName])
    {
        tag = kSocialNetworkTwitter;
    }
    else if ([imageName isEqualToString:kGooglePlusButtonImageName])
    {
        tag = kSocialNetworkGooglePlus;
    }
    else if ([imageName isEqualToString:kFoursquareButtonImageName])
    {
        tag = kSocialNetworkFoursquare;
    }
    else if ([imageName isEqualToString:kInstagramButtonImageName])
    {
        tag = kSocialNetworkInstagram;
    }
    else if ([imageName isEqualToString:kLinkedInButtonImageName])
    {
        tag = kSocialNetworkLinkedIN;
    }
    
    return tag;
}

@end
