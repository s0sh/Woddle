//
//  FacebookLoadMorePostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 03.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "FacebookLoadMorePostOperation.h"
#import "FacebookRequest.h"

@implementation FacebookLoadMorePostOperation

#pragma mark - Initialization

-(id)initFacebookLoadMorePostOperationWithToken:(NSString*)token from:(NSString*)from to:(NSString*)to withDelegate:(id)delegate_
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
    FacebookRequest* request = [[FacebookRequest alloc] init];
    NSArray* posts = [request loadMorePostsWithToken:self.token from:[self.from intValue] count:[self.to intValue]];
    if (self.isCancelled)
    {
        return ;
    }
    [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookLoadMorePostDidFinishWithPosts:) withObject:posts waitUntilDone:YES];
}
@end
