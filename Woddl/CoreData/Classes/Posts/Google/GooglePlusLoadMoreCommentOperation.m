//
//  GooglePlusLoadMoreCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 09.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "GooglePlusLoadMoreCommentOperation.h"
#import "GoogleRequest.h"

@implementation GooglePlusLoadMoreCommentOperation

-(id)initGooglePlusLoadMoreCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID andCount:(NSUInteger)count withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        self.token = token_;
        self.objectID = postID;
        self.count = count;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    GoogleRequest* request = [[GoogleRequest alloc] initWithToken:self.token];
    NSArray* result = [request getCommentsFromActivityID:self.objectID count:self.count];
    [(NSObject *)delegate performSelectorOnMainThread:@selector(googlePlusLoadMoreCommentDidFinishWithComments:) withObject:result waitUntilDone:YES];
}

@end
