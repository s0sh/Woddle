//
//  LinkedinRefreshGroupsOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 09.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "LinkedinRefreshGroupsOperation.h"
#import "LinkedinRequest.h"

@implementation LinkedinRefreshGroupsOperation

#pragma mark - Initialization

-(id)initLinkedinRefreshGroupsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_
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
    LinkedinRequest* groupsInfo = [[LinkedinRequest alloc] init];
    NSArray* groups = [groupsInfo getGroupsWithToken:self.token];
    
    [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinRefreshGroupsDidFinishWithGroups:) withObject:groups waitUntilDone:YES];
}

@end
