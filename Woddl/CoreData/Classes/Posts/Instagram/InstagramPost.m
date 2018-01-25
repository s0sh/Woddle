//
//  InstagramPost.m
//  Woddl
//
//  Created by Александр Бородулин on 07.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "InstagramPost.h"
#import "InstagramLikeOperation.h"
#import "SocialNetwork.h"
#import "WDDDataBase.h"
#import "InstagramCommentOperation.h"
#import "InstagramRefreshCommentOperation.h"
#import "InstagramLoadMoreCommentOperation.h"

@interface InstagramPost()<InstagramLikeOperationDelegate,InstagramRefreshCommentOperationDelegate,InstagramLoadMoreCommentOperationDelegate>
@end

@implementation InstagramPost

@dynamic imageURL;
@dynamic likedBy;
@synthesize completionBlock;
@synthesize failBlock;
@synthesize failComplationCommentBlock;
@synthesize complCommentBlock;
@synthesize getCommentComplationBlock;
@synthesize loadMoreCommentComplationBlock;

- (NSString *)socialNetworkIconName
{
    return self.subscribedBy.socialNetwork.socialNetworkIconName;
}

- (NSString *)socialNetworkLikesIconName
{
    return kInstagramLikesIconImageName;
}

- (NSString *)socialNetworkCommentsIconName
{
    return kInstagramCommentsIconImageName;
}

-(void)addLikeWithCompletionBlock:(ComplationLikingBlock)complationBlock_ andFailBlock:(FailLikingBlock)failBlock_
{
    completionBlock = complationBlock_;
    failBlock = failBlock_;
    NSOperationQueue* bgQueue = [InstagramPost operationQueue];
    InstagramLikeOperation *operation = [[InstagramLikeOperation alloc] initInstagramLikeOperationWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID andMyID:self.subscribedBy.userID withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)addCommentWithMessage:(NSString*)message andCompletionBlock:(ComplationCommentBlock)complationBlock_ withFailBlock:(FailCommentBlock)failCommentBlock_
{
    failComplationCommentBlock = failCommentBlock_;
    complCommentBlock = complationBlock_;
    NSOperationQueue* bgQueue = [InstagramPost operationQueue];
    InstagramCommentOperation* operation = [[InstagramCommentOperation alloc] initInstagramCommentOperationWithMesage:message andToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)commentsRefreshWithComplationBlock:(ComplationRefreshCommentsBlock)complationBlock
{
    getCommentComplationBlock = complationBlock;
    NSOperationQueue* bgQueue = [InstagramPost operationQueue];
    InstagramRefreshCommentOperation* operation = [[InstagramRefreshCommentOperation alloc] initInstagramRefreshCommentsWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)commentsLoadMoreFrom:(NSUInteger)from to:(NSUInteger)to withComplationBlock:(ComplationRefreshCommentsBlock)complationBlock
{
    loadMoreCommentComplationBlock = complationBlock;
    NSOperationQueue* bgQueue = [InstagramPost operationQueue];
    InstagramLoadMoreCommentOperation* operation = [[InstagramLoadMoreCommentOperation alloc] initInstagramLoadMoreCommentsWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID withDelegate:self];
    [bgQueue addOperation:operation];
}

#pragma mark - Delegate

-(void)instagramLikeDidFinishWithSuccess
{
    NSInteger likesCount = self.likesCount.integerValue;
    likesCount++;
    self.likesCount = [NSNumber numberWithInteger:likesCount];
    [[WDDDataBase sharedDatabase] save];
    completionBlock(YES);
    completionBlock = nil;
    failBlock = nil;
}

-(void)instagramLikeDidFinishWithFail
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

-(void)instagramUnlikeDidFinishWithSuccess
{
    NSInteger likesCount = self.likesCount.integerValue;
    likesCount--;
    self.likesCount = [NSNumber numberWithInteger:likesCount];
    [[WDDDataBase sharedDatabase] save];
    completionBlock(NO);
    completionBlock = nil;
    failBlock = nil;
}

-(void)instagramUnlikeDidFinishWithFail
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

-(void)instagramCommentDidFinishWithCommentID:(NSString *)commentID
{
    NSDictionary* commentInfo = [NSDictionary dictionaryWithObject:commentID forKey:@"id"];
    NSInteger commentsCount = self.commentsCount.integerValue;
    commentsCount++;
    self.commentsCount = [NSNumber numberWithInteger:commentsCount];
    [[WDDDataBase sharedDatabase] save];
    complCommentBlock(commentInfo);
    complCommentBlock = nil;
    failComplationCommentBlock = nil;
}

-(void)instagramCommentDidFinishWithFail
{
    NSInteger code = 106;
    NSString* errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"unlike not completed", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    failComplationCommentBlock(error);
    complCommentBlock = nil;
    failComplationCommentBlock = nil;
}

-(void)instagramRefreshCommentDidFinishWithComments:(NSArray *)comments
{
    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    [post setObject:comments forKey:@"comments"];
    [self.subscribedBy.socialNetwork setCommentsFromPostInfo:post toPost:self];
    getCommentComplationBlock(nil);
    getCommentComplationBlock = nil;
}

-(void)instagramLoadMoreCommentDidFinishWithComments:(NSArray *)comments
{
    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    [post setObject:comments forKey:@"comments"];
    [self.subscribedBy.socialNetwork setCommentsFromPostInfo:post toPost:self];
    loadMoreCommentComplationBlock(nil);
    loadMoreCommentComplationBlock = nil;
}

@end
