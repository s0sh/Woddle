//
//  WDDCommentPreView.m
//  Woddl
//
//  Created by Sergii Gordiienko on 26.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDCommentPreView.h"

#import "Tag.h"
#import "Comment.h"
#import "UserProfile.h"
#import "TwitterPost.h"
#import "InstagramPost.h"
#import "Link+Additions.h"

#import "WDDURLShorter.h"
#import "WDDDataBase.h"

#import <OHAttributedLabel/OHAttributedLabel.h>
#import <SDWebImage/SDWebImageManager.h>

#import "UIImageView+AvatarLoading.h"
#import "UIImage+ResizeAdditions.h"
#import "UIImageView+WebCache.h"
#import "NSDate+TimeAgo.h"


#define bgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)

static const CGFloat kCommentsViewWidth = 320.0f;
static const CGFloat kMessageWidth = 260.0f;
static const CGFloat kEdgeOffset = 10.0f;
static const CGFloat kStandratViewOffset = 8.0f;

static const CGFloat kAvatarSize = 32.0f;

static const CGFloat kAuthorLabelWidth = 180.0f;
static const CGFloat kAuthorLabelHeight = 20.0f;

static const CGFloat kTimeAgoLabelWidth = 100.0f;
static const CGFloat kTimeAgoLabelHeight = 20.0f;


@interface WDDCommentPreView() <OHAttributedLabelDelegate>

@property (weak, nonatomic) UIImageView *separatorImageView;
@property (strong, nonatomic) NSString *authorProfileURLString;

@property (nonatomic, strong) NSManagedObjectID *commentId;

@end

@implementation WDDCommentPreView

- (void)setMessageLabeldelegate:(id<OHAttributedLabelDelegate>)messageLabeldelegate
{
    _messageLabeldelegate = messageLabeldelegate;
    self.commentLabel.delegate = messageLabeldelegate;
}

static UIImage *placeHolderImage = nil;

- (instancetype)initWithComment:(Comment *)comment
{
    self = [super init];
    if (self)
    {
        self.frame = CGRectMake(0, 0, kCommentsViewWidth, [WDDCommentPreView sizeOfViewForComment:comment].height );
        self.commentId = comment.objectID;
        
        self.commentLabel = [self addCommetLabelForComment:comment];
        UIImageView *avatarView = [self addAvatarImageViewForComment:comment];
        UILabel *authorLabel = [self addAuthorLableWithComment:comment];
        [self addTimeAgoLabelWithComment:comment];
        _separatorImageView = [self addSeparator];
        
        self.backgroundColor = [UIColor colorWithRed:245/255.0f
                                               green:245/255.0f
                                                blue:245/255.0f
                                               alpha:1.0f];
        
        self.authorProfileURLString = comment.author.profileURL;
        
        [self setupShowProfileTapForView:avatarView];
        [self setupShowProfileTapForView:authorLabel];
    }
    return  self;
}


- (void)setupShowProfileTapForView:(UIView *)view
{
    [view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAuthorProfile)]];
    [view setUserInteractionEnabled:YES];
}

#pragma mark - Adding Subviews

- (UIImageView *)addSeparator
{
    UIImageView *separatorView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cell_bottom_shadow"]];
    separatorView.backgroundColor = [UIColor whiteColor];
    separatorView.opaque = YES;
    
    CGRect frame = separatorView.frame;
    frame.origin.y = CGRectGetMaxY(self.frame)-frame.size.height;
    separatorView.frame = frame;
    
    [self addSubview:separatorView];
    return separatorView;
}

- (UILabel *)addTimeAgoLabelWithComment:(Comment *)comment
{
    UILabel *timeAgoLabel = [[UILabel alloc]  initWithFrame:CGRectMake(CGRectGetWidth(self.frame) - kEdgeOffset - kTimeAgoLabelWidth,
                                                                       kEdgeOffset,
                                                                       kTimeAgoLabelWidth,
                                                                       kTimeAgoLabelHeight)];
    timeAgoLabel.text = [comment.date timeAgo];
    timeAgoLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    timeAgoLabel.textColor = [UIColor lightGrayColor];
    timeAgoLabel.textAlignment = NSTextAlignmentRight;
    timeAgoLabel.backgroundColor = [UIColor whiteColor];
    timeAgoLabel.opaque = YES;
     
    [timeAgoLabel setUserInteractionEnabled:YES];
    [self addSubview:timeAgoLabel];
    return timeAgoLabel;
}

- (UILabel *)addAuthorLableWithComment:(Comment *)commnet
{
    UILabel *authorLabel = [[UILabel alloc]  initWithFrame:CGRectMake(kEdgeOffset + kAvatarSize + kStandratViewOffset,
                                                                      kEdgeOffset,
                                                                      kAuthorLabelWidth,
                                                                      kAuthorLabelHeight)];
    
    authorLabel.text = commnet.author.name;
    authorLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    authorLabel.textColor = [UIColor blackColor];
    authorLabel.textAlignment = NSTextAlignmentLeft;
    authorLabel.backgroundColor = [UIColor whiteColor];
    authorLabel.opaque = YES;
    
    [authorLabel setUserInteractionEnabled:YES];
    [self addSubview:authorLabel];
    return authorLabel;
}

