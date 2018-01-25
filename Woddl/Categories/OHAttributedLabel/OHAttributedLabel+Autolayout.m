//
//  OHAttributedLabel+Autolayout.m
//  Woddl
//

#import "OHAttributedLabel+Autolayout.h"

@implementation OHAttributedLabel (Autolayout)

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize
{
    CGSize fitSize = CGSizeZero;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)[self attributedText]);
    if (framesetter)
    {
        CGSize targetSize = CGSizeMake(300.0f, INFINITY);
        fitSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, [self.attributedText length]), NULL, targetSize, NULL);
        CFRelease(framesetter);
    }
    return fitSize;
}

- (CGSize)intrinsicContentSize
{
    return [super intrinsicContentSize];
    return [self systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

@end
