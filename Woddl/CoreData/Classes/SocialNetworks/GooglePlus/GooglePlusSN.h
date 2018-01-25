//
//  GooglePlusSN.h
//  Woddl
//
//  Created by Sergii Gordiienko on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SocialNetwork.h"
#import "GooglePlusAPI.h"


@interface GooglePlusSN : SocialNetwork <GooglePlusActivityDelegate>

@property (nonatomic, retain) NSString * updateToken;

@property (nonatomic, strong) ComplationPostBlock postCompletionBlock;
@property (nonatomic, strong) completionSearchPostsBlock searchPostBlock;

-(void)getPosts;
- (void)getPostsFrom:(NSString*)from to:(NSString*)to isSelfPosts:(BOOL)isSelf;

- (void)addStatusWithMessage:(NSString*)message andImages:(NSArray*)images andLocation:(WDDLocation*)location withCompletionBlock:(completionAddStatusBlock)completionBlock;
- (void)getPostsWithCompletionBlock:(ComplationGetPostBlock)completionBlock;

- (void)getFriends;

@end