- (UIImageView *)addAvatarImageViewForComment:(Comment *)comment
{
    UIImageView *avatarImage = [[UIImageView alloc] initWithFrame:CGRectMake(kEdgeOffset, kEdgeOffset, kAvatarSize, kAvatarSize)];
    avatarImage.backgroundColor = [UIColor whiteColor];
    avatarImage.opaque = YES;
    
    NSURL *avatarURL = [NSURL URLWithString:comment.author.avatarRemoteURL];
    [avatarImage setAvatarWithURL:avatarURL];
    
//    avatarImage.layer.masksToBounds = YES;
//    [avatarImage.layer setCornerRadius:kAvatarCornerRadious];
    
    [avatarImage setUserInteractionEnabled:YES];
    [self addSubview:avatarImage];
    return avatarImage;
}

+ (void)buildCommentText:(NSMutableAttributedString **)text
               forCommet:(Comment *)comment
                 forSize:(BOOL)forSize
          commentPreview:(WDDCommentPreView *)commentPreview
{
    static NSDataDetector *dataDetector = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    });
    
    __block NSMutableAttributedString *commetText = *text;
    
    if (!comment.isLinksProcessed.boolValue)
    {
        __block BOOL allLinksFound = YES;
        
        [dataDetector enumerateMatchesInString:commetText.string
                                       options:NSMatchingReportCompletion
                                         range:NSMakeRange(0, comment.text.length)
                                    usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                        
                                        if (result.resultType == NSTextCheckingTypeLink)
                                        {
                                            NSString *linkString = [comment.text substringWithRange:result.range];
                                            
                                            if (![Link isURLStringShort:linkString])
                                            {
                                                NSURL *linkURL = [NSURL URLWithString:linkString];
                                                NSURL *cachedLink = [[WDDURLShorter defaultShorter] cachedLinkForURL:linkURL];
                                                
                                                if (cachedLink)
                                                {
                                                    [commetText.mutableString replaceOccurrencesOfString:linkString
                                                                                              withString:cachedLink.absoluteString
                                                                                                 options:NSCaseInsensitiveSearch
                                                                                                   range:NSMakeRange(0, commetText.mutableString.length)];
                                                    NSRange linkRange = [commetText.mutableString rangeOfString:cachedLink.absoluteString];
                                                    
                                                    if (forSize)
                                                    {
                                                        [commetText addAttribute:UITextAttributeFont value:[self messageBoldTextFont] range:linkRange];
                                                    }
                                                    else
                                                    {
                                                        [commetText setLink:cachedLink range:linkRange];
                                                    }
                                                }
                                                else
                                                {
                                                    __weak WDDCommentPreView *w_self = commentPreview;
                                                    
                                                    [[WDDURLShorter defaultShorter] getLinkForURL:linkURL
                                                                                     withCallback:^(NSURL *resultURL)
                                                    {
                                                         @synchronized(w_self)
                                                         {
                                                             NSMutableAttributedString *text = [w_self.commentLabel.attributedText mutableCopy];
                                                             [text.mutableString replaceOccurrencesOfString:linkURL.absoluteString
                                                                                                 withString:resultURL.absoluteString options:NSCaseInsensitiveSearch range:NSMakeRange(0, text.mutableString.length)];
                                                             NSRange newRange = [text.mutableString rangeOfString:resultURL.absoluteString];
                                                             [text setLink:resultURL range:newRange];
                                                             
                                                             dispatch_async(dispatch_get_main_queue(), ^()
                                                             {
                                                                 w_self.commentLabel.attributedText = text;
                                                                 [w_self.delegate needRelayoutCommentWithID:w_self.commentId];
                                                             });
                                                         }
                                                     }];
                                                    
                                                    if (forSize)
                                                    {
                                                        [commetText addAttribute:UITextAttributeFont value:[self messageBoldTextFont] range:result.range];
                                                    }
                                                    
                                                    allLinksFound = NO;
                                                }
                                            }
                                            else
                                            {
                                                NSRange linkRange = [commetText.mutableString rangeOfString:linkString];
                                                if (forSize)
                                                {
                                                    [commetText addAttribute:UITextAttributeFont value:[self messageBoldTextFont] range:linkRange];
                                                }
                                                else
                                                {
                                                    [commetText setLink:[NSURL URLWithString:linkString] range:linkRange];
                                                }
                                            }
                                        }
                                    }];
        
        if (allLinksFound)
        {
            NSManagedObjectContext *objectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            objectContext.parentContext = [WDDDataBase masterObjectContext];
            
            NSError *error = nil;
            Comment *localComment = (Comment *)[objectContext existingObjectWithID:comment.objectID
                                                                             error:&error];
            if (error)
            {
                DLog(@"Can't find post in local context because of %@", error.localizedDescription);
            }
            
            localComment.text = commetText.string;
            localComment.isLinksProcessed = @YES;
            
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
    
    for (Tag *tag in comment.tags)
    {
        NSString *regexString = [NSString stringWithFormat:@"%@([^\\w]|$)", tag.tag];
        NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [regex matchesInString:comment.text options:0 range:NSMakeRange(0, [comment.text length])];
        for (NSTextCheckingResult *match in matches)
        {
            NSRange matchRange = [match range];
            NSString *tagString = [tag.tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            if (forSize)
            {
                [commetText addAttribute:UITextAttributeFont value:[self messageBoldTextFont] range:matchRange];
            }
            else
            {
                [commetText setLink:[NSURL URLWithString:[kTagURLBase stringByAppendingString:tagString]]
                              range:matchRange];
            }
        }
    }
    
    //  Names
    NSString *regexString = [NSString stringWithFormat:@"(?:(?<=\\s)|^)@(\\w*[0-9A-Za-z_]+\\w*)"];
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:nil];
    NSArray *matches = [regex matchesInString:comment.text
                                      options:0
                                        range:NSMakeRange(0, [comment.text length])];
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = [match range];
        NSString *username = [[comment.text substringWithRange:matchRange] stringByReplacingOccurrencesOfString:@"@" withString:@""];
        
        NSString *urlBase;
        if  ([comment.post isKindOfClass:[TwitterPost class]])
        {
            urlBase = kTwitterNameURLBase;
        }
        else if ([comment.post isKindOfClass:[InstagramPost class]])
        {
            urlBase = kInstagramNameURLBase;
        }
        else
        {
            urlBase = kTagURLBase;
        }
        
        
        if (forSize)
        {
            [commetText addAttribute:UITextAttributeFont value:[self messageBoldTextFont] range:matchRange];
        }
        else
        {
            [commetText setLink:[NSURL URLWithString:[urlBase stringByAppendingString:username]]
                          range:matchRange];
        }
    }
}

