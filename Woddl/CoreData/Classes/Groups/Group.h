//
//  Group.h
//  Woddl
//
//  Created by Sergii Gordiienko on 27.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


typedef NS_ENUM(NSInteger, GroupType)
{
    kGroupTypeUnknown = 0,
    kGroupTypePage,
    kGroupTypeGroup
};


@class Post, SocialNetwork, UserProfile, Notification;

@interface Group : NSManagedObject

@property (nonatomic, retain) NSString * groupID;
@property (nonatomic, retain) NSString * groupURL;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSNumber * isGroupBlock;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSSet *members;
@property (nonatomic, retain) NSSet *posts;
@property (nonatomic, retain) NSSet *managedBy;
@property (nonatomic, retain) NSSet *notifications;
@end

@interface Group (CoreDataGeneratedAccessors)

- (void)addMembersObject:(SocialNetwork *)value;
- (void)removeMembersObject:(SocialNetwork *)value;
- (void)addMembers:(NSSet *)values;
- (void)removeMembers:(NSSet *)values;

- (void)addPostsObject:(Post *)value;
- (void)removePostsObject:(Post *)value;
- (void)addPosts:(NSSet *)values;
- (void)removePosts:(NSSet *)values;

- (void)addManagedByObject:(UserProfile *)value;
- (void)removeManagedByObject:(UserProfile *)value;
- (void)addManagedBy:(NSSet *)values;
- (void)removeManagedBy:(NSSet *)values;

- (void)addNotificationsObject:(Notification *)value;
- (void)removeNotificationsObject:(Notification *)value;
- (void)addNotifications:(NSSet *)values;
- (void)removeNotifications:(NSSet *)values;

@end
