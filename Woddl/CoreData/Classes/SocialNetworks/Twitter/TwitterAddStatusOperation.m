//
//  TwitterAddStatusOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 30.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "TwitterAddStatusOperation.h"
#import "TwitterRequest.h"
#import "WDDLocation.h"

@implementation TwitterAddStatusOperation

-(id)initTwitterAddStatusOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andImage:(NSData*)image andLocation:(WDDLocation*)location withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        self.token = token_;
        self.message = message_;
        delegate = delegate_;
        self.image = image;
        self.location = location;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    TwitterRequest* request = [[TwitterRequest alloc] init];
    NSDictionary* result = [request addStatusWithMessage:self.message
                                                andImage:self.image
                                                location:self.location
                                                andToken:self.token];
    if(result)
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterAddStatusDidFinishWithSuccess:) withObject:result waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(twitterAddStatusDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

@end
