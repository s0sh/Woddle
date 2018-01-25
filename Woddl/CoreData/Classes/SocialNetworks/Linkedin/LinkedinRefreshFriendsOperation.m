//
//  LinkedinRefreshFriendsOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 25.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinRefreshFriendsOperation.h"
#import "LinkedinRequest.h"

@implementation LinkedinRefreshFriendsOperation

#pragma mark - Initialization

-(id)initLinkedinRefreshFriendsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_
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
    LinkedinRequest* linkedinRequest = [[LinkedinRequest alloc] init];
    NSArray* result = [linkedinRequest getFriendsWithToken:self.token];
    [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinRefreshFriendsDidFinishWithFriends:) withObject:result waitUntilDone:YES];
}

@end
