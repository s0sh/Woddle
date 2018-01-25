//
//  WYPopoverTheme+WDDNotifications.m
//  Woddl
//

#import "WYPopoverTheme+WDDNotifications.h"
#import <objc/runtime.h>

char * const themeArrowBaseOffsetKey    = "themeArrowBaseOffsetKey";
char * const themeArrowHeightOffsetKey  = "themeArrowHeightOffsetKey";
char * const themeStrokeWidthKey        = "themeStrokeWidthKey";

@implementation WYPopoverTheme (WDDNotifications)

- (CGFloat)arrowBaseOffset
{
    return [objc_getAssociatedObject(self, themeArrowBaseOffsetKey) floatValue];
}

- (void)setArrowBaseOffset:(CGFloat)arrowBaseOffset
{
    objc_setAssociatedObject(self, themeArrowBaseOffsetKey, @(arrowBaseOffset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)arrowHeightOffset
{
    return [objc_getAssociatedObject(self, themeArrowHeightOffsetKey) floatValue];
}

- (void)setArrowHeightOffset:(CGFloat)arrowHeightOffset
{
    objc_setAssociatedObject(self, themeArrowHeightOffsetKey, @(arrowHeightOffset), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)strokeWidth
{
    return [objc_getAssociatedObject(self, themeStrokeWidthKey) floatValue];
}

- (void)setStrokeWidth:(CGFloat)strokeWidth
{
    objc_setAssociatedObject(self, themeStrokeWidthKey, @(strokeWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
