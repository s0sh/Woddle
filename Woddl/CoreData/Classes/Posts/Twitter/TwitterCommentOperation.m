//
//  TwitterCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 03.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "TwitterCommentOperation.h"
#import "TwitterRequest.h"

@implementation TwitterCommentOperation

@synthesize token;
@synthesize objectID;
@synthesize message;

-(id)initTwitterCommentOperationWithMesage:(NSString*)message_ Token:(NSString*)token_ andPostID:(NSString*)postID andUserID:(NSString*)userID withDelegate:(id)delegate_
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
    TwitterRequest* request = [[TwitterRequest alloc] init];
    
    NSDictionary* reply = [request replyToTwittWithMessage:message andTwittID:objectID andImage:nil andToken:token];
    if(reply)
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterCommentDidFinishWithDictionary:) withObject:reply waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterCommentDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

@end
