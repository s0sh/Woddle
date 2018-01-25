//
//  GooglePlusPost.m
//  Woddl
//
//  Created by Sergii Gordiienko on 28.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "GooglePlusPost.h"
#import "GoogleOthersProfile.h"
#import "GoogleRequest.h"
#import "SocialNetwork.h"
#import "GooglePlusRefreshCommentOperation.h"
#import "GooglePlusLoadMoreCommentOperation.h"

@interface GooglePlusPost()<GooglePlusRefreshCommentOperationDelegate,GooglePlusLoadMoreCommentOperationDelegate>
@end

@implementation GooglePlusPost

@dynamic likedBy;
@synthesize getCommentComplationBlock;
@synthesize loadMoreCommentComplationBlock;

- (NSString *)socialNetworkIconName
{
    return self.subscribedBy.socialNetwork.socialNetworkIconName;
}

- (NSString *)socialNetworkLikesIconName
{
    return kGoogleLikesIconImageName;
}

- (NSString *)socialNetworkCommentsIconName
{
    return kGoogleCommentsIconImageName;
}

-(void)addLikeWithCompletionBlock:(ComplationLikingBlock)complationBlock_ andFailBlock:(FailLikingBlock)failBlock_
{
#warning not implemented
    failBlock_(nil);
}

-(void)addCommentWithMessage:(NSString*)message andCompletionBlock:(ComplationCommentBlock)complationBlock withFailBlock:(FailCommentBlock)failCommentBlock;
{
    GoogleRequest *request = [[GoogleRequest alloc] initWithToken:self.subscribedBy.socialNetwork.accessToken];
    [request addCommentWithMessage:message toPostURL:self.linkURLString];
}

-(void)commentsRefreshWithComplationBlock:(ComplationRefreshCommentsBlock)complationBlock
{
    getCommentComplationBlock = complationBlock;
    NSOperationQueue* bgQueue = [GooglePlusPost operationQueue];
    GooglePlusRefreshCommentOperation* operation = [[GooglePlusRefreshCommentOperation alloc] initGooglePlusRefreshCommentsWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)commentsLoadMoreFrom:(NSUInteger)from to:(NSUInteger)to withComplationBlock:(ComplationLoadMoreCommentsBlock)complationBlock
{
    loadMoreCommentComplationBlock = complationBlock;
    NSOperationQueue* bgQueue = [GooglePlusPost operationQueue];
    NSUInteger count = from+to;
    GooglePlusLoadMoreCommentOperation* operation = [[GooglePlusLoadMoreCommentOperation alloc] initGooglePlusLoadMoreCommentsWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID andCount:count withDelegate:self];
    [bgQueue addOperation:operation];
}

#pragma mark - Delegate

-(void)googlePlusRefreshCommentDidFinishWithComments:(NSArray *)comments
{
    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    [post setObject:comments forKey:@"comments"];
    [self.subscribedBy.socialNetwork setCommentsFromPostInfo:post toPost:self];
    getCommentComplationBlock(nil);
    getCommentComplationBlock = nil;
}

-(void)googlePlusLoadMoreCommentDidFinishWithComments:(NSArray *)comments
{
    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    [post setObject:comments forKey:@"comments"];
    [self.subscribedBy.socialNetwork setCommentsFromPostInfo:post toPost:self];
    loadMoreCommentComplationBlock(nil);
    loadMoreCommentComplationBlock = nil;
}

@end
