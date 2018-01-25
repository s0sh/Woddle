//
//  LinkedinLikeOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 15.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinLikeOperation.h"
#import "LinkedinRequest.h"

@implementation LinkedinLikeOperation

@synthesize objectID;
@synthesize token;
@synthesize myID;

#pragma mark - Initialization

-(id)initLinkedinLikeOperationWithToken:(NSString*)token_ andPostID:(NSString*)postID andMyID:(NSString*)myID_ isGroupPost:(BOOL)isGroupPost withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        token = token_;
        objectID = postID;
        myID = myID_;
        self.isGroupPost = isGroupPost;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    LinkedinRequest* request = [[LinkedinRequest alloc] init];
    if (!self.isGroupPost)
    {
        NSDictionary* result = [request isPostLikedMe:objectID withToken:token andMyID:myID];
        if([result objectForKey:@"error"])
        {
            [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinLikingError:) withObject:result waitUntilDone:YES];
        }
        else
        {
            BOOL isLiked = [[result objectForKey:@"isLiked"] boolValue];
            if(!isLiked)
            {
                BOOL isSuccess = [request setLikeOnObjectID:objectID withToken:token];
                if (isSuccess)
                {
                    [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinLikeDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
                }
                else
                {
                    [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinLikeDidFinishWithFail) withObject:nil waitUntilDone:YES];
                }
            }
            else
            {
                BOOL isSuccess = [request setUnlikeOnObjectID:objectID withToken:token];
                if (isSuccess)
                {
                    [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinUnlikeDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
                }
                else
                {
                    [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinUnlikeDidFinishWithFail) withObject:nil waitUntilDone:YES];
                }
            }
        }
    }
    else
    {
        NSDictionary* result = [request isGroupPostLikedMe:objectID withToken:token andMyID:myID];
        if([result objectForKey:@"error"])
        {
            [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinLikingError:) withObject:result waitUntilDone:YES];
        }
        else
        {
            BOOL isLiked = [[result objectForKey:@"isLiked"] boolValue];
            if(!isLiked)
            {
                BOOL isSuccess = [request setLikeOnGroupObjectID:objectID withToken:token];
                if (isSuccess)
                {
                    [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinLikeDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
                }
                else
                {
                    [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinLikeDidFinishWithFail) withObject:nil waitUntilDone:YES];
                }
            }
            else
            {
                BOOL isSuccess = [request setUnlikeOnGroupObjectID:objectID withToken:token];
                if (isSuccess)
                {
                    [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinUnlikeDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
                }
                else
                {
                    [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinUnlikeDidFinishWithFail) withObject:nil waitUntilDone:YES];
                }
            }
        }
    }
}

@end
