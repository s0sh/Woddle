//
//  GooglePlusRefreshFriendsOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 25.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "GooglePlusRefreshFriendsOperation.h"
#import "GoogleRequest.h"

@implementation GooglePlusRefreshFriendsOperation

#pragma mark - Initialization

-(id)initGooglePlusRefreshFriendsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_
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
    GoogleRequest* googleRequest = [[GoogleRequest alloc] initWithToken:self.token];
    NSArray* result = [googleRequest getFriends];
    [(NSObject *)delegate performSelectorOnMainThread:@selector(googlePlusRefreshFriendsDidFinishWithFriends:) withObject:result waitUntilDone:YES];
}

@end
