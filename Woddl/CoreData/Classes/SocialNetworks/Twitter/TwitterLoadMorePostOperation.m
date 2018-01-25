//
//  TwitterLoadMorePostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 30.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "TwitterLoadMorePostOperation.h"
#import "TwitterRequest.h"

@implementation TwitterLoadMorePostOperation

#pragma mark - Initialization

-(id)initTwitterLoadMorePostOperationWithToken:(NSString*)token from:(NSString*)from to:(NSString*)to withDelegate:(id)delegate_
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
    TwitterRequest* request = [[TwitterRequest alloc] init];
    NSArray* posts = [request getPostsWithToken:self.token fromID:self.from to:self.to];
    if (self.isCancelled)
    {
        return ;
    }
    [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterLoadMorePostDidFinishWithPosts:) withObject:posts waitUntilDone:YES];
}
@end
