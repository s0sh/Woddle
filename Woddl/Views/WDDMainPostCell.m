//
//  WDDMainPostCell.m
//  Woddl
//
//  Created by Sergii Gordiienko on 08.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDMainPostCell.h"
#import "WDDConstants.h"
#import "SocialNetwork.h"
#import "Media.h"
#import "Post.h"

#import <SDWebImage/SDWebImageManager.h>
#import "UITapGestureRecognizer+MediaInfo.h"
#import "WDDCommentPreView.h"
#import "WDDPreviewManager.h"

#import "NSString+Additions.h"
#import "NSString+MD5.h"
#import "UIImage+ResizeAdditions.h"

#define SHOW_COMMENTS 0

#define bgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)

static const CGFloat FiveStringsTextSize = 86.f;    // 5 strings
static const CGFloat SixStringsTextSize = 100.f;    // 6 strings - MaximumNormalTextSize
static const CGFloat SevenStringsTextSize = 114.f;  // 7 strings

static const CGFloat MaximumExpandSize = 240.f;
static const CGFloat ExpandedMediaSize = 120.f;
static const CGFloat MediaTriangleHeight = 10.0f;

static const CGFloat LikesAndCommentsIconWidth = 17.f;
static const CGFloat LikesAndCommentsLabelWidth = 26.f;
static const CGFloat LikesAndCommentsLeftOffset = 2.f;

static const CGFloat ShowEventButtonHeight = 38.0f;

static const CGFloat AuthorNameRightOffset = 50.f;

static const NSInteger kMediaTypeLink = 254;

static NSMutableDictionary *st_iconsCache = nil;

@interface WDDMainPostCell () <OHAttributedLabelDelegate, WDDCommentPreviewDelegate>

@property (nonatomic, strong) NSSet *medias;
@property (nonatomic, strong) NSArray *comments;
@property (nonatomic, strong) NSSet *links;

- (NSAttributedString *)formShortMessageStringWithMessageText:(NSAttributedString *)fullText
                                                  searchRange:(NSRange)searchRange;

@end

@implementation WDDMainPostCell

- (void)awakeFromNib
{
    if (!st_iconsCache)
    {
        st_iconsCache = [NSMutableDictionary new];
    }
    
    [self.mediaScrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.mediaScrollView.scrollsToTop = NO;
    [self.commentsView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.likesIconWidth.constant = LikesAndCommentsIconWidth;
    self.likesLabelWidth.constant = LikesAndCommentsLabelWidth;
    self.likesIconOffset.constant = LikesAndCommentsLeftOffset;
    self.commentIconWidth.constant = LikesAndCommentsIconWidth;
    self.commentsLabelWidth.constant = LikesAndCommentsLabelWidth;
    self.commentsIconOffset.constant = LikesAndCommentsLeftOffset;

    self.commentsViewHeight.constant = 0.0f;
    self.commentsViewBottomOffSet.constant = 0.0f;
    
    self.textMessage.linkColor = [UIColor blackColor];
    self.textMessage.linkUnderlineStyle = kCTUnderlineStyleNone | kOHBoldStyleTraitSetBold;
    self.textMessage.automaticallyAddLinksForType = 0;
    
    self.textMessage.extendBottomToFit = YES;
    self.textMessage.delegate = self;
    
    //  Setup tap gesture
    [self setupShowProfileTapForView:self.authorNameLabel];
    [self setupShowProfileTapForView:self.avatarImageView];
}

- (void)setupShowProfileTapForView:(UIView *)view
{
    [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAuthorProfile)]];
    [view setUserInteractionEnabled:YES];
}

