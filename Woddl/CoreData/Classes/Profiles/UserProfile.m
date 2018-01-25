//
//  UserProfile.m
//  Woddl
//
//  Created by Sergii Gordiienko on 02.12.13.
//
//

#import "UserProfile.h"
#import "Comment.h"
#import "Post.h"
#import "SocialNetwork.h"


@implementation UserProfile

@dynamic avatarRemoteURL;
@dynamic name;
@dynamic profileURL;
@dynamic userID;
@dynamic isBlocked;
@dynamic comments;
@dynamic likedComments;
@dynamic posts;
@dynamic socialNetwork;
@dynamic subscribedPosts;
@dynamic manageGroups;
@dynamic likedPosts;
@dynamic sentNotifications;

- (void)prepareForDeletion
{
    if (self.avatarRemoteURL)
    {
        if (![self.avatarRemoteURL hasPrefix:@"http"])
        {
            [[NSFileManager defaultManager] removeItemAtPath:self.avatarRemoteURL error:nil];
        }
    }
    [super prepareForDeletion];
}

- (NSString *)socialNetworkIconName
{
    NSAssert(![self isKindOfClass:[Post class]], @"This is abstract class. Method should be overloaded by subclass");
    return nil;
}

@end
