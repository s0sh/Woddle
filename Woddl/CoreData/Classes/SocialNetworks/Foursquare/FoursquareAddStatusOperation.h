//
//  FoursquareAddStatusOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 02.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WDDLocation;
@protocol FoursquareAddStatusOperationDelegate;
@interface FoursquareAddStatusOperation : NSOperation
{
    id <FoursquareAddStatusOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) UIImage* image;
@property (nonatomic, strong) WDDLocation* location;

-(id)initFoursquareAddStatusOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andImage:(UIImage*)image andLocation:(WDDLocation*)location withDelegate:(id)delegate_;
@end

@protocol FoursquareAddStatusOperationDelegate<NSObject>
-(void)foursquareAddStatusDidFinishWithSuccess;
-(void)foursquareAddStatusDidFinishWithFail:(NSError*)error;
@end
