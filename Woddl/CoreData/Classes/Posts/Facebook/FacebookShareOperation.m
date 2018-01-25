//
//  FacebookShareOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 18.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookShareOperation.h"
#import "FacebookRequest.h"

@implementation FacebookShareOperation

@synthesize token;
@synthesize message;
@synthesize link;

-(id)initFacebookShareOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andLink:(NSString*)link_ withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        token = token_;
        message = message_;
        link = link_;
        delegate = delegate_;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    FacebookRequest* request = [[FacebookRequest alloc] init];
    if([request sharePostWithToken:token andMessage:message withLink:link])
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookShareDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookShareDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

@end
