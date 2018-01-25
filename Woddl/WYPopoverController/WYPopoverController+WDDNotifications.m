//
//  WYPopoverController+WDDNotifications.m
//  Woddl
//

#import "WYPopoverController+WDDNotifications.h"
#import <objc/runtime.h>

IMP updateThemeUIOriginal;
Ivar backgroundViewIvar;

@interface WYPopoverController (MakePrivatePublic)

@property (nonatomic, strong) WYPopoverBackgroundView *backgroundView;

@end

@implementation WYPopoverController (WDDNotifications)

+ (void)load
{
    Class class = [self class];
    
    IMP categoryImplementation = class_getMethodImplementation(class, @selector(updateThemeUI));
    
    unsigned int count;
    
    class_copyMethodList(class, &count);
    
    Method *methodlist = malloc(sizeof(Method) * count);
    
    methodlist = class_copyMethodList(class, NULL);
    
    for (int i = 0; i < count; i++)
    {
        SEL sel  = method_getName(methodlist[i]);
        IMP impl = method_getImplementation(methodlist[i]);
        
        if (sel == @selector(updateThemeUI) && impl != categoryImplementation)
        {
            updateThemeUIOriginal = impl;
            break;
        }
    }
    
    free(methodlist);
    
    backgroundViewIvar = class_getInstanceVariable(class, "backgroundView");
}

- (void)updateThemeUI
{
    self.backgroundView.arrowBaseOffset     = self.theme.arrowBaseOffset;
    self.backgroundView.arrowHeightOffset   = self.theme.arrowHeightOffset;
    self.backgroundView.strokeWidth         = self.theme.strokeWidth;
    updateThemeUIOriginal(self, _cmd);
}

- (UIView*)backgroundView
{
    return object_getIvar(self, backgroundViewIvar);
}

@end
