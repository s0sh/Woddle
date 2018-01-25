//
//  FacebookShareOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 18.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FacebookShareOperationDelegate;
@interface FacebookShareOperation : NSOperation
{
    id <FacebookShareOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* link;

-(id)initFacebookShareOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andLink:(NSString*)link_ withDelegate:(id)delegate_;
@end

@protocol FacebookShareOperationDelegate<NSObject>
-(void)facebookShareDidFinishWithSuccess;
-(void)facebookShareDidFinishWithFail;
@end
