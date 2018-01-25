//
//  LinkedinCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 26.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinCommentOperation.h"
#import "LinkedinRequest.h"

@implementation LinkedinCommentOperation

@synthesize token;
@synthesize objectID;
@synthesize message;
@synthesize userID;

-(id)initLinkedinCommentOperationWithMesage:(NSString*)message_ andToken:(NSString*)token_ andPostID:(NSString*)postID andUserID:(NSString*)userID_ isGroupPost:(BOOL)isGroupPost withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        token = token_;
        objectID = postID;
        message = message_;
        userID = userID_;
        self.isGroupPost = isGroupPost;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    LinkedinRequest* request = [[LinkedinRequest alloc] init];
    if(!self.isGroupPost)
    {
        NSDictionary* reply = [request addCommentToPost:objectID withToken:token andMessage:message andUserID:userID];
        if(reply)
        {
            if([reply objectForKey:@"error"])
            {
                [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinCommentDidFinishWithFail:) withObject:reply waitUntilDone:YES];
            }
            else
            {
                [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinCommentDidFinishWithDictionary:) withObject:reply waitUntilDone:YES];
            }
        }
        else
        {
            [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinCommentDidFinishWithFail:) withObject:nil waitUntilDone:YES];
        }
    }
    else
    {
        NSDictionary* reply = [request addCommentToGroupPost:objectID withToken:token andMessage:message andUserID:userID];
        if(reply)
        {
            if([reply objectForKey:@"error"])
            {
                [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinCommentDidFinishWithFail:) withObject:reply waitUntilDone:YES];
            }
            else
            {
                [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinCommentDidFinishWithDictionary:) withObject:reply waitUntilDone:YES];
            }
        }
        else
        {
            [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinCommentDidFinishWithFail:) withObject:nil waitUntilDone:YES];
        }

    }
}

@end
