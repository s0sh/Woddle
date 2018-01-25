//
//  WYPopoverBackgroundView+WDDNotifications.m
//  Woddl
//

#import "WYPopoverBackgroundView+WDDNotifications.h"
#import <objc/runtime.h>

char * const backgroundArrowBaseOffsetKey       = "backgroundArrowBaseOffsetKey";
char * const backgroundArrowHeightOffsetKey     = "backgroundArrowHeightOffsetKey";
char * const backgroundStrokeWidthKey           = "backgroundStrokeWidthKey";

@interface WYPopoverBackgroundView (MakePrivatePublic)

@property (nonatomic, assign) WYPopoverArrowDirection arrowDirection;
@property (nonatomic, assign) CGFloat arrowOffset;
@property (nonatomic, assign) CGFloat arrowBase;
@property (nonatomic, assign) CGFloat arrowHeight;
@property (nonatomic, assign) CGFloat outerCornerRadius;
@property (nonatomic, assign) CGFloat outerShadowBlurRadius;
@property (nonatomic, strong) UIColor *outerShadowColor;
@property (nonatomic, assign) CGFloat glossShadowOffset;
@property (nonatomic, assign) CGFloat glossShadowBlurRadius;

- (CGRect)outerRect:(CGRect)rect arrowDirection:(WYPopoverArrowDirection)arrowDirection;

@end

@implementation WYPopoverBackgroundView (WDDNotifications)

