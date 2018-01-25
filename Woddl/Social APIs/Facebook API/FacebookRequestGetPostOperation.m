//
//  FacebookRequestGetPostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 27.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookRequestGetPostOperation.h"
#import "FacebookRequest.h"

@implementation FacebookRequestGetPostOperation

@synthesize completionBlock;
@synthesize token;
@synthesize dataDict;

-(id)initFacebookRequestGetPostOperationWithToken:(NSString*)token_ andDictionary:(NSDictionary*)data withComplationBlock:(ComplationGetFBPostBlock)complationBlock_
{
    if (self = [super init])
    {
        token = token_;
        completionBlock = complationBlock_;
        dataDict = data;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    if (self.isCancelled)
    {
        return ;
    }
    FacebookRequest* request = [[FacebookRequest alloc] init];
    NSDictionary* result = [request getPostWithDictionary:dataDict andToken:token];
    if (self.isCancelled)
    {
        return ;
    }
    completionBlock(result);
    completionBlock = nil;
}

@end
