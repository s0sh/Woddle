//
//  WDDSAddSocialNetworkViewController.h
//  Woddl
//
//  Created by Sergii Gordiienko on 25.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum taLoginMode
{
    LoginModeAddNetwork = 0,
    LoginModeRestoreToken = 1
} LoginMode;

typedef void (^TokenUpdateCallback)(SocialNetworkType networkType, NSString *accessKey, NSDate *expirationTime);

@interface WDDSAddSocialNetworkViewController : UIViewController

@property (nonatomic, assign) LoginMode loginMode;
@property (nonatomic, retain) NSString *updatingAccountId;
@property (nonatomic, retain) NSString *updatingAccountName;
@property (nonatomic, copy) TokenUpdateCallback updatedCallback;

- (void)showLoginForNetworkWithType:(SocialNetworkType)networkType;

- (IBAction)facebookPressed:(id)sender;
- (IBAction)twitterPressed:(id)sender;
- (IBAction)instagramPressed:(id)sender;
- (IBAction)foursquarePressed:(id)sender;
- (IBAction)linkedinPressed:(id)sender;
- (IBAction)googlePressed:(id)sender;

@end
