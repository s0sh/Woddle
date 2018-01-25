//
//  FacebookRefreshCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 10.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookRefreshCommentOperation.h"
#import "FacebookRequest.h"

@implementation FacebookRefreshCommentOperation

-(id)initFacebookRefreshCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID withDelegate:(id)delegate_
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
    FacebookRequest* request = [[FacebookRequest alloc] init];
    NSArray* result = [request getCommentsOnPostID:self.objectID withToken:self.token];
    [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookRefreshCommentDidFinishWithComments:) withObject:result waitUntilDone:YES];
}

@end