- (void)setNumberOfComments:(NSNumber *)commentsCount
{
    if (commentsCount)
    {
        if (!st_iconsCache[self.commentsIconImageName])
        {
            UIImage *icon = [UIImage imageNamed:self.commentsIconImageName];
            [st_iconsCache setObject:icon forKey:self.commentsIconImageName];
        }
        
        self.commentsIconImageView.image = st_iconsCache[self.commentsIconImageName];
        
//        dispatch_async(bgQueue, ^{
//            UIImage* commentIconImage = [UIImage imageNamed:self.commentsIconImageName];
//            dispatch_async(dispatch_get_main_queue(), ^{
//                self.commentsIconImageView.image = commentIconImage;
//            });
//        });
        
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
            UIImage* likesIconImage = [UIImage imageNamed:self.likeIconImageName];
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
        self.likesIconOffset.constant = 0.f;
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

- (void)setMediasList:(NSSet *)medias
{
    self.medias = medias;
    
    self.mediaScrollHeight.constant = (self.medias.count || self.links.count ? ExpandedMediaSize : 0);
    
    __block CGFloat positionX = 0.f;
    NSInteger tagActivityIdicator = 1024;
    NSInteger tagPlayIcon = 1025;
    
    NSMutableArray *linksList = [NSMutableArray new];

//    if (self.shouldPreviewLinksAsMedia && self.textMessage.attributedText.length)
//    {
//        [self.textMessage.linksDataDetector enumerateMatchesInString:self.fullMessageText.string
//                                                             options:NSMatchingReportCompletion
//                                                               range:NSMakeRange(0, self.fullMessageText.string.length)
//                                                          usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
//                                                              if (result.resultType == NSTextCheckingTypeLink)
//                                                              {
//                                                                  NSString *linkString = [self.fullMessageText.string substringWithRange:result.range];
//                                                                  [linksList addObject:[NSURL URLWithString:[linkString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
//                                                              }
//                                                          }];
//    }

    
    self.links = [NSSet setWithArray:linksList];
    
    CGFloat imageWidth = CGRectGetWidth([UIScreen mainScreen].bounds) / (self.medias.count + self.links.count > 1 ? 2 : 1);
    
    for (Media *mediaObj in self.medias)
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
            
            
            
            [[SDWebImageManager sharedManager] downloadWithURL:[NSURL URLWithString:(mediaObj.previewURLString ? mediaObj.previewURLString : mediaObj.mediaURLString)]
                                                       options:SDWebImageLowPriority | SDWebImageRetryFailed
                                                      progress:nil
                                                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                                         if (finished)
                                                         {
                                                             [[wImageView viewWithTag:tagActivityIdicator] removeFromSuperview];

                                                             if (!error)
                                                             {
                                                                 [[wImageView viewWithTag:tagPlayIcon] setHidden:NO];
                                                                 wImageView.image = image;
                                                             }
                                                             
                                                             if ([wMediaObject.type isEqual:@(kMediaPhoto)])
                                                             {
                                                                 NSString *mediaURLString = mediaObj.mediaURLString;
                                                                 [[SDWebImageManager sharedManager] downloadWithURL:[NSURL URLWithString:mediaURLString]
                                                                                                            options:SDWebImageLowPriority | SDWebImageRetryFailed
                                                                                                           progress:nil
                                                                                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                                                                                              
                                                                                                              if (finished)
                                                                                                              {
                                                                                                                  if (error || !image)
                                                                                                                  {
                                                                                                                      DLog(@"Fail to load image with url: %@", mediaURLString);
                                                                                                                      
                                                                                                                      if (!wImageView.image)
                                                                                                                      {
                                                                                                                          wImageView.image = [UIImage imageNamed:@"ImageLoadinFailedIcon"];
                                                                                                                      }
                                                                                                                  }
                                                                                                                  else if(image.size.height < [UIScreen mainScreen].bounds.size.height && image.size.width < [UIScreen mainScreen].bounds.size.width)
                                                                                                                  {
                                                                                                                      wImageView.image = image;
                                                                                                                  }
                                                                                                                  else
                                                                                                                  {
                                                                                                                      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                                                                                                                          
                                                                                                                          CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
                                                                                                                          CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
                                                                                                                          CGSize rescaledImageSize = (image.size.width > image.size.height) ? CGSizeMake(screenHeight, screenWidth) : CGSizeMake(screenWidth, screenHeight);
                                                                                                                          
                                                                                                                          UIImage *rescaledImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit bounds:rescaledImageSize interpolationQuality:kCGInterpolationMedium];
                                                                                                                          
                                                                                                                          [[[SDWebImageManager sharedManager] imageCache] storeImage:rescaledImage forKey:wMediaObject.mediaURLString];
                                                                                                                          
                                                                                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                              
                                                                                                                              wImageView.image = rescaledImage;
                                                                                                                              
                                                                                                                          });
                                                                                                                          
                                                                                                                      });
                                                                                                                  }
                                                                                                              }
                                                                                                          }];
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
                                               forSocialNetwork:self.snPost.subscribedBy.socialNetwork
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

- (void)setRecentCommets:(NSArray *)comments
{
    if (!comments.count) {
        return ;
    }
    
    self.comments = comments;
    [self configureCommentsView];
}

