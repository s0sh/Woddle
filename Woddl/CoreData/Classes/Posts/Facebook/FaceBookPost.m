//
//  FaceBookPost.m
//  Woddl
//
//  Created by Sergii Gordiienko on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FaceBookPost.h"
#import "Comment.h"
#import "FaceBookOthersProfile.h"
#import "FacebookRequest.h"
#import "SocialNetwork.h"
#import "FacebookLikeOperation.h"
#import "WDDDataBase.h"
#import "FacebookCommentOperation.h"
#import "FacebookShareOperation.h"
#import "FacebookRefreshCommentOperation.h"
#import "FacebookLoadMoreCommentOperation.h"

@interface FaceBookPost()<FacebookLikeOperationDelegate,
                            FacebookCommentOperationDelegate,
                            FacebookShareOperationDelegate,
                            FacebookRefreshCommentOperationDelegate,
                            FacebookLoadMoreCommentOperationDelegate>
@end

@implementation FaceBookPost

@dynamic likedBy;
@synthesize completionBlock;
@synthesize failBlock;
@synthesize completionCommentBlock;
@synthesize completionSharingBlock;
@synthesize failComplationCommentBlock;
@synthesize getCommentComplationBlock;
@synthesize loadMoreCommentComplationBlock;

- (NSString *)socialNetworkIconName
{
    return self.subscribedBy.socialNetwork.socialNetworkIconName;
}

- (NSString *)socialNetworkLikesIconName
{
    return kFacebookLikesIconImageName;
}

- (NSString *)socialNetworkCommentsIconName
{
    return kFacebookCommentsIconImageName;
}

- (NSString *)fullID
{
    NSString *postID = self.postID;
    if ([postID rangeOfString:@"_"].location == NSNotFound)
    {
        postID = [(self.group ? self.group.groupID : self.author.userID) stringByAppendingFormat:@"_%@", self.postID];
    }
    
    return postID;
}

