//
//  WDDChatMessageCell.m
//  Woddl
//
//  Created by Petro Korenev on 12/2/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDChatMessageCell.h"

#import "XMPPFramework.h"
//#import <XMPPFramework/XMPPMessageArchiving_Message_CoreDataObject.h>

#import <OHAttributedLabel/OHAttributedLabel.h>

#import <NSDate+TimeAgo/NSDate+TimeAgo.h>

#import <NSDate+TimeAgo/NSDate+TimeAgo.h>
#import "NSDate+fromDate.h"

#define TEXT_FONT           [UIFont systemFontOfSize:14.]
#define DATE_TEXT_FONT      [UIFont systemFontOfSize:9.]
#define MEDIA_TITLE_FONT    [UIFont systemFontOfSize:18.]

#define LEFT_EDGE_INSETS UIEdgeInsetsMake(35.f, 25.f, 12.f, 12.f)
#define RIGHT_EDGE_INSETS UIEdgeInsetsMake(35.f, 12.f, 12.f, 25.f)

#ifdef SHOW_AVATAR
    #define AVATAR_SIZE CGSizeMake(45.f, 45.f)
#endif

static CGFloat textMarginHorizontal     = 15.;
static CGFloat textMarginVertical       = 10.;

static CGFloat horizontalContentIndent  = 8.;

static CGFloat verticalContentIndent    = 8.;
static CGFloat verticalAvatarIndent     = 8.;

static CGFloat bubbleTextMaxWidth       = 200.;

static NSInteger clockImageHeight       = 9;
static NSInteger clockImageWidth        = 9;

@interface WDDChatMessageCell () <UIGestureRecognizerDelegate, OHAttributedLabelDelegate>

@property (nonatomic) UIImageView *baloonView;
@property (nonatomic) UIImageView *avatarView;
@property (nonatomic) UIImageView *clockImageView;

@property (nonatomic) OHAttributedLabel *messageTextLabel;
@property (nonatomic) UILabel *messageDateLabel;

@property (nonatomic) NSString *messageDate;

@end

@implementation WDDChatMessageCell

- (void)setupSubviews
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSDateFormatter * formatter=[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm a"];
    _messageDate = [formatter stringFromDate:self.message.timestamp];//[self.message.timestamp timeAgo];
    
#ifdef SHOW_AVATAR
    _avatarView = [UIImageView new];
    
    [self.contentView addSubview:self.avatarView];
#endif
    
    UIImage *bubbleImage = nil;
    UIColor *dateTextColor = nil;
    
    if( self.message.isOutgoing )
    {
        bubbleImage = [[UIImage imageNamed:@"bubbleMy"]
                       resizableImageWithCapInsets:RIGHT_EDGE_INSETS
                       resizingMode:UIImageResizingModeStretch];
        
        dateTextColor = [UIColor lightGrayColor];
    }
    else
    {
        NSString *bubleName = @"bubbleOther";
        bubbleImage = [[UIImage imageNamed:bubleName]
                       resizableImageWithCapInsets:LEFT_EDGE_INSETS
                       resizingMode:UIImageResizingModeStretch];
        
        dateTextColor = [UIColor lightGrayColor];
    }
    
    self.baloonView = [[UIImageView alloc] initWithImage:bubbleImage];

    [self.contentView addSubview:self.baloonView];
    
    if(!self.message.isComposing)
    {
        self.messageDateLabel = [UILabel new];
        self.messageDateLabel.backgroundColor = [UIColor clearColor];
        self.messageDateLabel.font = DATE_TEXT_FONT;
        self.messageDateLabel.textColor = dateTextColor;
        self.messageDateLabel.text = self.messageDate;
        self.messageDateLabel.text = [NSString stringWithFormat:@"%@ %@", self.messageDateLabel.text, [self.message.timestamp timeAgoFromToday]];
        
        //[self.baloonView addSubview:self.messageDateLabel];
        [self.contentView addSubview:self.messageDateLabel];
    }
    else
    {
        _messageTextLabel = [OHAttributedLabel new];
        
        self.messageTextLabel.backgroundColor = [UIColor clearColor];
        self.messageTextLabel.font = TEXT_FONT;
        self.messageTextLabel.numberOfLines = 0;
        self.messageTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        self.messageTextLabel.textColor = [UIColor blackColor];
        
        self.messageTextLabel.text = NSLocalizedString(@"lskIsTyping", @"is typing...");
        
        [self.baloonView.superview addSubview:self.messageTextLabel];
        
        return;
    }
    
    self.clockImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ClockImage"]];
    
    [self.contentView addSubview:self.clockImageView];
    
    _messageTextLabel = [OHAttributedLabel new];
    
    self.messageTextLabel.backgroundColor = [UIColor clearColor];
    self.messageTextLabel.font = TEXT_FONT;
    self.messageTextLabel.numberOfLines = 0;
    self.messageTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    self.messageTextLabel.textColor = [UIColor darkGrayColor];
    self.messageTextLabel.delegate = self;
    
    self.messageTextLabel.text = self.message.body;
    
    self.messageTextLabel.centerVertically = YES;
    
    [self.baloonView.superview addSubview:self.messageTextLabel];
}