- (void)setDelegate:(id<WDDMainPostCellDelegate>)delegate
{
    _delegate = delegate;
    for (WDDCommentPreView *preview in self.commentsView.subviews)
    {
        preview.delegate = delegate;
    }
}

- (void)setFullMessageText:(NSAttributedString *)fullMessageText
{
    _fullMessageText = fullMessageText;
    
    if (!self.isExpanded && self.isExpandable)
    {
        self.textMessage.text = nil;
        self.textMessage.attributedText = self.shortMessageText;
    }
    else
    {
        self.textMessage.text = nil;
        self.textMessage.attributedText = fullMessageText;
    }
}

- (NSAttributedString *)shortMessageText
{
    if (self.fullMessageText && !_shortMessageText)
    {
        @autoreleasepool
        {
            _shortMessageText = [self formShortMessageStringWithMessageText:self.fullMessageText
                                                                searchRange:NSMakeRange(0, self.fullMessageText.length)];
        }
     }
    return _shortMessageText;
}

- (NSAttributedString *)formShortMessageStringWithMessageText:(NSAttributedString *)fullText
                                                  searchRange:(NSRange)searchRange;
{
    CGSize textSize = [self.class sizeForText:fullText withFont:[self.class messageTextFont]];
    NSRange newSearchRange = NSMakeRange(NSNotFound, 0);
    
    if (textSize.height <= SixStringsTextSize)
    {
        NSUInteger length = fullText.length;
        while (textSize.height <= SixStringsTextSize && length < self.fullMessageText.length)
        {
            length++;
            NSAttributedString *newText = [self.fullMessageText attributedSubstringFromRange:NSMakeRange(0, length)];
            textSize = [self.class sizeForText:newText withFont:[self.class messageTextFont]];
        }
        length--;
        
        NSMutableAttributedString *newText = [NSMutableAttributedString attributedStringWithAttributedString:[self.fullMessageText attributedSubstringFromRange:NSMakeRange(0, length)]];
        
        
        BOOL isEndsWithNewLine = [newText.string isEndsWithNewlineCharacter];
        NSString *showMoreString = [NSString stringWithFormat:@"%@%@",
                                    (isEndsWithNewLine ? @"" : @"\n"),
                                    NSLocalizedString(@"lskShowMore", @"Show more button")];
        NSUInteger newLineOffset = (isEndsWithNewLine ? 0 : 1);
        
        NSDictionary *attributes = @{ NSFontAttributeName : [WDDMainPostCell messageTextFont],
                                      NSForegroundColorAttributeName : [UIColor blackColor] };
        NSMutableAttributedString *showMoreAtrString = [[NSMutableAttributedString alloc] initWithString:showMoreString
                                                                                           attributes:attributes];
        
        NSMutableParagraphStyle *paragrapStyle = [[NSMutableParagraphStyle alloc] init];
        paragrapStyle.alignment = NSTextAlignmentRight;
        
        [showMoreAtrString addAttribute:NSParagraphStyleAttributeName
                                  value:paragrapStyle
                                  range:NSMakeRange(newLineOffset, showMoreString.length-newLineOffset)];
        
        [showMoreAtrString setLink:[NSURL URLWithString:kShowMoreURLBase]
                             range:NSMakeRange(newLineOffset, showMoreString.length-newLineOffset)];
        
        [newText appendAttributedString:showMoreAtrString];
        return newText;
    }
    else if (textSize.height > SixStringsTextSize)
    {
        newSearchRange = NSMakeRange(searchRange.location, searchRange.length/2);
    }
    
    NSAttributedString *newText = [self.fullMessageText attributedSubstringFromRange:NSMakeRange(0, newSearchRange.location+newSearchRange.length)];
    

    return [self formShortMessageStringWithMessageText:newText searchRange:newSearchRange];
}

- (BOOL)isExpandable
{
    CGSize postSize = [WDDMainPostCell sizeForText:self.fullMessageText withFont:self.textMessage.font];
    BOOL textExpandable = (postSize.height > SixStringsTextSize);
    
    return textExpandable;
}

- (void)setIsExpanded:(BOOL)isExpanded
{
    _isExpanded = isExpanded;
    self.arrowIcon.image = [UIImage imageNamed:(isExpanded ? @"ArrowUp" : @"ArrowDown")];
    self.commentsView.hidden = !isExpanded;
}

- (void)deleteButtonEnable:(BOOL)enable
{
    self.deleteButton.hidden = !enable;
}

