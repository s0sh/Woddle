//
//  TwitterPost.m
//  Woddl
//
//  Created by Sergii Gordiienko on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "TwitterPost.h"
#import "TwitterOthersProfile.h"
#import "TwitterLikeOperation.h"
#import "SocialNetwork.h"
#import "WDDDataBase.h"
#import "TwitterRetweetOperation.h"
#import "TwitterReplyOperation.h"
#import "TwitterSN.h"
#import "TwitterCommentOperation.h"
#import "NetworkRequest.h"
#import "TwitterLoadMoreCommentOperation.h"
#import "TwitterRefreshCommentOperation.h"
#import "Comment.h"

@interface TwitterPost()<TwitterLikeOperationDelegate,TwitterRetweetOperationDelegate,TwitterReplyOperationDelegate,TwitterCommentOperationDelegate,TwitterLoadMoreCommentOperationDelegate,TwitterRefreshCommentOperationDelegate>
@end

@implementation TwitterPost

@dynamic retweetedFrom;
@dynamic retweetsCount;
@synthesize completionBlock;
@synthesize failBlock;
@synthesize completeRetweetBlock;
@synthesize replyCompletionBlock;
@synthesize completionCommentBlock;
@synthesize failComplationCommentBlock;
@synthesize loadMoreCommentComplationBlock;
@synthesize getCommentComplationBlock;

- (NSString *)socialNetworkIconName
{
    return self.subscribedBy.socialNetwork.socialNetworkIconName;
}

- (NSString *)socialNetworkLikesIconName
{
    return kTwitterLikesIconImageName;
}

- (NSString *)socialNetworkCommentsIconName
{
    return kTwitterCommentsIconImageName;
}

