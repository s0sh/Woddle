//
//  TwitterRetweetOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 19.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "TwitterRetweetOperation.h"
#import "TwitterRequest.h"

@implementation TwitterRetweetOperation

@synthesize objectID;
@synthesize token;

#pragma mark - Initialization

-(id)initTwitterRetweetOperationWithToken:(NSString*)token_ andPostID:(NSString*)postID withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        token = token_;
        objectID = postID;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    TwitterRequest* request = [[TwitterRequest alloc] init];
    if([request retweet:objectID withToken:token])
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterRetweetDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterRetweetDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}
@end