- (void)setIsEvent:(BOOL)isEvent
{
    _isEvent = isEvent;
    self.showEventButton.hidden = !isEvent;
    [self.showEventButton setTitle:NSLocalizedString(@"lskShowEventButtonTitle", @"Show event details") forState:UIControlStateNormal];
}

static const CGFloat MessageWidth = 300.f;
static const CGFloat OffsetY = 10.f;
static const CGFloat MessageMinY = 51.f;

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.mediaScrollHeight.constant = (self.medias.count || self.links.count ? ExpandedMediaSize : 0);
    self.mediaTriangleHeight.constant = (self.medias.count || self.links.count ? MediaTriangleHeight : 0);
    self.mediaScrollBottomOffset.constant = (self.medias.count || self.links.count ? OffsetY : 0);
    self.textToMediaOffset.constant = (self.medias.count || self.links.count ? OffsetY / 2.f : OffsetY);
    self.arrowIcon.hidden = YES;
    self.commentsViewHeight.constant = (!self.isExpanded ? 0.f : [WDDMainPostCell heightForCommentsView:self.comments]);
    self.commentsViewBottomOffSet.constant = 0.0f;
    
    self.showEventInfoButtonHeight.constant = (self.isEvent ? ShowEventButtonHeight : 0.0f);
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self resetCellViews];
    
    self.isExpanded = NO;
    self.isEvent = NO;
    self.previewLinksAsMedia = NO;
    
    self.medias = nil;
    self.delegate = nil;
    self.comments = nil;
    self.likeIconImageName = nil;
    self.commentsIconImageName = nil;
    self.authorProfileURLString = nil;
    
    self.fullMessageText = nil;
    self.shortMessageText = nil;
    
    if (self.reuseBlock) self.reuseBlock(self.currentIndexPath);
}

- (void)resetCellViews
{
    self.avatarImageView.image = nil;
    self.socialNetworkIcon.image = nil;
    self.likesIconImageView.image = nil;
    self.commentsIconImageView.image = nil;
    
    self.timeAgoLabel.text = nil;
    self.authorNameLabel.text = nil;
    self.textMessage.text = nil;
    self.commentsCountLabel.text = nil;
    self.likesCountLabel.text = nil;
    [self.showEventButton setTitle:nil forState:UIControlStateNormal];
    self.showEventButton.hidden = YES;
    
    self.likesIconImageView.hidden = NO;
    self.likesCountLabel.hidden = NO;
    self.commentsIconImageView.hidden = NO;
    self.commentsCountLabel.hidden = NO;
    
    self.retweetsIcon.hidden = NO;
    self.retweetsCountLabel.hidden = NO;
    
    self.arrowIcon.image = [UIImage imageNamed:@"ArrowDown"];
    
    self.likesIconWidth.constant = LikesAndCommentsIconWidth;
    self.likesLabelWidth.constant = LikesAndCommentsLabelWidth;
    self.likesIconOffset.constant = LikesAndCommentsLeftOffset;
    self.commentIconWidth.constant = LikesAndCommentsIconWidth;
    self.commentsLabelWidth.constant = LikesAndCommentsLabelWidth;
    self.commentsIconOffset.constant = LikesAndCommentsLeftOffset;
    self.authorNameRightOffset.constant = AuthorNameRightOffset;
    self.retweetsLabelWidth.constant = LikesAndCommentsLabelWidth;
    
    [self removeViewFromSuperview:self.mediaScrollView];
    [self removeViewFromSuperview:self.commentsView];
}

- (void)removeViewFromSuperview:(UIView *)superview
{
    for (UIView *view in superview.subviews)
    {
        [view removeFromSuperview];
    }
}

#pragma mark - Static method for size calculation

