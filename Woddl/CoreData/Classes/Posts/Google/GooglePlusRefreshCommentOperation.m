//
//  GooglePlusRefreshCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 09.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "GooglePlusRefreshCommentOperation.h"
#import "GoogleRequest.h"

@implementation GooglePlusRefreshCommentOperation

-(id)initGooglePlusRefreshCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID withDelegate:(id)delegate_
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
    GoogleRequest* request = [[GoogleRequest alloc] initWithToken:self.token];
    NSArray* result = [request getCommentsFromActivityID:self.objectID];
    [(NSObject *)delegate performSelectorOnMainThread:@selector(googlePlusRefreshCommentDidFinishWithComments:) withObject:result waitUntilDone:YES];
}

@end
