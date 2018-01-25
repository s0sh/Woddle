//
//  InstagramLikeOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 16.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "InstagramLikeOperation.h"
#import "InstagramRequest.h"

@implementation InstagramLikeOperation

@synthesize objectID;
@synthesize token;
@synthesize myID;

#pragma mark - Initialization

-(id)initInstagramLikeOperationWithToken:(NSString*)token_ andPostID:(NSString*)postID andMyID:(NSString*)myID_ withDelegate:(id)delegate_
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
    InstagramRequest* request = [[InstagramRequest alloc] init];
    if(![request isPostLikedMe:objectID withToken:token andMyID:myID])
    {
        BOOL isSuccess = [request setLikeOnObjectID:objectID withToken:token];
        if (isSuccess)
            [(NSObject *)delegate performSelectorOnMainThread:@selector(instagramLikeDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
        else
            [(NSObject *)delegate performSelectorOnMainThread:@selector(instagramLikeDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
    else
    {
        BOOL isSuccess = [request setUnlikeOnObjectID:objectID withToken:token];
        if (isSuccess)
            [(NSObject *)delegate performSelectorOnMainThread:@selector(instagramUnlikeDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
        else
            [(NSObject *)delegate performSelectorOnMainThread:@selector(instagramUnlikeDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

@end
