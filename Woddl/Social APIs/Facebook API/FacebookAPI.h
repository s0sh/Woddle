//
//  FacebookAPI.h
//  Woddl
//
//  Created by Александр Бородулин on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FacebookPictures.h"

@protocol FacebookAPIDelegate;
@interface FacebookAPI : NSObject
{
    NSString* OAuthToken;
    NSDate* expiresIn;
    id<FacebookAPIDelegate> delegate;
}

+(FacebookAPI*)instance;
-(void)loginWithDelegate:(id<FacebookAPIDelegate>)delegate_;
-(BOOL)loginWithToken:(NSString *)token expire:(NSDate *)expire delegate:(id<FacebookAPIDelegate>)delegate_;
@end

@protocol FacebookAPIDelegate

-(void)loginFacebookViewController:(UIViewController*) fbViewController;
-(void)loginWithSuccessWithToken:(NSString *)accessToken
                       andExpire:(NSDate *) expire
                       andUserID:(NSString *)userID
                   andScreenName:(NSString *)name
                     andImageURL:(NSString *)imageURL
                   andProfileURL:(NSString *)profileURLString
                       andGroups:(NSArray *)groups;
-(void)loginWithFail;
-(void)loginFailFromDeviceFacebookAccount;

@end
