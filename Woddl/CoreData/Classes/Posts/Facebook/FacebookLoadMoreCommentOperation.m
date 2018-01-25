//
//  FacebookLoadMoreCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 10.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookLoadMoreCommentOperation.h"
#import "FacebookRequest.h"

@implementation FacebookLoadMoreCommentOperation

-(id)initFacebookLoadMoreCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID andCount:(NSUInteger)count offset:(NSUInteger)offset withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        self.token = token_;
        self.objectID = postID;
        self.count = count;
        self.offset = offset;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    FacebookRequest* request = [[FacebookRequest alloc] init];
    NSArray* result = [request getCommentsOnPostID:self.objectID offset:self.offset withToken:self.token];
    [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookLoadMoreCommentDidFinishWithComments:) withObject:result waitUntilDone:YES];
}

@end
