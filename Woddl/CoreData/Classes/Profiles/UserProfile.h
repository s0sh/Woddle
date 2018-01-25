//
//  UserProfile.h
//  Woddl
//
//  Created by Sergii Gordiienko on 02.12.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SocialNetwork.h"

@class Comment, Post, SocialNetwork, Group, Notification;

@interface UserProfile : NSManagedObject

@property (nonatomic, retain) NSString * avatarRemoteURL;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * profileURL;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSNumber * isBlocked;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *likedComments;
@property (nonatomic, retain) NSSet *posts;
@property (nonatomic, retain) SocialNetwork *socialNetwork;
@property (nonatomic, retain) NSSet *subscribedPosts;
@property (nonatomic, retain) NSSet *likedPosts;
@property (nonatomic, retain) NSSet *manageGroups;
@property (nonatomic, retain) NSSet *sentNotifications;
@end

@interface UserProfile (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addLikedCommentsObject:(Comment *)value;
- (void)removeLikedCommentsObject:(Comment *)value;
- (void)addLikedComments:(NSSet *)values;
- (void)removeLikedComments:(NSSet *)values;

- (void)addPostsObject:(Post *)value;
- (void)removePostsObject:(Post *)value;
- (void)addPosts:(NSSet *)values;
- (void)removePosts:(NSSet *)values;

- (void)addSubscribedPostsObject:(Post *)value;
- (void)removeSubscribedPostsObject:(Post *)value;
- (void)addSubscribedPosts:(NSSet *)values;
- (void)removeSubscribedPosts:(NSSet *)values;

- (void)addLikedPostsObject:(Post *)value;
- (void)removeLikedPostsObject:(Post *)value;
- (void)addLikedPosts:(NSSet *)values;
- (void)removeLikedPosts:(NSSet *)values;

- (void)addManageGroupsObject:(Group *)value;
- (void)removeManageGroupsObject:(Group *)value;
- (void)addManageGroups:(NSSet *)values;
- (void)removeManageGroups:(NSSet *)values;

- (void)addSentNotificationsObject:(Notification *)value;
- (void)removeSentNotificationsObject:(Notification *)value;
- (void)addSentNotifications:(NSSet *)values;
- (void)removeSentNotifications:(NSSet *)values;

//  Custom method
- (NSString *)socialNetworkIconName;

@end