+ (CGFloat)calculateCellHeightForText:(id)text
                            withMedia:(BOOL)isMedia
                         withComments:(NSArray *)comments
                               inMode:(CellMode)mode
                   shouldPreviewLinks:(BOOL)shouldPreviewLinks
{
    CGSize textSize = CGSizeZero;
    CGFloat cellHeight = 0;

    NSInteger textLength = ([text isKindOfClass:[NSAttributedString class]] ? [[text string] length] : [text length]);
    if (textLength)
    {
        textSize = [self sizeForText:text withFont:self.messageTextFont];
    }
    
    __block BOOL isContainLink = NO;
    CGFloat mediaScrollHeight = ((isMedia || isContainLink ) ? ExpandedMediaSize : OffsetY / 2.f);
    
    if (mode == CellModeExpanded)
    {
        CGFloat textHeight = ceilf(textSize.height) + 20.f;
        CGFloat commetsViewHeight = [WDDMainPostCell heightForCommentsView:comments];
        
        cellHeight = MessageMinY + textHeight + OffsetY * (isMedia || isContainLink ? 2.0f : 0.f) + mediaScrollHeight + commetsViewHeight;
    }
    else
    {
        CGFloat textHeight = round(textSize.height);
        if (textSize.height > SixStringsTextSize)
        {
            textHeight = SevenStringsTextSize;
        }
        cellHeight = MessageMinY + mediaScrollHeight + OffsetY * (isMedia || isContainLink ? 2.0f : 1.0f) + textHeight;
    }
    
    if (mode == CellModeEvent)
    {
        cellHeight += ShowEventButtonHeight;
    }
    
    return cellHeight;
}


static NSMutableDictionary *st_textSizes = nil;

+ (CGSize)sizeForText:(id)text withFont:(UIFont *)font
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        st_textSizes = [NSMutableDictionary new];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(memoryWarningReceived:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    });
    
    if (!text)
    {
        return CGSizeZero;
    }
    
    NSAttributedString *string = nil;
    if ([text isKindOfClass:[NSAttributedString class]])
    {
        string = text;
    }
    else
    {
        string = [NSMutableAttributedString attributedStringWithString:text];
        [(NSMutableAttributedString *)string setAttributes:@{UITextAttributeFont : font}
                                                     range:NSMakeRange(0, [text length])];
    }
    
    NSValue *size = [st_textSizes objectForKey:[[string string] MD5]];
    if (size)
    {
        return [size CGSizeValue];
    }

    CGSize fitSize = CGSizeZero;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)string);
    if (framesetter)
    {
        CGSize targetSize = CGSizeMake(MessageWidth, INFINITY);
        fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [string length]), NULL, targetSize, NULL);
        CFRelease(framesetter);
    }
    
    [st_textSizes setObject:[NSValue valueWithCGSize:fitSize]
                     forKey:[[string string] MD5]];
    
    return fitSize;
}

+ (void)memoryWarningReceived:(NSNotification *)notificaiton
{
    [st_textSizes removeAllObjects];
}

+ (UIFont *)messageTextFont
{
    return [UIFont systemFontOfSize:kPostFontSize];
}

+ (UIFont *)boldMessageTextFont
{
    return [UIFont boldSystemFontOfSize:kPostFontSize];
}

#pragma mark - User actions processing

- (void)showFullMedia:(UITapGestureRecognizer *)sender
{
    switch (sender.mediaType.intValue)
    {
        case kMediaPhoto:
            [self.delegate showFullImageWithURL:sender.mediaURL previewURL:sender.previewURL fromCell:self];
        break;
            
        case kMediaVideo:
            [self.delegate showFullVideoWithURL:sender.mediaURL fromCell:self];
        break;
            
        case kMediaTypeLink:
            [self.delegate showLinkWithURL:sender.mediaURL fromCell:self];
        break;
    }
}

- (IBAction)showMorePressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(shouldBeExpanded:)])
    {
        [self.delegate shouldBeExpanded:self];
    }
}

#pragma mark - Show comments logic

+ (CGFloat)heightForCommentsView:(NSArray *)comments
{
    CGFloat height = 0.0f;

#if SHOW_COMMENTS == 1
    for (Comment *commnet in comments)
    {
        height += [WDDCommentPreView sizeOfViewForComment:commnet].height;
    }
#else
    height = -8.f;
#endif
    
    return height;
}

- (void)configureCommentsView
{
#if SHOW_COMMENTS == 1
    CGFloat heightPosition = 0.0f;
    for (Comment *comment in self.comments)
    {
        WDDCommentPreView *preview = [[WDDCommentPreView alloc] initWithComment:comment];
        [preview hideSeparator];
        
        CGRect frame = preview.frame;
        frame.origin.y = heightPosition;
        preview.frame = frame;
        
        NSInteger index = [self.comments indexOfObject:comment];
        if (index == 0)
        {
            UIImageView *postShadow = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"post_shadow"]];
            [preview addSubview:postShadow];
        }
        
        preview.backgroundColor = [UIColor whiteColor];
        preview.messageLabeldelegate = self;
        preview.delegate = self;
        
        [self.commentsView addSubview:preview];
        
        heightPosition = CGRectGetMaxY(preview.frame);
    }
