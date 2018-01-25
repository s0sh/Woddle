//
//  GooglePlusLoadMorePostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 30.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "GooglePlusLoadMorePostOperation.h"
#import "GoogleRequest.h"

@implementation GooglePlusLoadMorePostOperation

#pragma mark - Initialization

-(id)initGooglePlusLoadMorePostOperationWithToken:(NSString*)token from:(NSString*)from to:(NSString*)to withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        self.from = from;
        self.to = to;
        self.token = token;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    GoogleRequest* request = [[GoogleRequest alloc] initWithToken:self.token];
    NSArray* posts = [request getPostsWithCount:[self.to intValue] from:self.from];
    if (self.isCancelled)
    {
        return ;
    }
    [(NSObject *)delegate performSelectorOnMainThread:@selector(googlePlusLoadMorePostDidFinishWithPosts:) withObject:posts waitUntilDone:YES];
}
@end
