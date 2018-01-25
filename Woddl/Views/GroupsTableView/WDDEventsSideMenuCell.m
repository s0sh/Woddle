//
//  WDDEventsSideMenuCell.m
//  Woddl
//
//  Created by Sergii Gordiienko on 09.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "WDDEventsSideMenuCell.h"

static const CGFloat kEventWidth = 215.0f;
static const CGFloat kVerticalOffset = 4.0f;

@implementation WDDEventsSideMenuCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.eventInformationLabel.extendBottomToFit = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self resetViews];
}

- (void)resetViews
{
    self.eventInformationLabel.text = nil;
}

#pragma mark - Static method for size calculation

+ (CGFloat)calculateCellHeightForText:(NSString *)text
{
    CGSize textSize = CGSizeZero;
    CGFloat cellHeight = 0;
    
    NSString *preview = text;
    NSRange previewRange = [preview rangeOfString:@"\n"];
    if (previewRange.location != NSNotFound)
    {
        preview = [preview substringToIndex:previewRange.location];
    }
    
    if (preview.length)
    {
        textSize = [self sizeForText:preview withFont:self.messageTextFont];
    }
    
    cellHeight = textSize.height + 2*kVerticalOffset;
    
    return cellHeight;
}

+ (CGSize)sizeForText:(id)text withFont:(UIFont *)font
{
    CGSize textSize;
    if (!IS_IOS7)
    {
        NSString *textString = [text isKindOfClass:[NSAttributedString class]] ? [text string] : text;
        
        textSize = [textString sizeWithFont:font constrainedToSize:CGSizeMake(kEventWidth, INFINITY) lineBreakMode:NSLineBreakByWordWrapping];
    }
    else
    {
        if ([text isKindOfClass:[NSAttributedString class]])
        {
            textSize = [(NSAttributedString *)text boundingRectWithSize:CGSizeMake(kEventWidth, INFINITY)
                                                                options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                                context:nil].size;
        }
        else
        {
            textSize = [(NSString *)text boundingRectWithSize:CGSizeMake(kEventWidth, INFINITY)
                                                      options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:@{UITextAttributeFont : font}
                                                      context:nil].size;
        }
    }
    
    //  KOSTYL: Wrong calculation of bondingRectWithSize, especialy for arabic founts
    if (textSize.height < 20.0f)
    {
        textSize.height = 20.0f;
    }
    return textSize;
}

+ (UIFont *)messageTextFont
{
    return [UIFont systemFontOfSize:kPostFontSize];
}

@end
