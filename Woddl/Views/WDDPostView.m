//
//  WDDPostView.m
//  Woddl
//
//  Created by Sergii Gordiienko on 27.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDPostView.h"

#import <OHAttributedLabel/OHAttributedLabel.h>
#import <SDWebImage/SDWebImageManager.h>
#import "UIImage+ResizeAdditions.h"
#import "UIImageView+WebCache.h"
#import "NSDate+TimeAgo.h"
#import "UITapGestureRecognizer+MediaInfo.h"

#import "Post.h"
#import "TwitterPost.h"
#import "Tag.h"
#import "Media.h"
#import "UserProfile.h"
#import "Group.h"
#import "Link+Additions.h"

#import "WDDPreviewManager.h"
#import "WDDURLShorter.h"
#import "WDDDataBase.h"

#define bgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)

static const CGFloat kAvatarCornerRadious = 2.0f;
static const CGFloat LikesAndCommentsIconWidth = 17.f;
static const CGFloat LikesAndCommentsLabelWidth = 26.f;
static const CGFloat LikesAndCommentsLeftOffset = 2.f;

static const CGFloat AuthorNameRightOffset = 32.f;

static const CGFloat ExpandedMediaSize = 120.f;
static const CGFloat MediaTriangleHeight = 10.0f;
static const CGFloat OffsetY = 8.0f;
static const CGFloat MessageMinY = 51.f;
static const CGFloat MessageWidth = 300.f;
static const CGFloat ShowEventButtonHeight = 38.0f;

static const CGFloat MaximumExpandSize = 240.f;

static const NSInteger kMediaTypeLink = 254;

@implementation WDDPostView

- (void)awakeFromNib
{
    self.mediaScrollHeight.constant = 0.0f;
    self.mediaScrollBottomOffset.constant = 0.0f;
    
    self.textMessage.automaticallyAddLinksForType = 0;
    self.likesIconWidth.constant = LikesAndCommentsIconWidth;
    self.likesLabelWidth.constant = LikesAndCommentsLabelWidth;
    self.commentIconWidth.constant = LikesAndCommentsIconWidth;
    self.commentsLabelWidth.constant = LikesAndCommentsLabelWidth;
    self.commentsIconOffset.constant = LikesAndCommentsLeftOffset;
}

#pragma mark - Setters

- (void)setPost:(Post *)post
{
    _post = post;
    
    if (!post)
    {
        return ;
    }
    
    [self getAllLinks];
    [self updateViewContent];
}

-(void)getAllLinks
{
    OHAttributedLabel* textMessage = [[OHAttributedLabel alloc] init];
    textMessage.text = self.post.text;
    self.links = nil;
}

- (void)updateViewContent
{
    [self setupHeight];
    
    [self setupMessageTextLabel];
    [self setupAvatarImageView];
    [self setupAuthorNameLabel];
    [self setupTimeAgoLabel];
    [self setupSocialNetworkIcon];
    [self setupLikesAndComments];
    [self setupRetweetIcon];
    [self setupMediaScrollView];
    
    [self setupShowProfileTapForView:self.avatarImageView];
    [self setupShowProfileTapForView:self.authorNameLabel];
    
    [self setupShowEventButton];
}

- (void)setupShowEventButton
{
    if ([self.post.type  isEqual: @(kPostTypeEvent)])
    {
        self.showEventButton.hidden = NO;
        [self.showEventButton setTitle:NSLocalizedString(@"lskShowEventButtonTitle", @"Show event details") forState:UIControlStateNormal];
        self.mediaScrollBottomOffset.constant = 0.0f;
        self.showEventInfoButtonHeight.constant = ShowEventButtonHeight;
    }
    else
    {
        self.showEventInfoButtonHeight.constant = 0.0f;
    }
}

- (void)setupShowProfileTapForView:(UIView *)view
{
    [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAuthorProfile)]];
    [view setUserInteractionEnabled:YES];
}

#pragma mark - Avatar setup

