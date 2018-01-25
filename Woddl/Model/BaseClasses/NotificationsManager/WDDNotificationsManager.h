//
//  WDDNotificationsManager.h
//  Woddl
//

#import <Foundation/Foundation.h>

@interface WDDNotificationsManager : NSObject

+ (instancetype)sharedManager;
- (void)disconnectFromDB;
- (void)fetchNotifications;
- (NSFetchedResultsController*)notificationsFRC;

@end
