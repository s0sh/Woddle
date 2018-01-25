//
//  UIViewController+NavbarLogo.m
//  Woddl
//

#import "UIViewController+NavbarLogo.h"
#import "WDDNotificationsViewController.h"
#import "WDDDataBase.h"
#import <BTBadgeView/BTBadgeView.h>
#import <objc/runtime.h>

char * const notificationsPopoverKey = "notificationsPopover";
NSMutableDictionary *observerMap;

@implementation UIViewController (NavbarLogo)

+ (void)load
{
    observerMap = [NSMutableDictionary new];
}

- (void)setupNavigationBarTitle
{
    UIButton    *button     = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage     *image      = [UIImage imageNamed:@"MainScreen_nav_bar_logo"];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                 0,
                                                                 image.size.width   + NOTIFICATIONS_BADGE_WIDTH * 2,
                                                                 image.size.height  + NOTIFICATIONS_BADGE_HEIGHT)];
    
    [button setFrame:CGRectMake(NOTIFICATIONS_BADGE_WIDTH,
                                NOTIFICATIONS_BADGE_HEIGHT / 2,
                                image.size.width,
                                image.size.height)];
    
    [button setBackgroundImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(navbarLogoTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    BTBadgeView *badgeView = [[BTBadgeView alloc] initWithFrame:CGRectMake(image.size.width + NOTIFICATIONS_BADGE_WIDTH * 0.75 - 2,
                                                                           NOTIFICATIONS_BADGE_HEIGHT / 2 - 2,
                                                                           NOTIFICATIONS_BADGE_WIDTH * 0.75,
                                                                           NOTIFICATIONS_BADGE_HEIGHT)];
    
    [badgeView setStrokeColor:[UIColor whiteColor]];
    [badgeView setFillColor:[UIColor redColor]];
    [badgeView setTextColor:[UIColor whiteColor]];
    [badgeView setStrokeWidth:1.0f];
    [badgeView setHideWhenEmpty:YES];
    [badgeView setShadow:NO];
    [badgeView setShine:NO];
    [badgeView setFont:[UIFont boldSystemFontOfSize:8.0f]];
    
    [self setupNotificationsBadgeValue:badgeView withImageWidth:image.size.width shouldUpdateAfter:NO];
    
    [titleView addSubview:button];
    [titleView addSubview:badgeView];
    
    [titleView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navbarLogoTapped:)]];
    
    self.navigationItem.titleView = titleView;
    
    __weak typeof (self) weakSelf = self;
    NSString *uuid = [[NSUUID UUID] UUIDString];
    
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:kNotificationNotificationsDidUpdate
                                                                    object:nil
                                                                     queue:[NSOperationQueue mainQueue]
                                                                usingBlock:^(NSNotification *note)
    {
        if (!weakSelf)
        {
            [[NSNotificationCenter defaultCenter] removeObserver:observerMap[uuid]];
            [observerMap removeObjectForKey:uuid];
        }
        [weakSelf setupNotificationsBadgeValue:badgeView withImageWidth:image.size.width shouldUpdateAfter:NO];
    }];
    
    observerMap[uuid] = observer;
}

#pragma mark - actions

- (void)navbarLogoTapped:(id)sender
{
    [WDDNotificationsViewController showOnViewController:self];
}

#pragma mark - setter/getter

- (void)setNotificationsPopover:(WYPopoverController *)notificationsPopover
{
    objc_setAssociatedObject(self, notificationsPopoverKey, notificationsPopover, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (WYPopoverController*)notificationsPopover
{
    return objc_getAssociatedObject(self, notificationsPopoverKey);
}

#pragma mark - helper

- (void)setupNotificationsBadgeValue:(BTBadgeView * __weak)badge withImageWidth:(CGFloat)width
{
    [self setupNotificationsBadgeValue:badge withImageWidth:width shouldUpdateAfter:YES];
}

- (void)setupNotificationsBadgeValue:(BTBadgeView * __weak)badge withImageWidth:(CGFloat)width shouldUpdateAfter:(BOOL)shouldUpdateAfter
{
    if (![WDDDataBase isConnectedToDB]) return;
    NSUInteger badgeBalue = [self countUnreadNotifications];
    NSString *badgeString;
    if (badgeBalue <= 99)
    {
        badgeString = [@(badgeBalue) stringValue];
    }
    else
    {
        badgeString = @"99+";
    }
    badge.frame = CGRectMake(width + NOTIFICATIONS_BADGE_WIDTH * 0.75 - 2,
                             NOTIFICATIONS_BADGE_HEIGHT / 2 - 2,
                             NOTIFICATIONS_BADGE_WIDTH * ((badgeString.length + 2) * 0.25),
                             NOTIFICATIONS_BADGE_HEIGHT);
    badge.value = badgeString;
    
    if (shouldUpdateAfter)
    {
        __weak typeof (self) weakSelf   = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^()
        {
           [weakSelf setupNotificationsBadgeValue:badge withImageWidth:width];
        });
    }
}

- (NSUInteger)countUnreadNotifications
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Notification class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isUnread == TRUE"];
    return [[[WDDDataBase sharedDatabase] managedObjectContext] countForFetchRequest:fetchRequest error:nil];
}

@end
