//
//  FacebookGetPostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 13.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookGetPostOperation.h"
#import "FacebookRequest.h"

@implementation FacebookGetPostOperation
@synthesize token;
@synthesize userID;

#pragma mark - Initialization

-(id)initFacebookGetPostOperationWithToken:(NSString*)token_ andUserID:(NSString*)userID_ andCount:(NSUInteger)count_ andGroups:(NSArray*)groups withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        delegate = delegate_;
        token = token_;
        userID = userID_;
        count = count_;
        self.groups = groups;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
//    if (self.isCancelled)
//    {
//        return ;
//    }
//    FacebookRequest* request = [[FacebookRequest alloc] init];
//    BOOL result = [request getPostsWithToken:token
//                                   andUserID:userID andCount:count andGroups:self.groups withComplationBlock:^(NSArray *resultArray)
//    {
//        if (self.isCancelled)
//        {
//            return ;
//        }
//        [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookGetPostDidFinishWithPosts:) withObject:resultArray waitUntilDone:YES];
//    }];
//    
//    if (self.isCancelled)
//    {
//        return ;
//    }
//    
//    if(!result)
//    {
//        [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookGetPostDidFinishWithPosts:) withObject:nil waitUntilDone:YES];
//    }
}

@end
