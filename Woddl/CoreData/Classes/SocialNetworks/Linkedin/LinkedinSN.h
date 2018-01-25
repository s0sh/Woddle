//
//  LinkedinSN.h
//  Woddl
//
//  Created by Sergii Gordiienko on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SocialNetwork.h"


@interface LinkedinSN : SocialNetwork

@property (nonatomic,strong) ComplationPostBlock postCompletionBlock;
@property (nonatomic,strong) completionAddStatusBlock addStatusCompletionBlock;
@property (nonatomic,strong) completionRefreshGroupsBlock refreshGroupsCompletionBlock;
@property (nonatomic,strong) ComplationGetPostBlock getPostCompletionBlock;


- (void)loadMoreGroupsPostsWithGroupID:(NSString *)groupID from:(NSString *)from to:(NSString *)to;

@end
