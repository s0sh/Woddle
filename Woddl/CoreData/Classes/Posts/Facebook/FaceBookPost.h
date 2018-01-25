//
//  FaceBookPost.h
//  Woddl
//
//  Created by Sergii Gordiienko on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Post.h"

@class Comment, FaceBookOthersProfile;

@interface FaceBookPost : Post

@property (nonatomic, retain) NSSet *likedBy;
@property (nonatomic,strong) ComplationLikingBlock completionBlock;
@property (nonatomic,strong) ComplationCommentBlock completionCommentBlock;
@property (nonatomic,strong) FailCommentBlock failComplationCommentBlock;
@property (nonatomic,strong) ComplationShareBlock completionSharingBlock;
@property (nonatomic,strong) FailLikingBlock failBlock;
@property (nonatomic,strong) ComplationRefreshCommentsBlock getCommentComplationBlock;
@property (nonatomic,strong) ComplationLoadMoreCommentsBlock loadMoreCommentComplationBlock;

-(void)addLikeWithCompletionBlock:(ComplationLikingBlock)complationBlock andFailBlock:(FailLikingBlock)failBlock;
-(void)addCommentWithMessage:(NSString*)message andCompletionBlock:(ComplationCommentBlock)complationBlock withFailBlock:(FailCommentBlock)failCommentBlock;
-(void)shareWithCompletionBlock:(ComplationShareBlock)complationBlock;

-(void)commentsRefreshWithComplationBlock:(ComplationRefreshCommentsBlock)complationBlock;
-(void)commentsLoadMoreFrom:(NSUInteger)from to:(NSUInteger)to withComplationBlock:(ComplationLoadMoreCommentsBlock)complationBlock;

@end

@interface FaceBookPost (CoreDataGeneratedAccessors)

- (void)addLikedByObject:(FaceBookOthersProfile *)value;
- (void)removeLikedByObject:(FaceBookOthersProfile *)value;
- (void)addLikedBy:(NSSet *)values;
- (void)removeLikedBy:(NSSet *)values;

@end