- (void)setupAvatarImageView
{
    CGFloat width = self.avatarImageView.frame.size.width*2;
    UIImage *placeHolderImage = [[UIImage imageNamed:kAvatarPlaceholderImageName] thumbnailImage:width
                                                                               transparentBorder:1.0f
                                                                                    cornerRadius:kAvatarCornerRadious
                                                                            interpolationQuality:kCGInterpolationDefault];
    NSURL *avatarURL = [NSURL URLWithString:self.post.author.avatarRemoteURL];
    
    SDWebImageCompletedBlock completion = ^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (!error)
        {
            image = [image thumbnailImage:width
                        transparentBorder:1.0f
                             cornerRadius:kAvatarCornerRadious
                     interpolationQuality:kCGInterpolationMedium];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.avatarImageView.image = image;
            });
        }
    };
    
    [self.avatarImageView setImageWithURL:avatarURL
                         placeholderImage:placeHolderImage
                                  options:SDWebImageRefreshCached
                                completed:completion];
    
    self.avatarImageView.layer.masksToBounds = YES;
    [self.avatarImageView.layer setCornerRadius:kAvatarCornerRadious];
}

#pragma mark - Author and time ago label, Social network icon

- (void)setupAuthorNameLabel
{
    self.authorNameLabel.text = self.post.author.name;
}

- (void)setupTimeAgoLabel
{
    self.timeAgoLabel.text = [self.post.time timeAgo];
}

- (void)setupSocialNetworkIcon
{
    self.socialNetworkIcon.image = [UIImage imageNamed:self.post.socialNetworkIconName];
}

#pragma mark - Likes and comments icon with labels

- (void)setupRetweetIcon
{
    NSNumber *numberOfRetweets = nil;
    if ([self.post respondsToSelector:@selector(retweetsCount)])
    {
        numberOfRetweets = [self.post performSelector:@selector(retweetsCount)];
    }
    [self setNumberOfRetweets:numberOfRetweets];
}

- (void)setupLikesAndComments
{
    [self setNumberOfComments:(self.post.isCommentable ? self.post.commentsCount : nil)];
    [self setNumberOfLikes:(self.post.isLikable ? self.post.likesCount : nil)];
    
    if (fabs([self.post.updateTime timeIntervalSinceDate:[NSDate date]]) > 900.f)
    {
        __weak WDDPostView *w_self = self;
        [self.post refreshLikesAndCommentsCountWithComplitionBlock:^(BOOL success) {
            
            [w_self setNumberOfComments:(w_self.post.isCommentable ? w_self.post.commentsCount : nil)];
            [w_self setNumberOfLikes:(w_self.post.isLikable ? w_self.post.likesCount : nil)];
        }];
    }

}

- (void)setNumberOfComments:(NSNumber *)commentsCount
{
    if (commentsCount)
    {
        dispatch_async(bgQueue, ^{
            UIImage* commentIconImage = [UIImage imageNamed:[self.post socialNetworkCommentsIconName]];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.commentsIconImageView.image = commentIconImage;
            });
        });
        
        self.commentsCountLabel.text = (commentsCount.integerValue > 99 ? @"99+" : commentsCount.stringValue);
    }
    else
    {
        self.commentsIconImageView.hidden = YES;
        self.commentsCountLabel.hidden = YES;
        self.commentIconWidth.constant = 0.f;
        self.commentsLabelWidth.constant = 0.f;
        self.commentsIconOffset.constant = 0.f;
    }
}

- (void)setNumberOfLikes:(NSNumber *)likesCount
{
    if (likesCount)
    {
        dispatch_async(bgQueue, ^{
            UIImage* likesIconImage = [UIImage imageNamed:[self.post socialNetworkLikesIconName]];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.likesIconImageView.image = likesIconImage;
            });
        });
        
        NSString *likesText = nil;
        if (likesCount.integerValue > 99)
        {
            likesText = @"99+";
        }
        else if (likesCount.integerValue < -99)
        {
            likesText = @"-99";
        }
        else
        {
            likesText = likesCount.stringValue;
        }
        
        self.likesCountLabel.text = likesText;
    }
    else
    {
        self.likesIconImageView.hidden = YES;
        self.likesCountLabel.hidden = YES;
        self.likesIconWidth.constant = 0.f;
        self.likesLabelWidth.constant = 0.f;
        //self.likesIconOffset.constant = 0.f;
    }
}

