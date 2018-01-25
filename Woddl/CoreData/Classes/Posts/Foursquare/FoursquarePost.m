//
//  FoursquarePost.m
//  Woddl
//
//  Created by Александр Бородулин on 08.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FoursquarePost.h"
#import "FoursquareLikeOperation.h"
#import "SocialNetwork.h"
#import "WDDDataBase.h"
#import "FoursquareCommentOperation.h"
#import "FoursquareRefreshCommentOperation.h"
#import "FoursquareLoadMoreCommentOperation.h"
#import "NetworkRequest.h"

@interface FoursquarePost()<FoursquareLikeOperationDelegate,FoursquareCommentOperationDelegate,FoursquareRefreshCommentOperationDelegate,FoursquareLoadMoreCommentOperationDelegate>
@end

@implementation FoursquarePost

@dynamic likedBy;

@synthesize completionBlock;
@synthesize failBlock;
@synthesize complCommentBlock;
@synthesize failComplationCommentBlock;
@synthesize getCommentComplationBlock;
@synthesize loadMoreCommentComplationBlock;

- (NSString *)socialNetworkIconName
{
    return self.subscribedBy.socialNetwork.socialNetworkIconName;
}

- (NSString *)socialNetworkLikesIconName
{
    return kFoursquareLikesIconImageName;
}

- (NSString *)socialNetworkCommentsIconName
{
    return kFoursquareCommentsIconImageName;
}

-(void)addLikeWithCompletionBlock:(ComplationLikingBlock)complationBlock_ andFailBlock:(FailLikingBlock)failBlock_
{
    completionBlock = complationBlock_;
    failBlock = failBlock_;
    NSOperationQueue* bgQueue = [FoursquarePost operationQueue];
    FoursquareLikeOperation *operation = [[FoursquareLikeOperation alloc] initFoursquareLikeOperationWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID andMyID:self.subscribedBy.userID withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)addCommentWithMessage:(NSString*)message andCompletionBlock:(ComplationCommentBlock)complationBlock_ withFailBlock:(FailCommentBlock)failCommentBlock_
{
    failComplationCommentBlock = failCommentBlock_;
    complCommentBlock = complationBlock_;
    NSOperationQueue* bgQueue = [FoursquarePost operationQueue];
    FoursquareCommentOperation* operation = [[FoursquareCommentOperation alloc] initFoursquareCommentOperationWithMesage:message andToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)commentsRefreshWithComplationBlock:(ComplationRefreshCommentsBlock)complationBlock
{
    getCommentComplationBlock = complationBlock;
    NSOperationQueue* bgQueue = [FoursquarePost operationQueue];
    FoursquareRefreshCommentOperation* operation = [[FoursquareRefreshCommentOperation alloc] initFoursquareRefreshCommentsWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)commentsLoadMoreFrom:(NSUInteger)from to:(NSUInteger)to withComplationBlock:(ComplationRefreshCommentsBlock)complationBlock
{
    loadMoreCommentComplationBlock = complationBlock;
    NSOperationQueue* bgQueue = [FoursquarePost operationQueue];
    FoursquareLoadMoreCommentOperation* operation = [[FoursquareLoadMoreCommentOperation alloc] initFoursquareLoadMoreCommentsWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID withDelegate:self];
    [bgQueue addOperation:operation];
}

#pragma mark - Delegate

-(void)foursquareLikeDidFinishWithSuccess
{
    NSInteger likesCount = self.likesCount.integerValue;
    likesCount++;
    self.likesCount = [NSNumber numberWithInteger:likesCount];
    [[WDDDataBase sharedDatabase] save];
    completionBlock(YES);
    completionBlock = nil;
    failBlock = nil;
}

-(void)foursquareLikeDidFinishWithFail
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

-(void)foursquareUnlikeDidFinishWithSuccess
{
    NSInteger likesCount = self.likesCount.integerValue;
    likesCount--;
    self.likesCount = [NSNumber numberWithInteger:likesCount];
    [[WDDDataBase sharedDatabase] save];
    completionBlock(NO);
    completionBlock = nil;
    failBlock = nil;
}

-(void)foursquareUnlikeDidFinishWithFail
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

-(void)foursquareCommentDidFinishWithDictionary:(NSDictionary *)comment
{
    NSInteger commentsCount = self.commentsCount.intValue;
    commentsCount++;
    self.commentsCount = [NSNumber numberWithInteger:commentsCount];
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
    
    complCommentBlock(nil);
    complCommentBlock = nil;
    failComplationCommentBlock = nil;
}

-(void)foursquareCommentDidFinishWithFail
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

-(void)foursquareRefreshCommentDidFinishWithComments:(NSArray *)comments
{
    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    [post setObject:comments forKey:@"comments"];
    [self.subscribedBy.socialNetwork setCommentsFromPostInfo:post toPost:self];
    getCommentComplationBlock(nil);
    getCommentComplationBlock = nil;
}

-(void)foursquareLoadMoreCommentDidFinishWithComments:(NSArray *)comments
{
    
    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    [post setObject:comments forKey:@"comments"];
    [self.subscribedBy.socialNetwork setCommentsFromPostInfo:post toPost:self];
    loadMoreCommentComplationBlock(nil);
    loadMoreCommentComplationBlock = nil;
}

@end
