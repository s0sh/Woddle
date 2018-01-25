//
//  LinkedinLoadMoreCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 09.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinLoadMoreCommentOperation.h"
#import "LinkedinRequest.h"

@implementation LinkedinLoadMoreCommentOperation

-(id)initLinkedinLoadMoreCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID from:(NSInteger)from to:(NSInteger)to isGroupPost:(BOOL)isGroupPost withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        self.token = token_;
        self.objectID = postID;
        self.from = from;
        self.to = to;
        self.isGroupPost = isGroupPost;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    if(!self.isGroupPost)
    {
        LinkedinRequest* request = [[LinkedinRequest alloc] init];
        NSArray* result = [request getMoreCommentsFromPostID:self.objectID andToken:self.token];
        [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinLoadMoreCommentDidFinishWithComments:) withObject:result waitUntilDone:YES];
    }
    else
    {
        LinkedinRequest* request = [[LinkedinRequest alloc] init];
        NSArray* result = [request loadMoreCommentsFromGroupPostID:self.objectID from:self.from count:self.to andToken:self.token];
        [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinLoadMoreCommentDidFinishWithComments:) withObject:result waitUntilDone:YES];
    }
}

@end
