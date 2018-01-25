//
//  LinkedinPost.h
//  Woddl
//
//  Created by Sergii Gordiienko on 08.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Post.h"
#import "LinkedinOthersProfile.h"


@interface LinkedinPost : Post

@property (nonatomic, retain) NSString * updateKey;
@property (nonatomic, retain) NSSet *likedBy;
@property (nonatomic,strong) ComplationLikingBlock completionBlock;
@property (nonatomic,strong) FailLikingBlock failBlock;
@property (nonatomic,strong) ComplationCommentBlock complCommentBlock;
@property (nonatomic,strong) FailCommentBlock failComplationCommentBlock;
@property (nonatomic,strong) ComplationRefreshCommentsBlock getCommentComplationBlock;
@property (nonatomic,strong) ComplationLoadMoreCommentsBlock loadMoreCommentComplationBlock;

-(void)addLikeWithCompletionBlock:(ComplationLikingBlock)complationBlock_ andFailBlock:(FailLikingBlock)failBlock_;
-(void)addCommentWithMessage:(NSString*)message andCompletionBlock:(ComplationCommentBlock)complationBlock withFailBlock:(FailCommentBlock)failCommentBlock;
-(void)commentsRefreshWithComplationBlock:(ComplationRefreshCommentsBlock)complationBlock;
-(void)commentsLoadMoreFrom:(NSUInteger)from to:(NSUInteger)to withComplationBlock:(ComplationLoadMoreCommentsBlock)complationBlock;

@end

@interface LinkedinPost (CoreDataGeneratedAccessors)

- (void)addLikedByObject:(LinkedinOthersProfile *)value;
- (void)removeLikedByObject:(LinkedinOthersProfile *)value;
- (void)addLikedBy:(NSSet *)values;
- (void)removeLikedBy:(NSSet *)values;

@end