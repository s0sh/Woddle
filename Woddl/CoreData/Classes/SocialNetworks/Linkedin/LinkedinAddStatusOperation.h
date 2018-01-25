//
//  LinkedinAddStatusOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 02.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WDDLocation;
@protocol LinkedinAddStatusOperationDelegate;
@interface LinkedinAddStatusOperation : NSOperation
{
    id <LinkedinAddStatusOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* image;
@property (nonatomic, strong) WDDLocation* location;

-(id)initLinkedinAddStatusOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andImage:(NSData*)image andLocation:(WDDLocation*)location withDelegate:(id)delegate_;
@end

@protocol LinkedinAddStatusOperationDelegate<NSObject>
-(void)linkedinAddStatusDidFinishWithSuccess;
-(void)linkedinAddStatusDidFinishWithFail;
@end
