//
//  Post.m
//  Woddl
//
//  Created by Sergii Gordiienko on 14.04.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "Post.h"
#import "Comment.h"
#import "Group.h"
#import "Media.h"
#import "Tag.h"
#import "UserProfile.h"
#import "SocialNetwork.h"

#import "NetworkRequest.h"
#import "FacebookRequest.h"
#import "FoursquareRequest.h"
#import "LinkedinRequest.h"
#import "TwitterRequest.h"
#import "GoogleRequest.h"
#import "InstagramRequest.h"

#import "FaceBookPost.h"
#import "FoursquarePost.h"
#import "LinkedinPost.h"
#import "TwitterPost.h"
#import "GooglePlusPost.h"
#import "InstagramPost.h"

#import "WDDDataBase.h"

@implementation Post

@dynamic commentsCount;
@dynamic isCommentable;
@dynamic isLikable;
@dynamic isLinksProcessed;
@dynamic isSearchedPost;
@dynamic likesCount;
@dynamic linkURLString;
@dynamic locationValue;
@dynamic postID;
@dynamic text;
@dynamic time;
@dynamic type;
@dynamic updateTime;
@dynamic isReadLater;
@dynamic author;
@dynamic comments;
@dynamic group;
@dynamic likedBy;
@dynamic links;
@dynamic media;
@dynamic places;
@dynamic subscribedBy;
@dynamic tags;
@dynamic notifications;

- (NSString *)socialNetworkIconName
{
    NSAssert(![self isKindOfClass:[Post class]], @"This is abstract class. Method should be overloaded by subclass");
    return nil;
}

- (NSString *)socialNetworkLikesIconName
{
    NSAssert(![self isKindOfClass:[Post class]], @"This is abstract class. Method should be overloaded by subclass");
    return nil;
}

- (NSString *)socialNetworkCommentsIconName
{
    NSAssert(![self isKindOfClass:[Post class]], @"This is abstract class. Method should be overloaded by subclass");
    return nil;
}

+ (NSOperationQueue *)operationQueue
{
    NSAssert([self class] != [Post class], @"SocialNetwork class is abstract and have to be subclassed!");
    
    NSMutableDictionary *operationQueues = [Post operationQueues];
    NSString *queueKey = [NSStringFromClass([self class]) stringByAppendingString:@".operationQueue"];
    
    if (!operationQueues[queueKey])
    {
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        operationQueue.maxConcurrentOperationCount = 2;
        operationQueues[queueKey] = operationQueue;
    }
    
    return operationQueues[queueKey];
}

+ (NSMutableDictionary *)operationQueues
{
    static NSMutableDictionary *operationQueues;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        operationQueues = [[NSMutableDictionary alloc] init];
    });
    return operationQueues;
}

- (void)addLike
{
    NSAssert(![self isKindOfClass:[Post class]], @"This is abstract class. Method should be overloaded by subclass");
}

- (void)addCommentWithMessage:(NSString *)message andCompletionBlock:(ComplationCommentBlock)complationBlock withFailBlock:(FailCommentBlock)failCommentBlock
{
    NSAssert(![self isKindOfClass:[Post class]], @"This is abstract class. Method should be overloaded by subclass");
}

- (void)addLikeWithCompletionBlock:(ComplationLikingBlock)complationBlock andFailBlock:(FailLikingBlock)failBlock
{
    NSAssert(![self isKindOfClass:[Post class]], @"This is abstract class. Method should be overloaded by subclass");
}

- (void)shareWithCompletionBlock:(ComplationShareBlock)complationBlock
{
    NSAssert(![self isKindOfClass:[Post class]], @"This is abstract class. Method should be overloaded by subclass");
}

-(void)commentsRefreshWithComplationBlock:(ComplationRefreshCommentsBlock)complationBlock
{
    NSAssert(![self isKindOfClass:[Post class]], @"This is abstract class. Method should be overloaded by subclass");
}

-(void)commentsLoadMoreFrom:(NSUInteger)from to:(NSUInteger)to withComplationBlock:(ComplationRefreshCommentsBlock)complationBlock
{
    NSAssert(![self isKindOfClass:[Post class]], @"This is abstract class. Method should be overloaded by subclass");
}

- (void)refreshLikedUsersWithComplitionBlock:(void (^)(BOOL success))completionBlock
{
    NSString *postId = self.postID;
    NSString *accessToken = self.subscribedBy.socialNetwork.accessToken;
    
    dispatch_queue_t likedUsersQueue = dispatch_queue_create("loading_liked_users", nil);
    dispatch_async(likedUsersQueue, ^{
        
        BOOL result =[[self networkRequestFabric] getUsersWhosLikedPostWithID:postId
                                                                  accessToken:accessToken];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.likesCount.integerValue < self.likedBy.count)
            {
                self.likesCount = @(self.likedBy.count);
            }
            [[WDDDataBase sharedDatabase] save];
            
            completionBlock(result);
        });
        
    });
}

- (void)refreshLikesAndCommentsCountWithComplitionBlock:(void (^)(BOOL success))complitionBlock
{
    //    static dispatch_queue_t commentsUpdateQueue = nil;
    //
    //    if (!commentsUpdateQueue)
    //    {
    //        commentsUpdateQueue = dispatch_queue_create("likes_and_commetns_users", DISPATCH_QUEUE_SERIAL);
    //    }
    
    NSString *postId = self.postID;
    NSString *accessToken = self.subscribedBy.socialNetwork.accessToken;
    
    dispatch_async(/*commentsUpdateQueue*/dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        BOOL result = [[self networkRequestFabric] updateLikesAndFavoritesForPostWithID:postId
                                                                            accessToken:accessToken];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[WDDDataBase sharedDatabase] save];
            complitionBlock(result);
        });
        
    });
}

- (NetworkRequest *)networkRequestFabric
{
    if ([self isKindOfClass:[FaceBookPost class]])
    {
        return [FacebookRequest new];
    }
    else if ([self isKindOfClass:[TwitterPost class]])
    {
        return [TwitterRequest new];
    }
    else if ([self isKindOfClass:[FoursquarePost class]])
    {
        return [FoursquareRequest new];
    }
    else if ([self isKindOfClass:[GooglePlusPost class]])
    {
        return [[GoogleRequest alloc] initWithToken:self.subscribedBy.socialNetwork.accessToken];
    }
    else if ([self isKindOfClass:[LinkedinPost class]])
    {
        return [LinkedinRequest new];
    }
    else if ([self isKindOfClass:[InstagramPost class]])
    {
        return [InstagramRequest new];
    }
    else
    {
        return nil;
    }
}

@end
