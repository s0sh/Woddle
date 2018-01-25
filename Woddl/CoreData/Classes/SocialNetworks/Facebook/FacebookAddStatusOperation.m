//
//  FacebookAddStatusOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 30.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookAddStatusOperation.h"
#import "FacebookRequest.h"
#import "WDDLocation.h"
#import <Parse/Parse.h>

@interface FacebookAddStatusOperation ()
{
    NSData* _dataForUpload;
}

@end

@implementation FacebookAddStatusOperation

-(id)initFacebookAddStatusOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andImage:(NSData*)image andLocation:(WDDLocation*)location withDelegate:(id)delegate_
{
    if (self = [super init])
    {
        self.token = token_;
        self.message = message_;
        delegate = delegate_;
        _dataForUpload = image;
        self.location = location;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
//    self.image = [self getURLFromImageData:_dataForUpload];
    FacebookRequest* request = [[FacebookRequest alloc] init];
//    if([request addStatusWithToken:self.token andMessage:self.message andLon:[NSNumber numberWithDouble:self.location.longitude].stringValue andLat:[NSNumber numberWithDouble:self.location.latidude].stringValue andImageURL:self.image])
    if([request addStatusWithToken:self.token
                        andMessage:self.message
                          location:self.location
                          andImage:[UIImage imageWithData:_dataForUpload]])
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookAddStatusDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(facebookAddStatusDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

-(NSString*)getURLFromImageData:(NSData*)imageData
{
    if (!imageData) return nil;
    @try
    {
        NSError *error;
        PFFile *file = [PFFile fileWithData:imageData];
        
        if (![file save:&error])
        {
            DLog(@"error %@", error);
        }
        
        return file.url;
    }
    @catch (NSException *exception)
    {
        DLog(@"exception %@", exception);
    }
    @finally
    {
        
    }
}

@end
