//
//  GoogleAPI.h
//  Woddl
//
//  Created by Александр Бородулин on 03.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol GoogleAPIDelegate;
@interface GoogleAPI : NSObject
{
    NSString* OAuthToken;
    NSString* expiresIn;
    id<GoogleAPIDelegate> delegate;
}

+(GoogleAPI*)Instance;
-(void)loginWithDelegate:(id<GoogleAPIDelegate>)delegate_;
@end

@protocol GoogleAPIDelegate

-(void)loginGoogleViewController:(UIViewController*) googleViewController;
-(void)loginGoogleWithSuccessWithToken:(NSString*)accessToken
                             andExpire:(NSDate*) expire
                             andUserID:(NSString*)userID
                         andScreenName:(NSString*)name
                           andImageURL:(NSString*)imageURL
                         andProfileURL:(NSString *)profileURLString;
-(void)loginGoogleWithFail;

@end
