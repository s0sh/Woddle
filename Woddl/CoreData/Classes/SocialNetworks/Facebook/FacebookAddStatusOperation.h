//
//  FacebookAddStatusOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 30.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WDDLocation;
@protocol FacebookAddStatusOperationDelegate;
@interface FacebookAddStatusOperation : NSOperation
{
    id <FacebookAddStatusOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* image;
@property (nonatomic, strong) WDDLocation* location;

-(id)initFacebookAddStatusOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andImage:(NSData*)image andLocation:(WDDLocation*)location withDelegate:(id)delegate_;
@end

@protocol FacebookAddStatusOperationDelegate<NSObject>
-(void)facebookAddStatusDidFinishWithSuccess;
-(void)facebookAddStatusDidFinishWithFail;
@end
