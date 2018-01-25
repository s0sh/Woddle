//
//  FoursquareRefreshFriendsOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 25.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FoursquareRefreshFriendsOperation.h"
#import "FoursquareRequest.h"

@implementation FoursquareRefreshFriendsOperation

#pragma mark - Initialization

-(id)initFoursquareRefreshFriendsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_
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
    FoursquareRequest* foursquareRequest = [[FoursquareRequest alloc] init];
    NSArray* result = [foursquareRequest getFriendsWithToken:self.token];
    [(NSObject *)delegate performSelectorOnMainThread:@selector(foursquareRefreshFriendsDidFinishWithFriends:) withObject:result waitUntilDone:YES];
}

@end
