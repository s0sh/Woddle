//
//  GooglePlusGetActivitiesOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 26.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "GooglePlusGetActivitiesOperation.h"
#import "GoogleRequest.h"

@interface GooglePlusGetActivitiesOperation ()

@property (nonatomic, assign) NSInteger count;

@end

@implementation GooglePlusGetActivitiesOperation

@synthesize completionBlock;
@synthesize token;

-(id)initGooglePlusRequestGetActivitiesOperationWithToken:(NSString*)token_
                                              andPersonID:(NSString*)personID
                                                    count:(NSInteger)count
                                      withComplationBlock:(complationGetActivitiesBlock)complationBlock_
{
    if (self = [super init])
    {
        token = token_;
        completionBlock = complationBlock_;
        self.personID = personID;
        self.count = count;
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
    GoogleRequest* request = [[GoogleRequest alloc] init];
    request.accessToken = token;
    NSArray* result = [request getStatusesFromPersonID:self.personID count:self.count pageId:nil needPageId:NO];
    if (self.isCancelled)
    {
        return ;
    }
    completionBlock(result);
    completionBlock = nil;
}


@end
