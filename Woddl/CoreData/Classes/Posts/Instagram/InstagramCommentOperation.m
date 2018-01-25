//
//  InstagramCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 26.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "InstagramCommentOperation.h"
#import "InstagramRequest.h"

@implementation InstagramCommentOperation

@synthesize token;
@synthesize objectID;
@synthesize message;

-(id)initInstagramCommentOperationWithMesage:(NSString*)message_ andToken:(NSString*)token_ andPostID:(NSString*)postID withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        token = token_;
        objectID = postID;
        message = message_;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    InstagramRequest* request = [[InstagramRequest alloc] init];
    NSDictionary* reply = [request addCommentOnObjectID:objectID withToken:token andMessage:message];
    if(reply)
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(instagramCommentDidFinishWithCommentID:) withObject:[reply objectForKey:@"id"] waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(instagramCommentDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

@end
