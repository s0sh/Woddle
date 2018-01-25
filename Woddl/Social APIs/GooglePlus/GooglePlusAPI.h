//
//  GooglePlusAPI.h
//  Woddl
//
//  Created by Алексей Поляков on 30.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

@protocol GooglePlusAPIDelegate;
@protocol GooglePlusActivityDelegate;

#import <Foundation/Foundation.h>
#import <GooglePlus/GooglePlus.h>
#import <GoogleOpenSource/GoogleOpenSource.h>
#import "GooglePlusLoginViewController.h"
#import "SocialNetwork.h"

@interface GooglePlusAPI : NSObject <GPPSignInDelegate>
{
    NSString* OAuthToken;
    NSString* expiresIn;
    id <GooglePlusAPIDelegate> delegate;
    id <GooglePlusActivityDelegate> _activityDelegate;
}

+ (GooglePlusAPI *)Instance;
- (void)loginWithDelegate:(id<GooglePlusAPIDelegate>)delegate_;
- (id)login;
- (void)getPostsForUser:(NSString *)userID socialNetwork:(SocialNetwork *)network andDelegate:(id <GooglePlusActivityDelegate>)activityDelegate;

@end

@protocol GooglePlusAPIDelegate

-(void)loginGooglePlusViewController:(UIViewController*) gpViewController;
-(void)loginGooglePlusWithSuccessWithToken:(NSString*)accessToken expire:(NSDate*)expire userID:(NSString*)userID userName:(NSString *)userName imageURL:(NSString *)imageURL;
-(void)loginGooglePlusWithFail;

@end

@protocol GooglePlusActivityDelegate

- (void)getAllactivities:(NSMutableArray *)activities socialNetwork:(SocialNetwork *)network;

@end
