//
//  Post.h
//  Woddl
//
//  Created by Sergii Gordiienko on 14.04.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Media.h"

typedef NS_ENUM(NSInteger, PostType)
{
    kPostTypeUnknown = 0,
    kPostTypeEvent
};

typedef void (^ComplationLikingBlock)(BOOL isLiked);
typedef void (^FailLikingBlock)(NSError* error);
typedef void (^ComplationCommentBlock)(NSDictionary* info);
typedef void (^FailCommentBlock)(NSError* error);
typedef void (^ComplationShareBlock)(NSError* error);
typedef void (^ComplationRetweetBlock)(NSError* error);
typedef void (^ComplationPostBlock)(NSError* error);
typedef void (^ComplationReplyBlock)(NSError* error);
typedef void (^ComplationRefreshCommentsBlock)(NSError* error);
typedef void (^ComplationLoadMoreCommentsBlock)(NSError* error);

@class Comment, Group, Link, Media, Place, Tag, UserProfile, Notification;

@interface Post : NSManagedObject

@property (nonatomic, retain) NSNumber * commentsCount;
@property (nonatomic, retain) NSNumber * isCommentable;
@property (nonatomic, retain) NSNumber * isLikable;
@property (nonatomic, retain) NSNumber * isLinksProcessed;
@property (nonatomic, retain) NSNumber * isSearchedPost;
@property (nonatomic, retain) NSNumber * likesCount;
@property (nonatomic, retain) NSString * linkURLString;
@property (nonatomic, retain) id locationValue;
@property (nonatomic, retain) NSString * postID;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * time;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSDate * updateTime;
@property (nonatomic, retain) NSNumber * isReadLater;
@property (nonatomic, retain) UserProfile *author;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) Group *group;
@property (nonatomic, retain) NSSet *likedBy;
@property (nonatomic, retain) NSSet *links;
@property (nonatomic, retain) NSSet *media;
@property (nonatomic, retain) NSSet *places;
@property (nonatomic, retain) UserProfile *subscribedBy;
@property (nonatomic, retain) NSSet *tags;
@property (nonatomic, retain) NSSet *notifications;


+ (NSOperationQueue *) operationQueue;

- (void)addLikeWithCompletionBlock:(ComplationLikingBlock)complationBlock andFailBlock:(FailLikingBlock)failBlock;
- (void)addCommentWithMessage:(NSString *)message andCompletionBlock:(ComplationCommentBlock)complationBlock withFailBlock:(FailCommentBlock)failCommentBlock;
- (void)shareWithCompletionBlock:(ComplationShareBlock)complationBlock;
- (void)commentsRefreshWithComplationBlock:(ComplationRefreshCommentsBlock)complationBlock;
- (void)commentsLoadMoreFrom:(NSUInteger)from to:(NSUInteger)to withComplationBlock:(ComplationLoadMoreCommentsBlock)complationBlock;

- (void)refreshLikedUsersWithComplitionBlock:(void (^)(BOOL success))completionBlock;
- (void)refreshLikesAndCommentsCountWithComplitionBlock:(void (^)(BOOL success))complitionBlock;

@end

@interface Post (CoreDataGeneratedAccessors)

//  Generated methods
- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addLikedByObject:(UserProfile *)value;
- (void)removeLikedByObject:(UserProfile *)value;
- (void)addLikedBy:(NSSet *)values;
- (void)removeLikedBy:(NSSet *)values;

- (void)addLinksObject:(Link *)value;
- (void)removeLinksObject:(Link *)value;
- (void)addLinks:(NSSet *)values;
- (void)removeLinks:(NSSet *)values;

- (void)addMediaObject:(Media *)value;
- (void)removeMediaObject:(Media *)value;
- (void)addMedia:(NSSet *)values;
- (void)removeMedia:(NSSet *)values;

- (void)addPlacesObject:(Place *)value;
- (void)removePlacesObject:(Place *)value;
- (void)addPlaces:(NSSet *)values;
- (void)removePlaces:(NSSet *)values;

- (void)addTagsObject:(Tag *)value;
- (void)removeTagsObject:(Tag *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

- (void)addNotificationsObject:(Notification *)value;
- (void)removeNotificationsObject:(Notification *)value;
- (void)addNotifications:(NSSet *)values;
- (void)removeNotifications:(NSSet *)values;

//  Custom methods
- (NSString *)socialNetworkIconName;
- (NSString *)socialNetworkLikesIconName;
- (NSString *)socialNetworkCommentsIconName;

@end
