//
//  InstagramRefreshFriendsOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 25.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "InstagramRefreshFriendsOperation.h"
#import "InstagramRequest.h"

@implementation InstagramRefreshFriendsOperation

#pragma mark - Initialization

-(id)initInstagramRefreshFriendsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        self.token = token;
        self.userID = userID;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    InstagramRequest* instagramRequest = [[InstagramRequest alloc] init];
    NSArray* result = [instagramRequest getFriendsWithToken:self.token];
    [(NSObject *)delegate performSelectorOnMainThread:@selector(instagramRefreshFriendsDidFinishWithFriends:) withObject:result waitUntilDone:YES];
}

@end
