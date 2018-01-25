//
//  UIViewController+NavbarLogo.h
//  Woddl
//

#import <UIKit/UIKit.h>

#define NOTIFICATIONS_BADGE_WIDTH   24
#define NOTIFICATIONS_BADGE_HEIGHT  14

@class WYPopoverController;

@interface UIViewController (NavbarLogo)

- (void)setupNavigationBarTitle;

@property (nonatomic, strong) WYPopoverController *notificationsPopover;

@end
