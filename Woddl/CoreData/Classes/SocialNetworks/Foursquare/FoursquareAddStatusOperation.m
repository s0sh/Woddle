//
//  FoursquareAddStatusOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 02.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FoursquareAddStatusOperation.h"
#import "FoursquareRequest.h"
#import "WDDLocation.h"

@implementation FoursquareAddStatusOperation

-(id)initFoursquareAddStatusOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andImage:(UIImage*)image andLocation:(WDDLocation*)location withDelegate:(id)delegate_
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
    FoursquareRequest* request = [[FoursquareRequest alloc] init];
    NSError* error = [request addStatusWithToken:self.token
                                      andMessage:self.message
                                        location:self.location
                                        andImage:self.image];
    if(!error)
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(foursquareAddStatusDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(foursquareAddStatusDidFinishWithFail:) withObject:error waitUntilDone:YES];
    }
}
@end
