//
//  LinkedinPostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 20.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinPostOperation.h"
#import "Post.h"
#import "LinkedinRequest.h"
#import "UserProfile.h"

@implementation LinkedinPostOperation

@synthesize token;
@synthesize message;
@synthesize link;
@synthesize description;
@synthesize picture;

-(id)initLinkedinPostOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andPost:(Post*)post withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        token = token_;
        message = message_;
        delegate = delegate_;
        if(post)
        {
            link = post.linkURLString;
            description = post.text;
            picture = post.author.avatarRemoteURL;
        }
        
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    LinkedinRequest* request = [[LinkedinRequest alloc] init];
    if([request addStatusPostWithToken:token andMessage:message withLink:link andDescription:description andImageURL:picture])
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinPostDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinPostDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

@end
