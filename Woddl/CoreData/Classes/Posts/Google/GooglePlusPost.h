//
//  GooglePlusPost.h
//  Woddl
//
//  Created by Sergii Gordiienko on 28.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Post.h"

@class GoogleOthersProfile;

@interface GooglePlusPost : Post

@property (nonatomic, retain) NSSet *likedBy;

@property (nonatomic,strong) ComplationRefreshCommentsBlock getCommentComplationBlock;
@property (nonatomic,strong) ComplationLoadMoreCommentsBlock loadMoreCommentComplationBlock;

-(void)commentsRefreshWithComplationBlock:(ComplationRefreshCommentsBlock)complationBlock;
-(void)commentsLoadMoreFrom:(NSUInteger)from to:(NSUInteger)to withComplationBlock:(ComplationLoadMoreCommentsBlock)complationBlock;

@end

@interface GooglePlusPost (CoreDataGeneratedAccessors)

- (void)addLikedByObject:(GoogleOthersProfile *)value;
- (void)removeLikedByObject:(GoogleOthersProfile *)value;
- (void)addLikedBy:(NSSet *)values;
- (void)removeLikedBy:(NSSet *)values;

@end