- (OHAttributedLabel *)addCommetLabelForComment:(Comment *)comment
{
    __block NSMutableAttributedString *commetText = [[NSMutableAttributedString alloc] initWithString:comment.text
                                                                                   attributes:@{ NSFontAttributeName : [WDDCommentPreView messageTextFont],
                                                                                                 NSForegroundColorAttributeName : [UIColor blackColor] }];
    [[self class] buildCommentText:&commetText forCommet:comment forSize:YES commentPreview:self];
    
    CGSize textSize = [WDDCommentPreView sizeForText:commetText withFont:[WDDCommentPreView messageTextFont]];
    
    OHAttributedLabel *commentMessageLabel = [[OHAttributedLabel alloc] initWithFrame:CGRectMake(kEdgeOffset+kAvatarSize+kStandratViewOffset, kEdgeOffset + kAuthorLabelHeight + kStandratViewOffset, textSize.width, textSize.height)];
    
    commentMessageLabel.linkColor = [UIColor blackColor];
    commentMessageLabel.linkUnderlineStyle = kCTUnderlineStyleNone | kOHBoldStyleTraitSetBold;
    commentMessageLabel.backgroundColor = [UIColor clearColor];
    commentMessageLabel.opaque = YES;
    commentMessageLabel.attributedText = commetText;
    [commentMessageLabel setUserInteractionEnabled:YES];
    if (IS_IOS7)
    {
        [commentMessageLabel setTintColor:[UIColor clearColor]];
    }
    [self addSubview:commentMessageLabel];
    
    return commentMessageLabel;
}

#pragma mark - Calculating text height of comment

+ (CGSize)sizeForText:(NSAttributedString *)text withFont:(UIFont *)font
{    
    CGSize fitSize = CGSizeZero;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)text);
    if (framesetter)
    {
        CGSize targetSize = CGSizeMake(kMessageWidth, INFINITY);
        fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [text length]), NULL, targetSize, NULL);
        CFRelease(framesetter);
    }
    
    return fitSize;
}

+ (UIFont *)messageTextFont
{
    return [UIFont systemFontOfSize:12.f];
}

+ (UIFont *)messageBoldTextFont
{
    return [UIFont boldSystemFontOfSize:12.f];
}

#pragma mark - Class methods

+ (CGSize)sizeOfViewForComment:(Comment *)comment
{
    NSMutableAttributedString *commetText = [[NSMutableAttributedString alloc] initWithString:comment.text attributes:@{NSFontAttributeName : [WDDCommentPreView messageTextFont]}];
    [self buildCommentText:&commetText forCommet:comment forSize:YES commentPreview:nil];
    CGSize textSize = [WDDCommentPreView sizeForText:commetText withFont:[WDDCommentPreView messageTextFont]];
    CGFloat height = kEdgeOffset*2 + kAuthorLabelHeight + kStandratViewOffset + textSize.height;
    return CGSizeMake(kCommentsViewWidth, height);
}

#pragma mark - other logic

- (void)hideSeparator
{
    self.separatorImageView.hidden = YES;
}

#pragma mark - Show author profile

- (void)showAuthorProfile
{
    if ([self.delegate respondsToSelector:@selector(showCommentUserProfileWithURL:)])
    {
        [self.delegate showCommentUserProfileWithURL:[NSURL URLWithString:self.authorProfileURLString]];
    }
}



@end
