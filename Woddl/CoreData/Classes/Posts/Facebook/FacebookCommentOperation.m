//
//  FacebookCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 18.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookCommentOperation.h"
#import "FacebookRequest.h"

@implementation FacebookCommentOperation

@synthesize token;
@synthesize objectID;
@synthesize message;

-(id)initFacebookCommentOperationWithMesage:(NSString*)message_ Token:(NSString*)token_ andPostID:(NSString*)postID andUserID:(NSString*)userID withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        token = token_;
        objectID = postID;
        message = message_;
        self.userID = userID;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    FacebookRequest* request = [[FacebookRequest alloc] init];
    NSDictionary* reply = [request addCommentOnObjectID:objectID withUserID:self.userID withToken:token andMessage:message];
    if(reply)
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookCommentDidFinishWithDictionary:) withObject:reply waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookCommentDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

@end
