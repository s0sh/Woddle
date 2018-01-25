//
//  FacebookRefreshGroupsOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 18.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookRefreshGroupsOperation.h"
#import "FacebookGroupsInfo.h"

@implementation FacebookRefreshGroupsOperation

#pragma mark - Initialization

-(id)initFacebookRefreshGroupsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_
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
    FacebookGroupsInfo* groupsInfo = [[FacebookGroupsInfo alloc] init];
    NSArray* groups = [groupsInfo getAllGroupsWithUserID:self.userID andToken:self.token];
    //facebookRefreshGroupsDidFinishWithGroups
    [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookRefreshGroupsDidFinishWithGroups:) withObject:groups waitUntilDone:YES];
}

@end
