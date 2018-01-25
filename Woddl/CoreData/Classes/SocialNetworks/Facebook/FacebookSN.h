//
//  FacebookSN.h
//  Woddl
//
//  Created by Sergii Gordiienko on 02.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SocialNetwork.h"
#import "Post.h"

@interface FacebookSN : SocialNetwork

@property (nonatomic, retain) NSNumber * isChatEnabled;

@property (nonatomic,strong) ComplationPostBlock postCompletionBlock;
@property (nonatomic,strong) completionAddStatusBlock addStatusCompletionBlock;
@property (nonatomic, strong) completionSearchPostsBlock searchPostBlock;
@property (nonatomic,strong) ComplationGetPostBlock getPostCompletionBlock;

- (void)loadMoreGroupsPostsWithGroupID:(NSString *)groupID andGroupType:(NSInteger)type from:(NSString *)from to:(NSString *)to;

@end
