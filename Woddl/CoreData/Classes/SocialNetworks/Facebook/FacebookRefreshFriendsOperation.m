//
//  FacebookRefreshFriendsOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 24.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookRefreshFriendsOperation.h"
#import "FacebookRequest.h"

@implementation FacebookRefreshFriendsOperation

#pragma mark - Initialization

-(id)initFacebookRefreshFriendsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_
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
    FacebookRequest* fbRequest = [[FacebookRequest alloc] init];
    NSArray* result = [fbRequest getFriendsWithToken:self.token];
    [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookRefreshFriendsDidFinishWithFriends:) withObject:result waitUntilDone:YES];
}

@end
