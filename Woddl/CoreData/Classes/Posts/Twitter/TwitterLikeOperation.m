//
//  TwitterLikeOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 15.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "TwitterLikeOperation.h"
#import "TwitterRequest.h"

@implementation TwitterLikeOperation

@synthesize objectID;
@synthesize token;
@synthesize myID;

#pragma mark - Initialization

-(id)initTwitterLikeOperationWithToken:(NSString*)token_ andPostID:(NSString*)postID andMyID:(NSString*)myID_ withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        token = token_;
        objectID = postID;
        myID = myID_;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    TwitterRequest* request = [[TwitterRequest alloc] init];
    if(![request isPostLikedMe:objectID withToken:token andMyID:myID])
    {
        BOOL isSuccess = [request setLikeOnObjectID:objectID withToken:token];
        if (isSuccess)
            [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterLikeDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
        else
            [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterLikeDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
    else
    {
        BOOL isSuccess = [request setUnlikeOnObjectID:objectID withToken:token];
        if (isSuccess)
            [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterUnlikeDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
        else
            [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterUnlikeDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}
@end
