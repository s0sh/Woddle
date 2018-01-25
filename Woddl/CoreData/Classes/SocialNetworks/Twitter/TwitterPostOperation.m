//
//  TwitterPostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 20.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "TwitterPostOperation.h"
#import "Post.h"
#import "TwitterRequest.h"
#import "UserProfile.h"

#import "WDDURLShorter.h"

@implementation TwitterPostOperation

@synthesize token;
@synthesize message;
@synthesize link;

-(id)initTwitterPostOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andPost:(Post*)post withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        token = token_;
        message = message_;
        delegate = delegate_;
        if(post)
        {
            link = post.linkURLString;
            if (!message.length)
            {
                message = [NSString stringWithFormat:@"%@ : %@", post.author.name, post.text];
            }
        }
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    TwitterRequest* request = [[TwitterRequest alloc] init];
       
    if([request addTwitt:message withLink:link andToken:token])
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterPostDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterPostDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

@end
