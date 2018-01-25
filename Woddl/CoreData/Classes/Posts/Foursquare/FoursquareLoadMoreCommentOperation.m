//
//  LinkedinLoadMoreCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 10.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FoursquareLoadMoreCommentOperation.h"
#import "FoursquareRequest.h"

@implementation FoursquareLoadMoreCommentOperation

-(id)initFoursquareLoadMoreCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID withDelegate:(id)delegate_
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
    FoursquareRequest* request = [[FoursquareRequest alloc] init];
    NSArray* result = [request getCommentsFromCheckinID:self.objectID andAccessToken:self.token];
    [(NSObject *)delegate performSelectorOnMainThread:@selector(foursquareLoadMoreCommentDidFinishWithComments:) withObject:result waitUntilDone:YES];
}

@end
