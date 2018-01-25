//
//  LinkedinLoadMorePostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 31.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinLoadMorePostOperation.h"
#import "LinkedinRequest.h"

@implementation LinkedinLoadMorePostOperation

#pragma mark - Initialization

-(id)initLinkedinLoadMorePostOperationWithToken:(NSString*)token andUserID:(NSString*)userID from:(NSString*)from to:(NSString*)to isSelfPosts:(BOOL)isSelf withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        self.from = from;
        self.to = to;
        self.token = token;
        self.userID = userID;
        self.isSelf = isSelf;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    LinkedinRequest* request = [[LinkedinRequest alloc] init];
    NSArray* posts = [request loadMorePostsWithToken:self.token andUserID:self.userID andCount:[self.to integerValue] from:[self.from integerValue] isSelf:self.isSelf];
    if (self.isCancelled)
    {
        return ;
    }
    [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinLoadMorePostDidFinishWithPosts:) withObject:posts waitUntilDone:YES];
}
@end
