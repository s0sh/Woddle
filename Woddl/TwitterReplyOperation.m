//
//  TwitterReplyOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 29.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "TwitterReplyOperation.h"
#import "TwitterRequest.h"

@implementation TwitterReplyOperation

@synthesize objectID;
@synthesize token;

#pragma mark - Initialization

-(id)initTwitterReplyOperationWithToken:(NSString*)token_ andPostID:(NSString*)postID andMessage:(NSString*)message andImage:(NSData*)image withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        token = token_;
        objectID = postID;
        self.message = message;
        self.imageData = image;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    TwitterRequest* request = [[TwitterRequest alloc] init];
    NSDictionary* result = [request replyToTwittWithMessage:self.message andTwittID:objectID andImage:self.imageData andToken:token];
    if(result)
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterReplyDidFinishWithSuccess:) withObject:result waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterReplyDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}
@end
