//
//  FacebookLikeOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 14.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookLikeOperation.h"
#import "FacebookRequest.h"

@implementation FacebookLikeOperation

@synthesize objectID;
@synthesize token;
@synthesize myID;

#pragma mark - Initialization

-(id)initFacebookLikeOperationWithToken:(NSString*)token_ andPostID:(NSString*)postID andMyID:(NSString*)myID_ withDelegate:(id)delegate_
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
    FacebookRequest* request = [[FacebookRequest alloc] init];
    if(![request isPostLikedMe:objectID withToken:token andMyID:myID])
    {
        BOOL isSuccess = [request setLikeOnObjectID:objectID withToken:token];
        if (isSuccess)
            [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookLikeDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
        else
            [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookLikeDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
    else
    {
        BOOL isSuccess = [request setUnlikeOnObjectID:objectID withToken:token];
        if (isSuccess)
            [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookUnlikeDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
        else
            [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookUnlikeDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

@end
