//
//  Notification.h
//  Woddl
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SocialNetwork;
@class Group;
@class Post;
@class Media;
@class UserProfile;

@interface Notification : NSManagedObject

@property (nonatomic, retain) NSString *notificationId;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * iconURL;
@property (nonatomic, retain) NSNumber * isUnread;
@property (nonatomic, retain) NSString * externalURL;
@property (nonatomic, retain) NSString * externalObjectId;
@property (nonatomic, retain) NSString * externalObjectType;
@property (nonatomic, retain) NSString * senderId;
@property (nonatomic, retain) SocialNetwork *socialNetwork;
@property (nonatomic, retain) Group *group;
@property (nonatomic, retain) Post *post;
@property (nonatomic, retain) Media *media;
@property (nonatomic, retain) UserProfile *sender;

- (void)markAsRead;

@property (nonatomic, assign) BOOL isMarkingAsRead;

@end
