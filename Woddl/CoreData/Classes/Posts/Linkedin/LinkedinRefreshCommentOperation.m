//
//  LinkedinGetCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 09.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinRefreshCommentOperation.h"
#import "LinkedinRequest.h"

@implementation LinkedinRefreshCommentOperation

-(id)initLinkedinRefreshCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID isGroupPost:(BOOL)isGroupPost withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        self.token = token_;
        self.objectID = postID;
        self.isGroupPost = isGroupPost;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    LinkedinRequest* request = [[LinkedinRequest alloc] init];
    if(!self.isGroupPost)
    {
        NSArray* result = [request getCommentsFromPostID:self.objectID andToken:self.token];
        [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinRefreshCommentDidFinishWithComments:) withObject:result waitUntilDone:YES];
    }
    else
    {
        NSArray* result = [request getCommentsFromGroupPostID:self.objectID andToken:self.token];
        [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinRefreshCommentDidFinishWithComments:) withObject:result waitUntilDone:YES];
    }
}

@end