#pragma mark - draw

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    if ([layer.name isEqualToString:@"parent"])
    {
        UIGraphicsPushContext(context);
        //CGContextSetShouldAntialias(context, YES);
        //CGContextSetAllowsAntialiasing(context, YES);
        
        //// General Declarations
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        //// Gradient Declarations
        NSArray* fillGradientColors = [NSArray arrayWithObjects:
                                       (id)self.fillTopColor.CGColor,
                                       (id)self.fillBottomColor.CGColor, nil];
        CGFloat fillGradientLocations[] = {0, 1};
        CGGradientRef fillGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)fillGradientColors, fillGradientLocations);
        
        // Frames
        CGRect rect = self.bounds;
        
        CGRect outerRect = [self outerRect:rect arrowDirection:self.arrowDirection];
        outerRect = CGRectInset(outerRect, 0.5, 0.5);
        
        // Inner Path
        CGMutablePathRef outerPathRef = CGPathCreateMutable();
        
        CGPoint origin = CGPointZero;
        
        CGFloat reducedOuterCornerRadius = 0;
        
        if (self.arrowDirection == WYPopoverArrowDirectionUp || self.arrowDirection == WYPopoverArrowDirectionDown)
        {
            if (self.arrowOffset >= 0)
            {
                reducedOuterCornerRadius = CGRectGetMaxX(outerRect) - (CGRectGetMidX(outerRect) + self.arrowOffset + self.arrowBase / 2);
            }
            else
            {
                reducedOuterCornerRadius = (CGRectGetMidX(outerRect) + self.arrowOffset - self.arrowBase / 2) - CGRectGetMinX(outerRect);
            }
        }
        else if (self.arrowDirection == WYPopoverArrowDirectionLeft || self.arrowDirection == WYPopoverArrowDirectionRight)
        {
            if (self.arrowOffset >= 0)
            {
                reducedOuterCornerRadius = CGRectGetMaxY(outerRect) - (CGRectGetMidY(outerRect) + self.arrowOffset + self.arrowBase / 2);
            }
            else
            {
                reducedOuterCornerRadius = (CGRectGetMidY(outerRect) + self.arrowOffset - self.arrowBase / 2) - CGRectGetMinY(outerRect);
            }
        }
        
        reducedOuterCornerRadius = MIN(reducedOuterCornerRadius, self.outerCornerRadius);
        
        if (self.arrowDirection == WYPopoverArrowDirectionUp)
        {
            origin = CGPointMake(CGRectGetMidX(outerRect) + self.arrowOffset + self.arrowBaseOffset - self.arrowBase / 2, CGRectGetMinY(outerRect));
            
            CGPathMoveToPoint(outerPathRef, NULL, origin.x, origin.y);
            
            CGPathAddLineToPoint(outerPathRef, NULL, CGRectGetMidX(outerRect) + self.arrowOffset + self.arrowHeightOffset, CGRectGetMinY(outerRect) - self.arrowHeight);
            CGPathAddLineToPoint(outerPathRef, NULL, CGRectGetMidX(outerRect) + self.arrowOffset + self.arrowBaseOffset + self.arrowBase / 2, CGRectGetMinY(outerRect));
            
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect), (self.arrowOffset >= 0) ? reducedOuterCornerRadius :self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect),self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMinY(outerRect),self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect), (self.arrowOffset < 0) ? reducedOuterCornerRadius :self.outerCornerRadius);
            
            CGPathAddLineToPoint(outerPathRef, NULL, origin.x, origin.y);
        }
        
        if (self.arrowDirection == WYPopoverArrowDirectionDown)
        {
            origin = CGPointMake(CGRectGetMidX(outerRect) + self.arrowOffset + self.arrowBase / 2, CGRectGetMaxY(outerRect));
            
            CGPathMoveToPoint(outerPathRef, NULL, origin.x, origin.y);
            
            CGPathAddLineToPoint(outerPathRef, NULL, CGRectGetMidX(outerRect) + self.arrowOffset, CGRectGetMaxY(outerRect) + self.arrowHeight);
            CGPathAddLineToPoint(outerPathRef, NULL, CGRectGetMidX(outerRect) + self.arrowOffset - self.arrowBase / 2, CGRectGetMaxY(outerRect));
            
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMinY(outerRect), (self.arrowOffset < 0) ? reducedOuterCornerRadius :self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect),self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect),self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect), (self.arrowOffset >= 0) ? reducedOuterCornerRadius :self.outerCornerRadius);
            
            CGPathAddLineToPoint(outerPathRef, NULL, origin.x, origin.y);
        }
        
        if (self.arrowDirection == WYPopoverArrowDirectionLeft)
        {
            origin = CGPointMake(CGRectGetMinX(outerRect), CGRectGetMidY(outerRect) + self.arrowOffset + self.arrowBase / 2);
            
            CGPathMoveToPoint(outerPathRef, NULL, origin.x, origin.y);
            
            CGPathAddLineToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect) - self.arrowHeight, CGRectGetMidY(outerRect) + self.arrowOffset);
            CGPathAddLineToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect), CGRectGetMidY(outerRect) + self.arrowOffset - self.arrowBase / 2);
            
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect), (self.arrowOffset < 0) ? reducedOuterCornerRadius :self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect),self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect),self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMinY(outerRect), (self.arrowOffset >= 0) ? reducedOuterCornerRadius :self.outerCornerRadius);
            
            CGPathAddLineToPoint(outerPathRef, NULL, origin.x, origin.y);
        }
        
        if (self.arrowDirection == WYPopoverArrowDirectionRight)
        {
            origin = CGPointMake(CGRectGetMaxX(outerRect), CGRectGetMidY(outerRect) + self.arrowOffset - self.arrowBase / 2);
            
            CGPathMoveToPoint(outerPathRef, NULL, origin.x, origin.y);
            
            CGPathAddLineToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect) + self.arrowHeight, CGRectGetMidY(outerRect) + self.arrowOffset);
            CGPathAddLineToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMidY(outerRect) + self.arrowOffset + self.arrowBase / 2);
            
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect), (self.arrowOffset >= 0) ? reducedOuterCornerRadius :self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMinY(outerRect),self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect),self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect), (self.arrowOffset < 0) ? reducedOuterCornerRadius :self.outerCornerRadius);
            
            CGPathAddLineToPoint(outerPathRef, NULL, origin.x, origin.y);
        }
        
        if (self.arrowDirection == WYPopoverArrowDirectionNone)
        {
            origin = CGPointMake(CGRectGetMaxX(outerRect), CGRectGetMidY(outerRect));
            
            CGPathMoveToPoint(outerPathRef, NULL, origin.x, origin.y);
            
            CGPathAddLineToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMidY(outerRect));
            CGPathAddLineToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMidY(outerRect));
            
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect),self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect), CGRectGetMaxY(outerRect), CGRectGetMinX(outerRect), CGRectGetMinY(outerRect),self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMinX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect),self.outerCornerRadius);
            CGPathAddArcToPoint(outerPathRef, NULL, CGRectGetMaxX(outerRect), CGRectGetMinY(outerRect), CGRectGetMaxX(outerRect), CGRectGetMaxY(outerRect),self.outerCornerRadius);
            
            CGPathAddLineToPoint(outerPathRef, NULL, origin.x, origin.y);
        }
        
        CGPathCloseSubpath(outerPathRef);
        
        UIBezierPath* outerRectPath = [UIBezierPath bezierPathWithCGPath:outerPathRef];
        
        CGContextSaveGState(context);
        {
            CGContextSetShadowWithColor(context, self.outerShadowOffset, self.outerShadowBlurRadius, self.outerShadowColor.CGColor);
            CGContextBeginTransparencyLayer(context, NULL);
            [outerRectPath addClip];
            CGRect outerRectBounds = CGPathGetPathBoundingBox(outerRectPath.CGPath);
            CGContextDrawLinearGradient(context, fillGradient,
                                        CGPointMake(CGRectGetMidX(outerRectBounds), CGRectGetMinY(outerRectBounds)),
                                        CGPointMake(CGRectGetMidX(outerRectBounds), CGRectGetMaxY(outerRectBounds)),
                                        0);
            CGContextEndTransparencyLayer(context);
        }
        CGContextRestoreGState(context);
        
        ////// outerRect Inner Shadow
        CGRect outerRectBorderRect = CGRectInset([outerRectPath bounds], -self.glossShadowBlurRadius, -self.glossShadowBlurRadius);
        outerRectBorderRect = CGRectOffset(outerRectBorderRect, -self.glossShadowOffset.width, -self.glossShadowOffset.height);
        outerRectBorderRect = CGRectInset(CGRectUnion(outerRectBorderRect, [outerRectPath bounds]), -1, -1);
        
        UIBezierPath* outerRectNegativePath = [UIBezierPath bezierPathWithRect: outerRectBorderRect];
        [outerRectNegativePath appendPath: outerRectPath];
        outerRectNegativePath.usesEvenOddFillRule = YES;
        
        CGContextSaveGState(context);
        {
            CGFloat xOffset = self.glossShadowOffset.width + round(outerRectBorderRect.size.width);
            CGFloat yOffset = self.glossShadowOffset.height;
            CGContextSetShadowWithColor(context,
                                        CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)),
                                        self.glossShadowBlurRadius,
                                        self.glossShadowColor.CGColor);
            
            [outerRectPath addClip];
            CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(outerRectBorderRect.size.width), 0);
            [outerRectNegativePath applyTransform: transform];
            [[UIColor grayColor] setFill];
            [outerRectNegativePath fill];
        }
        CGContextRestoreGState(context);
        
        [self.outerStrokeColor setStroke];
        outerRectPath.lineWidth = self.strokeWidth;
        [outerRectPath stroke];
        
        //// Cleanup
        CFRelease(outerPathRef);
        CGGradientRelease(fillGradient);
        CGColorSpaceRelease(colorSpace);
        
        UIGraphicsPopContext();
    }
}

#pragma mark - getter/setter

- (CGFloat)arrowBaseOffset
{
    return [objc_getAssociatedObject(self, backgroundArrowBaseOffsetKey) floatValue];
}

- (void)setArrowBaseOffset:(CGFloat)arrowBaseOffset
{
    objc_setAssociatedObject(self, backgroundArrowBaseOffsetKey, @(arrowBaseOffset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)arrowHeightOffset
{
    return [objc_getAssociatedObject(self, backgroundArrowHeightOffsetKey) floatValue];
}

- (void)setArrowHeightOffset:(CGFloat)arrowHeightOffset
{
    objc_setAssociatedObject(self, backgroundArrowHeightOffsetKey, @(arrowHeightOffset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)strokeWidth
{
    return [objc_getAssociatedObject(self, backgroundStrokeWidthKey) floatValue];
}

- (void)setStrokeWidth:(CGFloat)strokeWidth
{
    objc_setAssociatedObject(self, backgroundStrokeWidthKey, @(strokeWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