- (void)setNumberOfRetweets:(NSNumber *)retweetsCount
{
    if (retweetsCount)
    {
        self.retweetsCountLabel.text = (retweetsCount.integerValue > 99 ? @"99+" : retweetsCount.stringValue);
    }
    else
    {
        self.retweetsIcon.hidden = YES;
        self.retweetsCountLabel.hidden = YES;
        self.authorNameRightOffset.constant = 10.f;
    }
}

#pragma mark - Setup Media
- (void)setupMediaScrollView
{
    if (!([self.post.media count] || self.links.count))
    {
        self.mediaScrollHeight.constant = 0.0f;
        self.mediaScrollBottomOffset.constant = 0.0f;
        self.mediaTriangleHeight.constant = 0.0f;
        return ;
    }
    
    self.mediaScrollHeight.constant = ExpandedMediaSize;
    self.mediaTriangleHeight.constant = MediaTriangleHeight;
    
    self.mediaScrollBottomOffset.constant = OffsetY;
    self.mediaScrollView.scrollsToTop = NO;
    [self setMediasList];
}


- (void)setMediasList
{
    __block CGFloat positionX = 0.f;
    NSInteger tagActivityIdicator = 1024;
    NSInteger tagPlayIcon = 1025;
    
    CGFloat imageWidth = CGRectGetWidth([UIScreen mainScreen].bounds) / (self.post.media.count + self.links.count > 1 ? 2 : 1);
    
    for (Media *mediaObj in self.post.media)
    {
        if (mediaObj.type.intValue == kMediaPhoto || mediaObj.type.intValue == kMediaVideo)
        {
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(positionX, 0.f, imageWidth, ExpandedMediaSize)];
            
            imageView.backgroundColor = [UIColor blackColor];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.clipsToBounds = YES;
            
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFullMedia:)];
            tapRecognizer.mediaType = mediaObj.type;
            tapRecognizer.mediaURL = [NSURL URLWithString:mediaObj.mediaURLString];
            tapRecognizer.previewURL = [NSURL URLWithString:mediaObj.previewURLString];
            
            [imageView addGestureRecognizer:tapRecognizer];
            imageView.userInteractionEnabled = YES;
            
            UIActivityIndicatorView *activityIndication = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
            activityIndication.center = CGPointMake(CGRectGetWidth(imageView.frame) / 2.f, CGRectGetHeight(imageView.frame) / 2.f);
            activityIndication.tag = tagActivityIdicator;
            [activityIndication startAnimating];
            [imageView addSubview:activityIndication];
            
            if (mediaObj.type.integerValue == kMediaVideo)
            {
                UIImageView *playIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PlayIcon"]];
                playIcon.center = CGPointMake(CGRectGetWidth(imageView.frame) / 2.f , CGRectGetHeight(imageView.frame) / 2.f);
                playIcon.tag = tagPlayIcon;
                playIcon.hidden = YES;
                [imageView addSubview:playIcon];
            }
            
            [self.mediaScrollView addSubview:imageView];
            
            NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:imageView
                                                                               attribute:NSLayoutAttributeWidth
                                                                               relatedBy:NSLayoutRelationEqual
                                                                                  toItem:nil
                                                                               attribute:NSLayoutAttributeNotAnAttribute
                                                                              multiplier:1
                                                                                constant:imageWidth];
            
            [imageView addConstraint:widthConstraint];
            
            positionX += CGRectGetWidth(imageView.frame);
            
            __weak UIImageView *wImageView = imageView;
            __weak Media *wMediaObject = mediaObj;
            
            [[SDWebImageManager sharedManager] downloadWithURL:[NSURL URLWithString:mediaObj.previewURLString ? mediaObj.previewURLString : mediaObj.mediaURLString]
                                                       options:SDWebImageLowPriority | SDWebImageRetryFailed
                                                      progress:nil
                                                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                                         
                                                         if (finished)
                                                         {
                                                             [[wImageView viewWithTag:tagActivityIdicator] removeFromSuperview];
                                                             
                                                             if (!error)
                                                             {
                                                                 wImageView.image = image;
                                                             }
                                                             
                                                             if ([wMediaObject.type isEqual:@(kMediaPhoto)])
                                                             {
                                                                 [[SDWebImageManager sharedManager] downloadWithURL:[NSURL URLWithString:mediaObj.mediaURLString]
                                                                                                            options:SDWebImageLowPriority | SDWebImageRetryFailed
                                                                                                           progress:nil
                                                                                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                                                                                              
                                                                                                              if (finished)
                                                                                                              {
                                                                                                                  if (error || !image)
                                                                                                                  {
                                                                                                                      if (!wImageView.image)
                                                                                                                      {
                                                                                                                          wImageView.image = [UIImage imageNamed:@"ImageLoadinFailedIcon"];
                                                                                                                      }
                                                                                                                  }
                                                                                                                  else
                                                                                                                  {
                                                                                                                      wImageView.image = image;
                                                                                                                  }
                                                                                                              }
                                                                                                          }];
                                                             }
                                                             else
                                                             {
                                                                 [[wImageView viewWithTag:tagPlayIcon] setHidden:NO];
                                                             }
                                                         }
                                                     }];
        }
    }
    
    [self.links enumerateObjectsUsingBlock:^(id obj, BOOL *stop)
     {
         UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(positionX, 0.f, imageWidth, ExpandedMediaSize)];
         
         imageView.backgroundColor = [UIColor blackColor];
         imageView.contentMode = UIViewContentModeScaleAspectFill;
         imageView.clipsToBounds = YES;
         
         UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showFullMedia:)];
         tapRecognizer.mediaType = @(kMediaTypeLink);
         tapRecognizer.mediaURL = obj;
         
         [imageView addGestureRecognizer:tapRecognizer];
         imageView.userInteractionEnabled = YES;
         
         UIActivityIndicatorView *activityIndication = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
         activityIndication.center = CGPointMake(CGRectGetWidth(imageView.frame) / 2.f, CGRectGetHeight(imageView.frame) / 2.f);
         activityIndication.tag = tagActivityIdicator;
         [activityIndication startAnimating];
         [imageView addSubview:activityIndication];
         
         [self.mediaScrollView addSubview:imageView];
         
         NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:imageView
                                                                            attribute:NSLayoutAttributeWidth
                                                                            relatedBy:NSLayoutRelationEqual
                                                                               toItem:nil
                                                                            attribute:NSLayoutAttributeNotAnAttribute
                                                                           multiplier:1
                                                                             constant:imageWidth];
         
         [imageView addConstraint:widthConstraint];
         
         positionX += CGRectGetWidth(imageView.frame);
         
         UIImage *image = [[SDWebImageManager sharedManager].imageCache imageFromMemoryCacheForKey:[obj absoluteString]];
         
         if (!image)
         {
             image = [[SDWebImageManager sharedManager].imageCache imageFromDiskCacheForKey:[obj absoluteString]];
         }
         
         if (image)
         {
             imageView.image = image;
             [activityIndication removeFromSuperview];
             
             return;
         }
         
         __weak UIImageView *wImageView = imageView;
         
         [[WDDPreviewManager sharedManager] preparePreviewForURL:obj
                                                forSocialNetwork:self.post.subscribedBy.socialNetwork
                                                          result:^(NSURL *linkURL, UIImage *preview) {
                                                              
                                                              if (preview)
                                                              {
                                                                  CGFloat previewAspect = CGRectGetHeight(wImageView.frame) / CGRectGetWidth(wImageView.frame);
                                                                  CGFloat imageWidth = preview.size.width * [UIScreen mainScreen].scale;
                                                                  CGFloat imageHeight = preview.size.width * previewAspect * [UIScreen mainScreen].scale;
                                                                  CGFloat imageOffsetY = 0.f;//(preview.size.height * [UIScreen mainScreen].scale - imageHeight) / 2.f;
                                                                  
                                                                  UIImage *imagePreview = [preview croppedImage:CGRectMake(0.f, imageOffsetY,
                                                                                                                           imageWidth, imageHeight)];
                                                                  
                                                                  CGFloat scaleFactor = imageWidth / CGRectGetWidth(wImageView.frame) * [UIScreen mainScreen].scale;
                                                                  if (scaleFactor < 1.f)
                                                                  {
                                                                      imagePreview = [imagePreview resizedImage:CGSizeMake(imageWidth * scaleFactor,
                                                                                                                           imageHeight * scaleFactor)
                                                                                           interpolationQuality:kCGInterpolationMedium];
                                                                  }
                                                                  
                                                                  [[wImageView viewWithTag:tagActivityIdicator] removeFromSuperview];
                                                                  
                                                                  [[SDWebImageManager sharedManager].imageCache storeImage:imagePreview
                                                                                                                    forKey:linkURL.absoluteString];
                                                                  
                                                                  wImageView.image = imagePreview;
                                                              }
                                                              else
                                                              {
                                                                  [[wImageView viewWithTag:tagActivityIdicator] removeFromSuperview];
                                                                  wImageView.image = [UIImage imageNamed:@"ImageLoadinFailedIcon"];
                                                              }
                                                          }];
         
     }];
    
    self.mediaScrollView.contentSize = CGSizeMake(positionX, CGRectGetHeight(self.mediaScrollView.frame));
}