-(void)addLikeWithCompletionBlock:(ComplationLikingBlock)complationBlock_ andFailBlock:(FailLikingBlock)failBlock_
{
    completionBlock = complationBlock_;
    failBlock = failBlock_;
    NSOperationQueue* bgQueue = [FaceBookPost operationQueue];
    
    
    FacebookLikeOperation *operation = [[FacebookLikeOperation alloc] initFacebookLikeOperationWithToken:self.subscribedBy.socialNetwork.accessToken
                                                                                               andPostID:[self fullID]
                                                                                                 andMyID:self.subscribedBy.userID
                                                                                            withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)addCommentWithMessage:(NSString*)message andCompletionBlock:(ComplationCommentBlock)complationBlock_ withFailBlock:(FailCommentBlock)failCommentBlock_
{
    failComplationCommentBlock = failCommentBlock_;
    completionCommentBlock = complationBlock_;
    NSOperationQueue* bgQueue = [FaceBookPost operationQueue];

    FacebookCommentOperation* operation = [[FacebookCommentOperation alloc] initFacebookCommentOperationWithMesage:message
                                                                                                             Token:self.subscribedBy.socialNetwork.accessToken
                                                                                                         andPostID:self.postID
                                                                                                         andUserID:self.subscribedBy.userID
                                                                                                      withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)shareWithCompletionBlock:(ComplationShareBlock)complationBlock_
{
    completionSharingBlock = complationBlock_;
    NSOperationQueue* bgQueue = [FaceBookPost operationQueue];
    FacebookShareOperation* operation = [[FacebookShareOperation alloc] initFacebookShareOperationWithToken:self.subscribedBy.socialNetwork.accessToken
                                                                                                 andMessage:@""
                                                                                                    andLink:self.linkURLString
                                                                                               withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)commentsRefreshWithComplationBlock:(ComplationRefreshCommentsBlock)complationBlock
{
    getCommentComplationBlock = complationBlock;
    NSOperationQueue* bgQueue = [FaceBookPost operationQueue];
    FacebookRefreshCommentOperation* operation = [[FacebookRefreshCommentOperation alloc] initFacebookRefreshCommentsWithToken:self.subscribedBy.socialNetwork.accessToken
                                                                                                                     andPostID:self.fullID
                                                                                                                  withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)commentsLoadMoreFrom:(NSUInteger)from to:(NSUInteger)to withComplationBlock:(ComplationLoadMoreCommentsBlock)complationBlock
{
    loadMoreCommentComplationBlock = complationBlock;
    NSOperationQueue* bgQueue = [FaceBookPost operationQueue];
    NSUInteger count = from+to;
    FacebookLoadMoreCommentOperation* operation = [[FacebookLoadMoreCommentOperation alloc] initFacebookLoadMoreCommentsWithToken:self.subscribedBy.socialNetwork.accessToken
                                                                                                                        andPostID:self.fullID
                                                                                                                         andCount:count
                                                                                                                           offset:from
                                                                                                                     withDelegate:self];
    [bgQueue addOperation:operation];
}

#pragma mark - Delegate

-(void)facebookLikeDidFinishWithSuccess
{
    NSInteger likesCount = self.likesCount.integerValue;
    likesCount++;
    self.likesCount = [NSNumber numberWithInteger:likesCount];
    [[WDDDataBase sharedDatabase] save];
    completionBlock(YES);
    completionBlock = nil;
    failBlock = nil;
}

-(void)facebookLikeDidFinishWithFail
{
    NSInteger code = 101;
    NSString* errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"like not completed", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    failBlock(error);
    completionBlock = nil;
    failBlock = nil;
}

-(void)facebookUnlikeDidFinishWithSuccess
{
    NSInteger likesCount = self.likesCount.integerValue;
    likesCount--;
    self.likesCount = [NSNumber numberWithInteger:likesCount];
    [[WDDDataBase sharedDatabase] save];
    completionBlock(NO);
    completionBlock = nil;
    failBlock = nil;
}

-(void)facebookUnlikeDidFinishWithFail
{
    NSInteger code = 100;
    NSString* errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"unlike not completed", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    failBlock(error);
    completionBlock = nil;
    failBlock = nil;
}

-(void)facebookCommentDidFinishWithDictionary:(NSDictionary *)comment
{
    NSInteger commentsCount = self.commentsCount.integerValue;
    commentsCount++;
    self.commentsCount = [NSNumber numberWithInt:commentsCount];
    [[WDDDataBase sharedDatabase] save];
    
    NSMutableDictionary* resultComment = [NSMutableDictionary dictionaryWithDictionary:comment];
    NSMutableDictionary* authorComment = [[NSMutableDictionary alloc] init];
    [authorComment setObject:self.subscribedBy.avatarRemoteURL forKey:kPostCommentAuthorAvaURLDictKey];
    [authorComment setObject:self.subscribedBy.name forKey:kPostCommentAuthorNameDictKey];
    [authorComment setObject:self.subscribedBy.userID forKey:kPostCommentAuthorIDDictKey];
    [authorComment setObject:self.subscribedBy.profileURL forKey:kPostAuthorProfileURLDictKey];
    [resultComment setObject:authorComment forKey:kPostCommentAuthorDictKey];
    NSArray* commentsArray = [NSArray arrayWithObject:resultComment];
    NSMutableDictionary * postDictionary = [[NSMutableDictionary alloc] init];
    [postDictionary setObject:commentsArray forKey:kPostCommentsDictKey];
    
    [self.subscribedBy.socialNetwork setCommentsFromPostInfo:postDictionary toPost:self];
    
    completionCommentBlock(nil);
    completionCommentBlock = nil;
    failComplationCommentBlock = nil;
}

-(void)facebookCommentDidFinishWithFail
{
    NSInteger code = 106;
    NSString* errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"unlike not completed", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    failComplationCommentBlock(error);
    completionCommentBlock = nil;
    failComplationCommentBlock = nil;
}

-(void)facebookShareDidFinishWithSuccess
{
    completionSharingBlock(nil);
    completionSharingBlock = nil;
}

-(void)facebookShareDidFinishWithFail
{
    NSInteger code = 102;
    NSString* errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"unlike not completed", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    completionSharingBlock(error);
    completionSharingBlock = nil;
}

-(void)facebookRefreshCommentDidFinishWithComments:(NSArray *)comments
{
    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    [post setObject:comments forKey:@"comments"];
    [self.subscribedBy.socialNetwork setCommentsFromPostInfo:post toPost:self];
    getCommentComplationBlock(nil);
    getCommentComplationBlock = nil;
}

-(void)facebookLoadMoreCommentDidFinishWithComments:(NSArray *)comments
{
    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    [post setObject:comments forKey:@"comments"];
    [self.subscribedBy.socialNetwork setCommentsFromPostInfo:post toPost:self];
    loadMoreCommentComplationBlock(nil);
    loadMoreCommentComplationBlock = nil;
}

- (void)refreshLikedUsersWithComplitionBlock:(void (^)(BOOL success))cmpBlock
{
    NSString *postId = self.fullID;
    NSString *accessToken = self.subscribedBy.socialNetwork.accessToken;
    
    dispatch_queue_t likedUsersQueue = dispatch_queue_create("loading_liked_users", nil);
    dispatch_async(likedUsersQueue, ^{
        
        BOOL result = [[FacebookRequest new] getUsersWhosLikedPostWithID:postId
                                                             accessToken:accessToken];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.likesCount.integerValue < self.likedBy.count)
            {
                self.likesCount = @(self.likedBy.count);
            }
            [[WDDDataBase sharedDatabase] save];
            
            cmpBlock(result);
        });
        
    });
}

@end
