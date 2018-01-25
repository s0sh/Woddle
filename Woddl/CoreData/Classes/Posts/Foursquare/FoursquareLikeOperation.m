//
//  FoursquareLikeOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 16.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FoursquareLikeOperation.h"
#import "FoursquareRequest.h"

@implementation FoursquareLikeOperation

@synthesize objectID;
@synthesize token;
@synthesize myID;

#pragma mark - Initialization

-(id)initFoursquareLikeOperationWithToken:(NSString*)token_ andPostID:(NSString*)postID andMyID:(NSString*)myID_ withDelegate:(id)delegate_
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
    FoursquareRequest* request = [[FoursquareRequest alloc] init];
    if(![request isPostLikedMe:objectID withToken:token andMyID:myID])
    {
        BOOL isSuccess = [request setLikeOnObjectID:objectID withToken:token];
        if (isSuccess)
            [(NSObject *)delegate performSelectorOnMainThread:@selector(foursquareLikeDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
        else
            [(NSObject *)delegate performSelectorOnMainThread:@selector(foursquareLikeDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
    else
    {
        BOOL isSuccess = [request setUnlikeOnObjectID:objectID withToken:token];
        if (isSuccess)
            [(NSObject *)delegate performSelectorOnMainThread:@selector(foursquareUnlikeDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
        else
            [(NSObject *)delegate performSelectorOnMainThread:@selector(foursquareUnlikeDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

@end