#pragma mark - User actions processing

- (void)showFullMedia:(UITapGestureRecognizer *)sender
{
    switch (sender.mediaType.intValue)
    {
        case kMediaPhoto:
            [self.delegate showFullImageWithURL:sender.mediaURL previewURL:sender.previewURL fromCell:nil];
            break;
            
        case kMediaVideo:
            [self.delegate showFullVideoWithURL:sender.mediaURL fromCell:nil];
            break;
    }
}

#pragma mark - Method for size calculation

- (void)setupHeight
{
    CGFloat height = [self calculateHeight];
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (CGFloat)calculateHeight
{
    CGSize textSize = CGSizeZero;
    CGFloat height = 0;
    
    textSize = [self sizeForText:[self getAttribudetPostText]
                        withFont:self.messageTextFont];
    
    CGFloat sizeToExpad = (self.post.media.count || self.links.count) ? ExpandedMediaSize : 0;
    CGFloat textHeight = ceilf(textSize.height) + 1;
        
    
    height = MessageMinY + textHeight + OffsetY * ((self.post.media.count || self.links.count) ? 2.0: 1.f) + sizeToExpad;

    if ([self.post.type  isEqual: @(kPostTypeEvent)])
    {
        height += ShowEventButtonHeight;
    }
    
    return height;
}

- (CGSize)sizeForText:(NSAttributedString *)text withFont:(UIFont *)font
{
    CGSize fitSize = CGSizeZero;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)text);
    if (framesetter)
    {
        CGSize targetSize = CGSizeMake(MessageWidth, INFINITY);
        fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [text length]), NULL, targetSize, NULL);
        CFRelease(framesetter);
    }
    
    return fitSize;
}

