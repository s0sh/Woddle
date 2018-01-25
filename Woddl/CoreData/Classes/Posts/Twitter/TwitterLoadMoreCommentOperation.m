//
//  TwitterLoadMoreCommentOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 03.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "TwitterLoadMoreCommentOperation.h"
#import "TwitterRequest.h"

@implementation TwitterLoadMoreCommentOperation

-(id)initTwitterLoadMoreCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID andUserName:(NSString*)userName from:(NSString*)from to:(NSInteger)to withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        self.token = token_;
        self.objectID = postID;
        self.userName = userName;
        self.from = from;
        self.to = to;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    TwitterRequest* request = [[TwitterRequest alloc] init];
    NSString* track = [NSString stringWithFormat:@"@%@",self.userName];
    NSArray* result = [request getCommentsWithTrack:track postID:self.objectID fromID:self.from count:self.to];
    [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterLoadMoreCommentDidFinishWithComments:) withObject:result waitUntilDone:YES];
}

@end
