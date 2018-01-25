//
//  TwitterAddStatusOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 30.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WDDLocation;
@protocol TwitterAddStatusOperationDelegate;
@interface TwitterAddStatusOperation : NSOperation
{
    id <TwitterAddStatusOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSData* image;
@property (nonatomic, strong) WDDLocation* location;

-(id)initTwitterAddStatusOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andImage:(NSData*)image andLocation:(WDDLocation*)location withDelegate:(id)delegate_;
@end

@protocol TwitterAddStatusOperationDelegate<NSObject>
-(void)twitterAddStatusDidFinishWithSuccess:(NSDictionary*)result;
-(void)twitterAddStatusDidFinishWithFail;
@end
