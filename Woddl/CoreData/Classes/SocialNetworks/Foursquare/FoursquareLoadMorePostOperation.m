//
//  FoursquareLoadMorePostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 31.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FoursquareLoadMorePostOperation.h"
#import "FoursquareRequest.h"

@implementation FoursquareLoadMorePostOperation

#pragma mark - Initialization

-(id)initFoursquareLoadMorePostOperationWithToken:(NSString*)token from:(NSString*)from to:(NSString*)to withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        self.count = [from intValue] + [to intValue];
        self.token = token;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    FoursquareRequest* request = [[FoursquareRequest alloc] init];
    NSArray* posts = [request getPostsWithToken:self.token andUserID:@"" andCount:self.count];
    if (self.isCancelled)
    {
        return ;
    }
    [(NSObject *)delegate performSelectorOnMainThread:@selector(foursquareLoadMorePostDidFinishWithPosts:) withObject:posts waitUntilDone:YES];
}
@end