- (UIFont *)messageTextFont
{
    return [UIFont systemFontOfSize:kPostFontSize];
}

- (UIFont *)boldMessageTextFont
{
    return [UIFont boldSystemFontOfSize:kPostFontSize];
}
#pragma mark - Message

- (void)setupMessageTextLabel
{
    NSMutableAttributedString *postText = [self getAttribudetPostText];
    
    self.textMessage.linkColor = [UIColor blackColor];
    self.textMessage.linkUnderlineStyle = kCTUnderlineStyleNone | kOHBoldStyleTraitSetBold;
    self.textMessage.automaticallyAddLinksForType = 0;
    
    self.textMessage.attributedText = postText;
    
    self.messageLabelHeight.constant = [self sizeForText:postText
                                                withFont:self.messageTextFont].height + ([self.post.group.type isEqual:@(kGroupTypeGroup)] ? 8.0f : 0.0f);
}

- (NSMutableAttributedString *)getAttribudetPostText
{
    static NSDataDetector *dataDetector = nil;
    if (!dataDetector)
    {
        dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink
                                                       error:nil];
    }
    
    __block NSMutableAttributedString *postText = [[NSMutableAttributedString alloc] initWithString:self.post.text attributes:@{NSFontAttributeName : [self messageTextFont]}];    
    
    if (!self.post.isLinksProcessed.boolValue)
    {
        BOOL allLinksFound = YES;
        NSMutableDictionary *linkPairs = [[NSMutableDictionary alloc] initWithCapacity:self.post.links.count];
        
        for (Link *link in self.post.links)
        {
            NSRange range = [postText.mutableString rangeOfString:link.url];
            NSURL *linkURL = [NSURL URLWithString:link.url];
            
            if (!link.isShortLink)
            {
                NSURL *cachedLink = [[WDDURLShorter defaultShorter] cachedLinkForURL:linkURL];
                
                if (cachedLink)
                {
                    [linkPairs setObject:cachedLink.absoluteString forKey:link.objectID];
                    [postText.mutableString replaceOccurrencesOfString:link.url
                                                               withString:cachedLink.absoluteString
                                                                  options:NSCaseInsensitiveSearch
                                                                    range:NSMakeRange(0, postText.mutableString.length)];
                    range = [postText.mutableString rangeOfString:cachedLink.absoluteString];
                    
                    if (self.post.subscribedBy.socialNetwork.type.integerValue != kSocialNetworkTwitter)
                    {
                        [postText setLink:cachedLink range:range];
                    }
                    else
                    {
                        if ([Link isURLShort:cachedLink])
                        {
                            [postText setLink:cachedLink range:range];
                        }
                    }
                }
                else
                {
                    allLinksFound = NO;
                    
                    if (self.post.subscribedBy.socialNetwork.type.integerValue != kSocialNetworkTwitter)
                    {
                        [postText setLink:linkURL range:range];
                    }
                }
            }
            else
            {
                if (self.post.subscribedBy.socialNetwork.type.integerValue != kSocialNetworkTwitter)
                {
                    [postText setLink:linkURL range:range];
                }
                else
                {
                    if ([Link isURLShort:linkURL])
                    {
                        [postText setLink:linkURL range:range];
                    }
                }
            }
        }
        
        if (allLinksFound)
        {
            NSManagedObjectContext *objectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            objectContext.parentContext = [WDDDataBase masterObjectContext];
            
            for (NSManagedObjectID *linkID in linkPairs.allKeys)
            {
                NSError *error = nil;
                Link *link = (Link *)[objectContext existingObjectWithID:linkID
                                                                   error:&error];
                if (error)
                {
                    DLog(@"Can't find link in local context because of %@", error.localizedDescription);
                }
                link.url = linkPairs[linkID];
            }
            
            NSError *error = nil;
            Post *localPost = (Post *)[objectContext existingObjectWithID:self.post.objectID
                                                                    error:&error];
            if (error)
            {
                DLog(@"Can't find post in local context because of %@", error.localizedDescription);
            }
            
            localPost.text = postText.string;
            localPost.isLinksProcessed = @YES;
            
            error = nil;
            [objectContext save:&error];
            if (!error)
            {
                [objectContext.parentContext performBlock:^{
                    
                    NSError *error = nil;
                    [objectContext.parentContext save:&error];
                    
                    if (error)
                    {
                        DLog(@"Can't save master context because of %@", error.localizedDescription);
                    }
                }];
            }
            else
            {
                DLog(@"Can't save local context because of %@", error.localizedDescription);
            }
        }
    }
    else
    {
        for (Link *link in self.post.links)
        {
            NSRange range = [postText.mutableString rangeOfString:link.url];
            NSURL *linkURL = [NSURL URLWithString:link.url];
            
            if (self.post.subscribedBy.socialNetwork.type.integerValue != kSocialNetworkTwitter)
            {
                [postText setLink:linkURL range:range];
            }
            else
            {
                if ([Link isURLShort:linkURL])
                {
                    [postText setLink:linkURL range:range];
                }
            }
        }
    }
    
    //  Tags
    for (Tag *tag in self.post.tags)
    {
        NSString *regexString = [NSString stringWithFormat:@"%@([^\\w]|$)", tag.tag];
        NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [regex matchesInString:postText.string options:0 range:NSMakeRange(0, [postText.string length])];
        for (NSTextCheckingResult *match in matches)
        {
            NSRange matchRange = [match range];
            NSString *tagString = [tag.tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            /*
            [postText setLink:[NSURL URLWithString:[kTagURLBase stringByAppendingString:tagString]]
                        range:matchRange];
             */
            if (self.post.subscribedBy.socialNetwork.type.integerValue != kSocialNetworkTwitter)
            {
                [postText setLink:[NSURL URLWithString:[kTagURLBase stringByAppendingString:tagString]]
                            range:matchRange];
            }
            else
            {
                if ([Link isURLStringShort:[kTagURLBase stringByAppendingString:tagString]])
                {
                    [postText setLink:[NSURL URLWithString:[kTagURLBase stringByAppendingString:tagString]]
                                range:matchRange];
                }
            }
        }
    }
    
    //  Names
    NSString *regexString = [NSString stringWithFormat:@"(?:(?<=\\s)|^)@(\\w*[0-9A-Za-z_]+\\w*)"];
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:nil];
    NSArray *matches = [regex matchesInString:postText.string
                                      options:0
                                        range:NSMakeRange(0, [postText.string length])];
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = [match range];
        NSString *username = [[postText.string substringWithRange:matchRange] stringByReplacingOccurrencesOfString:@"@" withString:@""];
        NSString *urlBase = ([self.post isKindOfClass:[TwitterPost class]] ? kTwitterNameURLBase : kTagURLBase);
        
        //[postText setLink:[NSURL URLWithString:[urlBase stringByAppendingString:username]]
                    //range:matchRange];
        
        if (self.post.subscribedBy.socialNetwork.type.integerValue != kSocialNetworkTwitter)
        {
            [postText setLink:[NSURL URLWithString:[urlBase stringByAppendingString:username]]
                        range:matchRange];
        }
        else
        {
//            if ([[urlBase stringByAppendingString:username] rangeOfString:@"t.co/"].location != NSNotFound)
            if ([Link isURLStringShort:[urlBase stringByAppendingString:username]])
            {
                [postText setLink:[NSURL URLWithString:[urlBase stringByAppendingString:username]]
                            range:matchRange];
            }
        }
    }
    
    //  Add group name
    if ([self.post.group.type isEqual:@(kGroupTypeGroup)])
    {
        NSString *fromGroupStringBase = NSLocalizedString(@"lskFromGroupBase", @"From group base string");
        NSMutableAttributedString *groupNameTitle =  [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n\r", fromGroupStringBase, self.post.group.name]];
        [groupNameTitle appendAttributedString:postText];
        postText = groupNameTitle;
    }
    
    if ([self.post.group.type isEqual:@(kGroupTypePage)])
    {
        NSString *fromGroupStringBase = NSLocalizedString(@"lskFromPageBase", @"From page base string");
        NSMutableAttributedString *groupNameTitle =  [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n\r", fromGroupStringBase, self.post.group.name]];
        [groupNameTitle appendAttributedString:postText];
        postText = groupNameTitle;
    }
    
    return postText;
}

#pragma mark - Show author profile
- (void)showAuthorProfile
{
    if ([self.delegate respondsToSelector:@selector(showUserPageWithURL:fromCell:)])
    {
        [self.delegate showUserPageWithURL:[NSURL URLWithString:self.post.author.profileURL]
                                  fromCell:nil];
    }
}

#pragma mark - Actions

- (IBAction)showEventInformation:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(showEventWithEventURL:fromCell:)])
    {
        [self.delegate showEventWithEventURL:[NSURL URLWithString:self.post.linkURLString] fromCell:nil];
    }
}

@end
