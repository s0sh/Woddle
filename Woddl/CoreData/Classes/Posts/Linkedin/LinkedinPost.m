//
//  LinkedinPost.m
//  Woddl
//
//  Created by Sergii Gordiienko on 08.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinPost.h"
#import "LinkedinLikeOperation.h"
#import "SocialNetwork.h"
#import "WDDDataBase.h"
#import "LinkedinCommentOperation.h"
#import "LinkedinRefreshCommentOperation.h"
#import "LinkedinLoadMoreCommentOperation.h"
#import "UserProfile.h"
#import "NetworkRequest.h"

@interface LinkedinPost()<LinkedinLikeOperationDelegate,LinkedinCommentOperationDelegate,LinkedinRefreshCommentOperationDelegate,LinkedinLoadMoreCommentOperationDelegate>
@end

@implementation LinkedinPost

@dynamic updateKey;
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
    return kLinkedInLikesIconImageName;
}

- (NSString *)socialNetworkCommentsIconName
{
    return kLinkedInCommentsIconImageName;
}

-(void)addLikeWithCompletionBlock:(ComplationLikingBlock)complationBlock_ andFailBlock:(FailLikingBlock)failBlock_
{
    completionBlock = complationBlock_;
    failBlock = failBlock_;
    NSOperationQueue* bgQueue = [LinkedinPost operationQueue];
    
    BOOL isGroupPost = NO;
    
    if (self.group)
    {
        isGroupPost = YES;
    }
    
    LinkedinLikeOperation *operation = [[LinkedinLikeOperation alloc] initLinkedinLikeOperationWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.updateKey andMyID:self.subscribedBy.userID isGroupPost:isGroupPost withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)addCommentWithMessage:(NSString*)message andCompletionBlock:(ComplationCommentBlock)complationBlock_ withFailBlock:(FailCommentBlock)failCommentBlock_
{
    failComplationCommentBlock = failCommentBlock_;
    complCommentBlock = complationBlock_;
    NSOperationQueue* bgQueue = [LinkedinPost operationQueue];
    
    BOOL isGroupPost = NO;
    
    if (self.group)
    {
        isGroupPost = YES;
    }
    
    LinkedinCommentOperation* operation = [[LinkedinCommentOperation alloc] initLinkedinCommentOperationWithMesage:message andToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.updateKey andUserID:self.subscribedBy.userID isGroupPost:isGroupPost withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)commentsRefreshWithComplationBlock:(ComplationRefreshCommentsBlock)complationBlock
{
    getCommentComplationBlock = complationBlock;
    NSOperationQueue* bgQueue = [LinkedinPost operationQueue];
    
    BOOL isGroupPost = NO;
    
    if (self.group)
    {
        isGroupPost = YES;
    }
    
    LinkedinRefreshCommentOperation* operation = [[LinkedinRefreshCommentOperation alloc] initLinkedinRefreshCommentsWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.updateKey isGroupPost:isGroupPost withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)commentsLoadMoreFrom:(NSUInteger)from to:(NSUInteger)to withComplationBlock:(ComplationLoadMoreCommentsBlock)complationBlock
{
    loadMoreCommentComplationBlock = complationBlock;
    NSOperationQueue* bgQueue = [LinkedinPost operationQueue];
    
    BOOL isGroupPost = NO;
    
    if (self.group)
    {
        isGroupPost = YES;
    }
    
    LinkedinLoadMoreCommentOperation* operation = [[LinkedinLoadMoreCommentOperation alloc] initLinkedinLoadMoreCommentsWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.updateKey from:from to:to isGroupPost:isGroupPost withDelegate:self];
    [bgQueue addOperation:operation];
}

#pragma mark - Delegate

-(void)linkedinLikeDidFinishWithSuccess
{
    NSInteger likesCount = self.likesCount.integerValue;
    likesCount++;
    self.likesCount = [NSNumber numberWithInteger:likesCount];
    [[WDDDataBase sharedDatabase] save];
    completionBlock(YES);
    completionBlock = nil;
    failBlock = nil;
}

-(void)linkedinLikeDidFinishWithFail
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

-(void)linkedinUnlikeDidFinishWithSuccess
{
    NSInteger likesCount = self.likesCount.integerValue;
    likesCount--;
    self.likesCount = [NSNumber numberWithInteger:likesCount];
    [[WDDDataBase sharedDatabase] save];
    completionBlock(NO);
    completionBlock = nil;
    failBlock = nil;
}

-(void)linkedinUnlikeDidFinishWithFail
{
    int code = 100;
    NSString* errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"unlike not completed", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    failBlock(error);
    completionBlock = nil;
    failBlock = nil;
}

-(void)linkedinLikingError:(NSDictionary *)error
{
    //Throttle limit for calls to this resource is reached.
    NSError* errorResult = nil;
    if(error)
    {
        if([error objectForKey:@"status"])
        {
            NSInteger code = [[error objectForKey:@"status"] integerValue];
            NSString* errorDomain = @"woodlDomain";
            if(code==403||code==401)
            {
                NSArray *objArray = [NSArray arrayWithObjects:@"unlike not completed", @"Throttle limit for calls to this resource is reached.", nil];
                NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
                errorResult = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
            }
        }
    }
    failBlock(errorResult);
    completionBlock = nil;
    failBlock = nil;
}

-(void)linkedinCommentDidFinishWithDictionary:(NSDictionary *)comment
{
    NSInteger commentsCount = self.commentsCount.integerValue;
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

-(void)linkedinCommentDidFinishWithFail:(NSDictionary *)failInfo
{
    if(failInfo)
    {
        NSInteger code = [[failInfo objectForKey:@"error"] integerValue];
        NSString* errorDomain = @"woodlDomain";
        NSArray *objArray;
        if(code==401||code==403)
        {
            objArray = [NSArray arrayWithObjects:@"comment not completed", @"ended in the number of requests", nil];
        }
        else
        {
            objArray = [NSArray arrayWithObjects:@"comment not completed", @"probably no connection", nil];
        }
        NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
        NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
        failComplationCommentBlock(error);
        complCommentBlock = nil;
        failComplationCommentBlock = nil;
    }
    else
    {
        NSInteger code = 106;
        NSString* errorDomain = @"woodlDomain";
        NSArray *objArray = [NSArray arrayWithObjects:@"comment not completed", @"probably no connection", nil];
        NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
        NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
        failComplationCommentBlock(error);
        complCommentBlock = nil;
        failComplationCommentBlock = nil;
    }
}

-(void)linkedinRefreshCommentDidFinishWithComments:(NSArray *)comments
{
    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    [post setObject:comments forKey:@"comments"];
    [self.subscribedBy.socialNetwork setCommentsFromPostInfo:post toPost:self];
    getCommentComplationBlock(nil);
    getCommentComplationBlock = nil;
}

-(void)linkedinLoadMoreCommentDidFinishWithComments:(NSArray *)comments
{
    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    [post setObject:comments forKey:@"comments"];
    [self.subscribedBy.socialNetwork setCommentsFromPostInfo:post toPost:self];
    loadMoreCommentComplationBlock(nil);
    loadMoreCommentComplationBlock = nil;
}

@end