#endif
}

#pragma mark - Show author profile
- (void)showAuthorProfile
{
    if ([self.delegate respondsToSelector:@selector(showUserPageWithURL:fromCell:)])
    {
        [self.delegate showUserPageWithURL:[NSURL URLWithString:self.authorProfileURLString]
                                  fromCell:self];
    }
}

- (void)showCommentUserProfileWithURL:(NSURL *)url
{
    if ([self.delegate respondsToSelector:@selector(showUserPageWithURL:fromCell:)])
    {
        [self.delegate showUserPageWithURL:url
                                  fromCell:self];
    }
}

#pragma mark - OHLabel delegate

-(BOOL)attributedLabel:(OHAttributedLabel*)attributedLabel shouldFollowLink:(NSTextCheckingResult*)linkInfo
{
    NSString *urlString = [linkInfo.URL absoluteString];
    if ([urlString hasPrefix:kTagURLBase])
    {
        NSString *tag = [urlString substringFromIndex:kTagURLBase.length];
#if DEBUG
        DLog(@"Tag: %@", tag);
#endif
        tag = [tag stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        tag = [tag stringByReplacingOccurrencesOfString:@"%23" withString:@"#"];
        [self.delegate showPostsWithTag:tag fromCell:self];
    }
    else if ([urlString hasPrefix:kPlaceURLBase])
    {
        NSString *placeInfo = [urlString substringFromIndex:kPlaceURLBase.length];
#if DEBUG
        DLog(@"Place: %@", placeInfo);
#endif
        [self.delegate showPlaceWithInfo:placeInfo fromCell:self];
    }
    else if ([urlString hasPrefix:kInstagramNameURLBase])
    {
        NSString *tag = [urlString substringFromIndex:kInstagramNameURLBase.length];
        NSString *instagramBaseURL = @"http://instagram.com";
        NSString *instagramProfileURLString = [instagramBaseURL stringByAppendingPathComponent:tag];
        [self.delegate showUserPageWithURL:[NSURL URLWithString:instagramProfileURLString] fromCell:self];
    }
    else if ([urlString hasPrefix:kTwitterNameURLBase])
    {
        NSString *tag = [urlString substringFromIndex:kTwitterNameURLBase.length];
#if DEBUG
        DLog(@"Twitter name: %@", tag);
#endif
        NSString *twitterBaseURL = @"https://twitter.com";
        NSString *twitterProfileURLString = [twitterBaseURL stringByAppendingPathComponent:tag];
        [self.delegate showUserPageWithURL:[NSURL URLWithString:twitterProfileURLString] fromCell:self];
    }
    else if ([urlString hasPrefix:kShowMoreURLBase])
    {
#if DEBUG
        DLog(@"Show more pressed");
#endif
        [self.delegate shouldBeExpanded:self];
    }
    else
    {
        [self.delegate showLinkWithURL:linkInfo.URL fromCell:self];
    }
    
    return NO;
}

#pragma mark - Actions

- (IBAction)showEventInformation:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(showEventWithEventURL:fromCell:)])
    {
        [self.delegate showEventWithEventURL:[NSURL URLWithString:self.snPost.linkURLString] fromCell:self];
    }
}

- (IBAction)deleteFromReadLaterList:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(deleteFromReadLaterListFromCell:)])
    {
        [self.delegate deleteFromReadLaterListFromCell:self];
    }
}
#pragma mark - Links

+ (NSArray *) getLinksFromText:(NSString *) text shouldPreviewLinks:(BOOL)shouldPreviewLinks
{
    NSMutableArray *linksList = [NSMutableArray new];

    OHAttributedLabel *textMessage = [[OHAttributedLabel alloc] init];
    
    textMessage.text = text;
    
    if (shouldPreviewLinks && textMessage.attributedText.length)
    {
        [textMessage.linksDataDetector enumerateMatchesInString:textMessage.text
                                                             options:NSMatchingReportCompletion
                                                               range:NSMakeRange(0, textMessage.text.length)
                                                          usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                                              if (result.resultType == NSTextCheckingTypeLink)
                                                              {
                                                                  NSString *linkString = [textMessage.text substringWithRange:result.range];
                                                                  [linksList addObject:[NSURL URLWithString:[linkString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
                                                              }
                                                          }];
    }
    
    return linksList;
}

@end