-(void)addLikeWithCompletionBlock:(ComplationLikingBlock)complationBlock_ andFailBlock:(FailLikingBlock)failBlock_
{
    completionBlock = complationBlock_;
    failBlock = failBlock_;
    NSOperationQueue* bgQueue = [TwitterPost operationQueue];
    TwitterLikeOperation *operation = [[TwitterLikeOperation alloc] initTwitterLikeOperationWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID andMyID:self.subscribedBy.userID withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)retweetWithCompletionBlock:(ComplationRetweetBlock)complationBlock_
{
    completeRetweetBlock = complationBlock_;
    NSOperationQueue* bgQueue = [TwitterPost operationQueue];
    TwitterRetweetOperation *operation = [[TwitterRetweetOperation alloc] initTwitterRetweetOperationWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID withDelegate:self];
    [bgQueue addOperation:operation];
}

static const NSUInteger kTwitterPostMaxLength = 140;
-(void)addCommentWithMessage:(NSString*)message andCompletionBlock:(ComplationCommentBlock)complationBlock withFailBlock:(FailCommentBlock)failCommentBlock
{
    completionCommentBlock = complationBlock;
    failComplationCommentBlock = failCommentBlock;

    #warning Should be refactored to store this data separately
    NSString *messageWithName = [NSString stringWithFormat:@"@%@ %@", self.author.profileURL.lastPathComponent, message];

    if (!messageWithName.length || messageWithName.length > kTwitterPostMaxLength )
    {
        NSArray *objArray = @[kErrorDescriptionTwitterCommentFailed, kErrorFailureReasonTwitterInvalidTweetLength];
        NSArray *keyArray = @[NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
        NSError *error = [NSError errorWithDomain:kErrorDomain
                                             code:kErrorCodeTwitterCommentFailed
                                         userInfo:userInfo];
        failComplationCommentBlock(error);
        completionCommentBlock = nil;
        failComplationCommentBlock = nil;
#ifdef DEBUG
        DLog(@"fail add tweet");
#endif
        return ;
    }
#ifdef DEBUG
    DLog(@"Addin tweet comment: %ld\n %@", message.length, message);
#endif
 
    // If everything OK - post tweet
    NSOperationQueue* bgQueue = [TwitterPost operationQueue];
    TwitterCommentOperation *operation = [[TwitterCommentOperation alloc] initTwitterCommentOperationWithMesage:messageWithName Token:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID andUserID:self.postID withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)replyWithMessage:(NSString*)message andImage:(NSData*)image andCompletionBlock:(ComplationReplyBlock)complationBlock
{
    replyCompletionBlock = complationBlock;
    NSOperationQueue* bgQueue = [TwitterPost operationQueue];
    TwitterReplyOperation *operation = [[TwitterReplyOperation alloc] initTwitterReplyOperationWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID andMessage:message andImage:image withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)commentsRefreshWithComplationBlock:(ComplationRefreshCommentsBlock)complationBlock
{
    getCommentComplationBlock = complationBlock;
    
    NSArray* comments = [self.comments allObjects];
    
    unsigned long long int lastComment = 0;
    
    for(Comment *comment in comments)
    {
        if(comment.commentID.longLongValue>lastComment)
        {
            lastComment = comment.commentID.longLongValue;
        }
    }
    
    NSOperationQueue* bgQueue = [TwitterPost operationQueue];
    TwitterRefreshCommentOperation *operation = [[TwitterRefreshCommentOperation alloc] initTwitterRefreshCommentsWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID userName:self.author.name sinceID:self.postID withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)commentsLoadMoreFrom:(NSString*)from to:(NSUInteger)to withComplationBlock:(ComplationLoadMoreCommentsBlock)complationBlock
{
    loadMoreCommentComplationBlock= complationBlock;
    NSOperationQueue* bgQueue = [TwitterPost operationQueue];
    TwitterLoadMoreCommentOperation *operation = [[TwitterLoadMoreCommentOperation alloc] initTwitterLoadMoreCommentsWithToken:self.subscribedBy.socialNetwork.accessToken andPostID:self.postID andUserName:self.author.name from:from to:to withDelegate:self];
    [bgQueue addOperation:operation];
}

#pragma mark - Delegate

-(void)twitterLikeDidFinishWithSuccess
{
    NSInteger likesCount = self.likesCount.integerValue;
    likesCount++;
    self.likesCount = [NSNumber numberWithInteger:likesCount];
    [[WDDDataBase sharedDatabase] save];
    completionBlock(YES);
    completionBlock = nil;
    failBlock = nil;
}

-(void)twitterLikeDidFinishWithFail
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

-(void)twitterUnlikeDidFinishWithSuccess
{
    NSInteger likesCount = self.likesCount.integerValue;
    likesCount--;
    self.likesCount = [NSNumber numberWithInteger:likesCount];
    [[WDDDataBase sharedDatabase] save];
    completionBlock(NO);
    completionBlock = nil;
    failBlock = nil;
}

-(void)twitterUnlikeDidFinishWithFail
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

-(void)twitterRetweetDidFinishWithSuccess
{
    completeRetweetBlock(nil);
    completeRetweetBlock = nil;
}

-(void)twitterRetweetDidFinishWithFail
{
    NSInteger code = 103;
    NSString* errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"unlike not completed", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    completeRetweetBlock(error);
    completeRetweetBlock = nil;
}

-(void)twitterReplyDidFinishWithSuccess:(NSDictionary *)result
{
    TwitterSN* network = (TwitterSN*)self.subscribedBy.socialNetwork;
    [network addPostToDataBase:result];
    [[WDDDataBase sharedDatabase] save];
    self.replyCompletionBlock(nil);
    self.replyCompletionBlock = nil;
}

-(void)twitterReplyDidFinishWithFail
{
    NSInteger code = 103;
    NSString* errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"unlike not completed", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    self.replyCompletionBlock(error);
    self.replyCompletionBlock = nil;
}

-(void)twitterCommentDidFinishWithDictionary:(NSDictionary *)comment
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
    completionCommentBlock(nil);
    completionCommentBlock = nil;
    failComplationCommentBlock = nil;
}

-(void)twitterCommentDidFinishWithFail
{
    NSInteger code = 110;
    NSString* errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"comment not completed", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    failComplationCommentBlock(error);
    completionCommentBlock = nil;
    failComplationCommentBlock = nil;
}

-(void)twitterLoadMoreCommentDidFinishWithComments:(NSArray *)comments
{
    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    [post setObject:comments forKey:@"comments"];
    [self.subscribedBy.socialNetwork setCommentsFromPostInfo:post toPost:self];
    loadMoreCommentComplationBlock(nil);
    loadMoreCommentComplationBlock = nil;
}

-(void)twitterRefreshCommentDidFinishWithComments:(NSArray*)comments
{
    NSMutableDictionary* post = [[NSMutableDictionary alloc] init];
    [post setObject:comments forKey:@"comments"];
    [self.subscribedBy.socialNetwork setCommentsFromPostInfo:post toPost:self];
    getCommentComplationBlock(nil);
    getCommentComplationBlock = nil;
}

#pragma mark - Instruments

NSComparisonResult dateSortComment(Comment *s1, Comment *s2, void *context)
{
    NSDate* d1 = s1.date;
    NSDate* d2 = s2.date;
    return [d1 compare:d2];
}

@end
