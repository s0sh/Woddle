//
//  LinkedinGetPostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 13.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinGetPostOperation.h"
#import "LinkedinRequest.h"

@implementation LinkedinGetPostOperation
@synthesize token;
@synthesize userID;

#pragma mark - Initialization

-(id)initLinkedinGetPostOperationWithToken:(NSString*)token_ andUserID:(NSString*)userID_ andCount:(NSUInteger)count_ andGroups:(NSArray *) groups withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        token = token_;
        userID = userID_;
        count = count_;
        self.groups = groups;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    LinkedinRequest* request = [[LinkedinRequest alloc] init];
    NSArray* posts = [request getPostsWithToken:self.token andUserID:self.userID andGroups:self.groups andCount:count];
    if (self.isCancelled)
    {
        return ;
    }
    [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinGetPostDidFinishWithPosts:) withObject:posts waitUntilDone:YES];
}
@end
