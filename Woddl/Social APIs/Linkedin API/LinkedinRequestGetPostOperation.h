//
//  LinkedinRequestGetPostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 11.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocialNetwork.h"

@interface LinkedinRequestGetPostOperation : NSOperation

@property (nonatomic,strong) ComplationGetPostBlock completionBlock;
@property (nonatomic, strong) NSString* token;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, assign) BOOL isSelfPosts;
@property (nonatomic, strong) NSString* userID;

-(id)initLinkedinRequestGetPostOperationWithToken:(NSString*)token_ userID:(NSString*)userID count:(NSUInteger)count isSelfPosts:(BOOL)isSelfPosts withComplationBlock:(ComplationGetPostBlock)complationBlock_;

@end