- (void)layoutSubviews
{
    if (!self.message) return;      // iOS 6 apparently calls -layoutSubviews after -dequeueReusableCellWithIdentifier:forIndexPath:
    
    [super layoutSubviews];
    
    NSString *messageText = self.message.isComposing ? NSLocalizedString(@"lskIsTyping", @"is typing...") : self.message.body;
    
    CGSize textSize = [WDDChatMessageCell sizeForMessageText:messageText];
    CGFloat dateLabelWidth = [WDDChatMessageCell widthForOneLineText:self.messageDateLabel.text withFont:DATE_TEXT_FONT];
    
//    CGFloat bottomLineWidth = [WDDChatMessageCell widthForOneLineText:self.messageDate withFont:DATE_TEXT_FONT];
    
    CGSize baloonSize = CGSizeZero;
    
    //baloonSize = (CGSize){ MAX(textSize.width, bottomLineWidth) + textMarginHorizontal * 2 + horizontalContentIndent,
        //textSize.height + textMarginVertical * 2
    baloonSize = (CGSize){ 245.f, textSize.height + textMarginVertical * 2};
    CGFloat horizontalTextMargin = textMarginHorizontal;
    
    if(self.message.isOutgoing)
    {
#ifdef SHOW_AVATAR
        self.avatarView.frame = (CGRect){ [UIScreen mainScreen].bounds.size.width - AVATAR_SIZE.width - horizontalContentIndent,
            verticalAvatarIndent, AVATAR_SIZE
        };
        self.baloonView.frame = (CGRect){ CGRectGetMinX(self.avatarView.frame) - baloonSize.width - horizontalContentIndent,
            verticalContentIndent, baloonSize
        };
#else
        self.baloonView.frame = (CGRect){ [UIScreen mainScreen].bounds.size.width - horizontalContentIndent - baloonSize.width,
            verticalContentIndent, baloonSize
        };
#endif
        
        horizontalTextMargin -= horizontalContentIndent / 2.f;
    }
    else
    {
#ifdef SHOW_AVATAR
        self.avatarView.frame = (CGRect){ horizontalContentIndent, verticalAvatarIndent, AVATAR_SIZE };
#endif
        self.baloonView.frame = (CGRect){ CGRectGetMaxX(self.avatarView.frame) + horizontalContentIndent * 1.5f,
            verticalContentIndent, baloonSize
        };
        
        horizontalTextMargin += horizontalContentIndent / 2.f;
    }
#ifdef SHOW_AVATAR
    if(!self.avatarView.image)
    {
        self.avatarView.image = self.avatar;
        
        UIImageView *roundMaskImageView = [[UIImageView alloc] initWithFrame:(CGRect){CGPointZero, AVATAR_SIZE}];
        
        roundMaskImageView.image = [UIImage imageNamed:@"contactChatMask"];
        
        [self.avatarView addSubview:roundMaskImageView];
    }
#endif
    
    //self.messageTextLabel.frame = [self.baloonView.superview convertRect:(CGRect){ textMarginHorizontal, textMarginVertical, textSize } fromView:self.baloonView];
    
    self.messageTextLabel.frame = [self.baloonView.superview convertRect:(CGRect){ horizontalTextMargin, textMarginVertical, textSize.width, self.baloonView.frame.size.height - textMarginVertical*2} fromView:self.baloonView];
    if (!self.message.isOutgoing)
    {
        
        self.clockImageView.frame = (CGRect){ self.baloonView.frame.origin.x + self.baloonView.frame.size.width - dateLabelWidth - 17, self.baloonView.frame.origin.y + self.baloonView.frame.size.height + 1, clockImageWidth, clockImageHeight};
        self.messageDateLabel.frame = (CGRect){ self.baloonView.frame.origin.x + self.baloonView.frame.size.width - dateLabelWidth - 5, self.baloonView.frame.origin.y + self.baloonView.frame.size.height, dateLabelWidth, DATE_TEXT_FONT.lineHeight};
    }
    else
    {
        self.clockImageView.frame = (CGRect){ self.baloonView.frame.origin.x, self.baloonView.frame.origin.y + self.baloonView.frame.size.height + 1, clockImageWidth, clockImageHeight};
        
        self.messageDateLabel.frame = (CGRect){ self.baloonView.frame.origin.x + 15, self.baloonView.frame.origin.y + self.baloonView.frame.size.height, dateLabelWidth, DATE_TEXT_FONT.lineHeight};
    }
}

