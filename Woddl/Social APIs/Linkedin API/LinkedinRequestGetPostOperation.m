//
//  LinkedinRequestGetPostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 11.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "LinkedinRequestGetPostOperation.h"
#import "LinkedinRequest.h"

@implementation LinkedinRequestGetPostOperation

@synthesize completionBlock;
@synthesize token;

-(id)initLinkedinRequestGetPostOperationWithToken:(NSString*)token_ userID:(NSString*)userID count:(NSUInteger)count isSelfPosts:(BOOL)isSelfPosts withComplationBlock:(ComplationGetPostBlock)complationBlock_;
{
    if (self = [super init])
    {
        token = token_;
        completionBlock = complationBlock_;
        self.userID = userID;
        self.count = count;
        self.isSelfPosts = isSelfPosts;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    if (self.isCancelled)
    {
        completionBlock = nil;
        return ;
    }
    LinkedinRequest* request = [[LinkedinRequest alloc] init];
    NSArray* result = [request getPostsWithToken:self.token andUserID:self.userID andCount:self.count isSelf:self.isSelfPosts];
    if (self.isCancelled)
    {
        completionBlock = nil;
        return ;
    }
    completionBlock(result);
    completionBlock = nil;
}


@end
