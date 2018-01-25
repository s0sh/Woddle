//
//  InstagramRefreshCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 10.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "InstagramRefreshCommentOperation.h"
#import "InstagramRequest.h"

@implementation InstagramRefreshCommentOperation

-(id)initInstagramRefreshCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        self.token = token_;
        self.objectID = postID;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    InstagramRequest* request = [[InstagramRequest alloc] init];
    NSArray* result = [request getCommentsWithPostID:self.objectID andToken:self.token];
    [(NSObject *)delegate performSelectorOnMainThread:@selector(instagramRefreshCommentDidFinishWithComments:) withObject:result waitUntilDone:YES];
}

@end
