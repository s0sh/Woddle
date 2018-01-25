//
//  Notification.m
//  Woddl
//

#import "Notification.h"
#import "SocialNetwork.h"

@implementation Notification

@dynamic notificationId;
@dynamic date;
@dynamic title;
@dynamic body;
@dynamic iconURL;
@dynamic isUnread;
@dynamic externalURL;
@dynamic externalObjectId;
@dynamic externalObjectType;
@dynamic senderId;
@dynamic socialNetwork;
@dynamic group;
@dynamic post;
@dynamic media;
@dynamic sender;

@synthesize isMarkingAsRead;

- (void)markAsRead
{
    if ([self.socialNetwork respondsToSelector:@selector(markNotificationAsRead:)] &&
        self.socialNetwork.activeState.boolValue &&
        self.isUnread.boolValue &&
        !self.isMarkingAsRead)
    {
        self.isMarkingAsRead = YES;
        [self.socialNetwork markNotificationAsRead:self];
    }
}

@end
