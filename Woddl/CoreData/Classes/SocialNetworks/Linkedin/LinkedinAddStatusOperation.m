//
//  LinkedinAddStatusOperation.m
//  Woddl
//
//  Created by Александр Бородулин on 02.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinAddStatusOperation.h"
#import "LinkedinRequest.h"
#import <Parse/Parse.h>

@interface LinkedinAddStatusOperation ()
{
    NSData* _dataForUpload;
}

@end

@implementation LinkedinAddStatusOperation

-(id)initLinkedinAddStatusOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andImage:(NSData*)image andLocation:(WDDLocation*)location withDelegate:(id)delegate_
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
    self.image = [self getURLFromImageData:_dataForUpload];
    LinkedinRequest* request = [[LinkedinRequest alloc] init];
    if([request addStatusWithToken:self.token andMessage:self.message andImageURL:self.image])
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinAddStatusDidFinishWithSuccess) withObject:nil waitUntilDone:YES];
    }
    else
    {
        [(NSObject *)delegate performSelectorOnMainThread:@selector(linkedinAddStatusDidFinishWithFail) withObject:nil waitUntilDone:YES];
    }
}

-(NSString*)getURLFromImageData:(NSData*)imageData
{
    if (!imageData) return nil;
    @try
    {
        NSError *error;
        PFFile *file = [PFFile fileWithName:@"photo" data:imageData contentType:@"image/jpeg"]; //fileWithData:imageData];
        
        if (![file save:&error])
        {
            DLog(@"error %@", error);
        }
        
        return file.url;
    }
    @catch (NSException *exception)
    {
        
    }
    @finally
    {
        
    }
}

@end
