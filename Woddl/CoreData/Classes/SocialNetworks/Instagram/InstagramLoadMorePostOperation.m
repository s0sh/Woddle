//
//  InstagramLoadMorePostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 31.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "InstagramLoadMorePostOperation.h"
#import "InstagramRequest.h"

@implementation InstagramLoadMorePostOperation

#pragma mark - Initialization

-(id)initInstagramLoadMorePostOperationWithToken:(NSString*)token from:(NSString*)from to:(NSString*)to withDelegate:(id)delegate_
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
    InstagramRequest* request = [[InstagramRequest alloc] init];
    NSArray* posts = [request loadMorePostsWithToken:self.token andUserID:@"" andCount:[self.to intValue] maxID:self.from];
    if (self.isCancelled)
    {
        return ;
    }
    [(NSObject *)delegate performSelectorOnMainThread:@selector(instagramLoadMorePostDidFinishWithPosts:) withObject:posts waitUntilDone:YES];
}
@end