- (void)prepareForReuse
{
    self.messageTextLabel.delegate = nil;
    self.message = nil;
    [self.contentView.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
        [subview removeFromSuperview];
    }];
    [super prepareForReuse];
}

#pragma mark - Sizes calculation

+ (NSAttributedString*)attributedStringForString:(NSString*)text
{
    NSMutableAttributedString *attributedString
    = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:TEXT_FONT}];
        
    NSError *error;
    
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
    
    NSArray *links = [detector matchesInString:text options:NSMatchingReportCompletion range:NSMakeRange(0, text.length)];
    
    [links enumerateObjectsUsingBlock:^(NSTextCheckingResult *link, NSUInteger idx, BOOL *stop)
     {
         [attributedString addAttribute:NSLinkAttributeName value:[NSURL URLWithString:[text substringWithRange:link.range]] range:link.range];
     }];
    
    return attributedString;
}

+ (CGSize)sizeForMessageText:(NSString *)text
{
    CGSize size = CGSizeZero;
    NSAttributedString *string = [self attributedStringForString:text];
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)string);
    if (framesetter)
    {
        CGSize targetSize = CGSizeMake(bubbleTextMaxWidth, INFINITY);
        size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [string length]), NULL, targetSize, NULL);
        CFRelease(framesetter);
    }
    
    size.height = ceil(size.height) + 1.0f;
    size.width  = ceil(size.width) + 1.0f;
    
    return size;
}

+ (CGFloat)widthForOneLineText:(NSString *)text withFont:(UIFont *)font
{
    return [text sizeWithFont:font
            constrainedToSize:CGSizeMake(CGFLOAT_MAX, font.lineHeight)
                lineBreakMode:NSLineBreakByWordWrapping].width;
}

+ (CGFloat)heightForCellWithText:(NSString *)text
{
    if( !text.length )
    {
        return 105.;// TODO: correct height calculation
    }
    else
    {
        CGSize textSize = [WDDChatMessageCell sizeForMessageText:text];
        DLog(@"Text size: %f, %f", textSize.width, textSize.height);
        
        CGFloat height = textSize.height + textMarginVertical * 2 + verticalContentIndent * 2 + DATE_TEXT_FONT.lineHeight;
        return height;
    }
}

#pragma mark - TTTAttributedLabelDelegate

- (BOOL)attributedLabel:(OHAttributedLabel*)attributedLabel shouldFollowLink:(NSTextCheckingResult*)linkInfo;
{
    return YES;
}

@end
