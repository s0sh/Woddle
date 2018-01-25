//
//  SocialNetwork.h
//  Woddl
//
//  Created by Sergii Gordiienko on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "UserProfile.h"
#import "WDDConstants.h"
#import "Post.h"
#import "WDDLocation.h"
#import "Group.h"
#import "Notification.h"

static NSInteger kGetPostLimit = 10;

typedef void (^ComplationGetPostBlock)(NSError* error);
typedef void (^ComplationPostBlock)(NSError* error);
typedef void (^completionAddStatusBlock)(NSError* error);
typedef void (^completionSearchPostsBlock)(NSError* error);
typedef void (^completionRefreshGroupsBlock)(void);

@class PFObject;

@protocol SocialNetworkNetworkCommunication<NSObject>
@required
+ (NSString *)baseURL;
@end

@interface SocialNetwork : NSManagedObject <SocialNetworkNetworkCommunication>

@property (nonatomic, retain) NSString * accessToken;
@property (nonatomic, retain) NSNumber * activeState;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) UserProfile * profile;
@property (nonatomic, retain) NSDate * exspireTokenTime;
@property (nonatomic, retain) NSSet* groups;
@property (nonatomic, retain) NSSet* notifications;

@property (nonatomic, retain) NSNumber * isEventsEnabled;
@property (nonatomic, retain) NSNumber * isGroupsEnabled;
@property (nonatomic, retain) NSNumber * isPagesEnabled;
@property (nonatomic, retain) NSDate * updatedAt;

@property (nonatomic, readonly) NSDictionary *syncResources;

+ (dispatch_queue_t) networkQueue;
+ (NSOperationQueue *) operationQueue;
+ (AFHTTPClient *) socialNetworkHTTPClient;

- (NSString *)socialNetworkIconName;

- (void)setTypeWith:(SocialNetworkType)type;
- (SocialNetworkType)socialNetworkType;

- (void)setExspireTokenTimeWithExpireTimeInterval:(NSTimeInterval)timeInterval;

- (void)getPosts;
- (void)getPostsWithCompletionBlock:(ComplationGetPostBlock)completionBlock;
- (void)getPostsFrom:(NSString*)from to:(NSString*)to isSelfPosts:(BOOL)isSelf;

- (void)fetchNotifications;
- (void)markNotificationAsRead:(Notification*)notification;

- (void)loadMoreGroupsPostsWithGroupID:(NSString *)groupID from:(NSString *)from to:(NSString *)to;

- (void)searchPostsWithText:(NSString *)searchText;
- (void)searchPostsWithText:(NSString *)searchText completionBlock:(completionSearchPostsBlock)comletionBlock;

- (void)postToWallWithMessage:(NSString*)message
                      andPost:(Post*)post
          withCompletionBlock:(ComplationPostBlock)completionBlock;
- (void)postToWallWithMessage:(NSString *)message
                         post:(Post *)post
                      toGroup:(Group *)group
          withCompletionBlock:(ComplationPostBlock)completionBlock;

- (void)addStatusWithMessage:(NSString*)message
                   andImages:(NSArray*)images
                 andLocation:(WDDLocation*)location
         withCompletionBlock:(completionAddStatusBlock)completionBlock;
- (void)addStatusWithMessage:(NSString *)message
                   andImages:(NSArray *)images
                 andLocation:(WDDLocation *)location
                     toGroup:(Group *)group
         withCompletionBlock:(completionAddStatusBlock)completionBlock;

- (void)saveNotificationsToDataBase:(NSArray *)notifications;
- (void)savePostsToDataBase:(NSArray *)posts;
- (void)setCommentsFromPostInfo:(NSDictionary *)postInfo toPost:(Post *)post;
- (void)setTagsFromPostInfo:(NSDictionary *)postInfo toPost:(Post *)post;
- (void)setPlacesFromPostInfo:(NSDictionary *)postInfo toPost:(Post *)post;
- (void)setMediaFromPostInfo:(NSDictionary *)postInfo toPost:(Post *)post;
- (void)updateLinksForPost:(Post *)post;

- (Class)postClass;

- (void)refreshGroups;
- (void)updateProfileInfo;

// parse integration
- (void)updateSocialNetworkOnParse;
- (void)updateSocialNetworkOnParseNow:(BOOL)now;

- (void)getFriends;

- (NSArray *)getSavedEvents;

- (NSArray *)linksForText:(NSString *)text;

@end

@interface SocialNetwork (CoreDataGeneratedAccessors)

- (void)addGroupsObject:(Group *)value;
- (void)removeGroupsObject:(Group *)value;
- (void)addGroups:(NSSet *)values;
- (void)removeGroups:(NSSet *)values;
- (void)addNotificationsObject:(Notification *)value;
- (void)removeNotificationsObject:(Notification *)value;
- (void)addNotifications:(NSSet *)values;
- (void)removeNotification:(NSSet *)values;

@end
