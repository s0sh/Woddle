//
//  TwitterSN.h
//  Woddl
//
//  Created by Sergii Gordiienko on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SocialNetwork.h"

@class TwitterOthersProfile;

@interface TwitterSN : SocialNetwork

@property (nonatomic,strong) ComplationGetPostBlock getPostsComplationBlock;
@property (nonatomic,strong) ComplationPostBlock postCompletionBlock;
@property (nonatomic,strong) completionAddStatusBlock addStatusCompletionBlock;
@property (nonatomic, strong) completionSearchPostsBlock searchPostBlock;


- (void)addPostToDataBase:(NSDictionary*)postDict;
- (TwitterOthersProfile*)twitterProfileWithDescription:(NSDictionary*)description;

@end
