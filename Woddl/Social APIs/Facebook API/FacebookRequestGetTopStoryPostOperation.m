//
//  FacebookRequestGetTopStoryPostOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 21.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "FacebookRequestGetTopStoryPostOperation.h"
#import "FacebookRequest.h"

@implementation FacebookRequestGetTopStoryPostOperation
@synthesize completionBlock;
@synthesize token;
@synthesize dataDict;

-(id)initFacebookRequestGetTopStoryPostOperationWithToken:(NSString*)token_ andDictionary:(NSDictionary*)data withComplationBlock:(ComplationGetFBPostBlock)complationBlock_
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
    NSDictionary* result = [request getTopStoryPostWithDictionary:dataDict
                                                 forGroupWithInfo:nil
                                                         andToken:token];
    if (self.isCancelled)
    {
        return ;
    }
    completionBlock(result);
    completionBlock = nil;
}

@end