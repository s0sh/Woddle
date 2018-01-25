//
//  TwitterPost.h
//  Woddl
//
//  Created by Sergii Gordiienko on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Post.h"

@class TwitterOthersProfile;

@interface TwitterPost : Post

@property (nonatomic, strong) TwitterOthersProfile *retweetedFrom;
@property (nonatomic, strong) NSNumber *retweetsCount;

@property (nonatomic, strong) ComplationLikingBlock completionBlock;
@property (nonatomic, strong) ComplationRetweetBlock completeRetweetBlock;
@property (nonatomic, strong) FailLikingBlock failBlock;
@property (nonatomic, strong) ComplationReplyBlock replyCompletionBlock;
@property (nonatomic, strong) ComplationCommentBlock completionCommentBlock;
@property (nonatomic, strong) FailCommentBlock failComplationCommentBlock;
@property (nonatomic, strong) ComplationLoadMoreCommentsBlock loadMoreCommentComplationBlock;
@property (nonatomic, strong) ComplationRefreshCommentsBlock getCommentComplationBlock;

-(void)addLikeWithCompletionBlock:(ComplationLikingBlock)complationBlock_ andFailBlock:(FailLikingBlock)failBlock_;
-(void)retweetWithCompletionBlock:(ComplationRetweetBlock)complationBlock_;
-(void)addCommentWithMessage:(NSString*)message andCompletionBlock:(ComplationCommentBlock)complationBlock withFailBlock:(FailCommentBlock)failCommentBlock;
-(void)replyWithMessage:(NSString*)message andImage:(NSData*)image andCompletionBlock:(ComplationReplyBlock)complationBlock;
-(void)commentsLoadMoreFrom:(NSString*)from to:(NSUInteger)to withComplationBlock:(ComplationLoadMoreCommentsBlock)complationBlock;
-(void)commentsRefreshWithComplationBlock:(ComplationRefreshCommentsBlock)complationBlock;

@end
