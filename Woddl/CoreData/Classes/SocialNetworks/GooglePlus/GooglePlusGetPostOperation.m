//
//  GooglePlusGetPostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 04.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "GooglePlusGetPostOperation.h"
#import "GoogleRequest.h"

@implementation GooglePlusGetPostOperation

#pragma mark - Initialization

-(id)initGooglePlusGetPostOperationWithToken:(NSString*)token userID:(NSString *)userID andCount:(NSUInteger)count_ withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        self.token = token;
        count = count_;
        self.userID = userID;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    GoogleRequest* request = [[GoogleRequest alloc] initWithToken:self.token];
     NSArray* posts = [request getPostsWithCount:count andUserID:self.userID];
    if (self.isCancelled)
    {
        return ;
    }
    [(NSObject *)delegate performSelectorOnMainThread:@selector(googlePlusGetPostDidFinishWithPosts:) withObject:posts waitUntilDone:YES];
}
@end
