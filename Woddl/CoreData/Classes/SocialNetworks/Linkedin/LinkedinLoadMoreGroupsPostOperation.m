//
//  LinkedinLoadMoreGroupsPostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 09.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "LinkedinLoadMoreGroupsPostOperation.h"
#import "LinkedinRequest.h"

@implementation LinkedinLoadMoreGroupsPostOperation

#pragma mark - Initialization

-(id)initLinkedinLoadMoreGroupsPostOperationWithToken:(NSString*)token groupID:(NSString*)groupID from:(NSString*)from to:(NSString*)to withDelegate:(id)delegate_
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
    LinkedinRequest* request = [[LinkedinRequest alloc] init];
    
    NSArray* posts = [request getGroupsPostsWithToken:self.token andGroupID:self.groupID from:[self.from intValue] count:[self.to intValue]];
    
    if (self.isCancelled)
    {
        return ;
    }
    
    [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinLoadMoreGroupsPostDidFinishWithPosts:) withObject:posts waitUntilDone:YES];
}
@end
