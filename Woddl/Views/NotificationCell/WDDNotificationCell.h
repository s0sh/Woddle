//
//  WDDNotificationCell.h
//  Woddl
//

#import <UIKit/UIKit.h>

@class Notification;

@interface WDDNotificationCell : UITableViewCell

- (void)setNotification:(Notification*)notification;
- (void)blinkUnreadShield;

@property (nonatomic, assign) BOOL expanded;

@end
