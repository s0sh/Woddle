//
//  TwitterRefreshCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 03.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "TwitterRefreshCommentOperation.h"
#import "TwitterRequest.h"

@implementation TwitterRefreshCommentOperation

-(id)initTwitterRefreshCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID userName:(NSString*)userName sinceID:(NSString*)sinceID withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        self.token = token_;
        self.objectID = postID;
        self.userName = userName;
        self.sinceID = sinceID;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    TwitterRequest* request = [[TwitterRequest alloc] init];
    NSString* track = [NSString stringWithFormat:@"@%@",self.userName];
    NSArray* result = [request getCommentsWithTrack:track sinceID:self.objectID];
    [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterRefreshCommentDidFinishWithComments:) withObject:result waitUntilDone:YES];
}

@end
