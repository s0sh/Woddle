//
//  FacebookLoadMoreGroupsPostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 06.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "FacebookLoadMoreGroupsPostOperation.h"
#import "FacebookRequest.h"

@implementation FacebookLoadMoreGroupsPostOperation

#pragma mark - Initialization

-(id)initFacebookLoadMoreGroupsPostOperationWithToken:(NSString*)token groupID:(NSString*)groupID from:(NSString*)from to:(NSString*)to withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        self.from = from;
        self.to = to;
        self.token = token;
        self.groupID = groupID;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    FacebookRequest* request = [[FacebookRequest alloc] init];
    
    NSArray* posts = [request loadMorePostsWithTokenFromGroup:self.groupID untilTime:self.from count:[self.to integerValue] andGroupType:1 andToken:self.token];
    
    if (self.isCancelled)
    {
        return ;
    }
    
    [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookLoadMoreGroupsPostDidFinishWithPosts:) withObject:posts waitUntilDone:YES];
}
@end
