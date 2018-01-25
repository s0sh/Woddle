//
//  TwitterGetPostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 13.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "TwitterGetPostOperation.h"
#import "TwitterRequest.h"

@implementation TwitterGetPostOperation
@synthesize token;
@synthesize userID;

#pragma mark - Initialization

-(id)initTwitterGetPostOperationWithToken:(NSString*)token_ andUserID:(NSString*)userID_ andCount:(NSUInteger)count_ withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        token = token_;
        userID = userID_;
        count = count_;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    TwitterRequest* request = [[TwitterRequest alloc] init];
    NSArray* posts = [request getPostsWithToken:token andUserID:userID andCount:count];
    if (self.isCancelled)
    {
        return ;
    }
    [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterGetPostDidFinishWithPosts:) withObject:posts waitUntilDone:YES];
}
@end
