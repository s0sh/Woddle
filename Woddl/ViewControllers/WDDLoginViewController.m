//
//  WDDLoginViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDLoginViewController.h"
#import "FacebookAPI.h"
#import "TwitterAPI.h"
#import "WDDDataBase.h"
#import "PrivateMessagesModel.h"
#import "SocialNetwork.h"
#import "FacebookSN.h"
#import "TwitterSN.h"
#import "FaceBookProfile.h"
#import <Parse.h>
#import "SAMHUDView.h"
#import <FlurrySDK/Flurry.h>
#import "WDDAppDelegate.h"
#import "SocialNetworkManager.h"
#import "WDDSAddSocialNetworkViewController.h"
#import <Social/Social.h>

#import "WDDCookiesManager.h"

typedef NS_ENUM(NSUInteger, LoginActionSheetType)
{
    LoginActionSheetTypeFacebook,
    LoginActionSheetTypeTwitter,
};

typedef NS_ENUM(NSUInteger, LoginFacebookActionSheetButton)
{
    LoginFacebookActionSheetButtonAccount,
    LoginFacebookActionSheetButtonOther,
    LoginFacebookActionSheetButtonCancel
};

@interface WDDLoginViewController () <FacebookAPIDelegate, TwitterAPIDelegate, SocialNetworkUpdatedDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *statusViewHeightConstraint;
@property (strong, nonatomic) SAMHUDView *progressHUD;

//  Model
@property (strong, nonatomic) NSArray *twitterSystemAccounts;
@property (strong, nonatomic) ACAccountStore *facebookAccountStore;

@end

@implementation WDDLoginViewController

#pragma mark - view controller lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];    
    self.backgroundImage.image = [UIImage imageNamed:ASSET_BY_SCREEN_HEIGHT(@"loginBackground")];
    if (!IS_IOS7)
    {
        self.statusViewHeightConstraint.constant = 0.0f;
    }
}

#pragma mark - user actions

- (IBAction)loginWithFaceBookAction
{
    if ([WDDDataBase isConnectedToDB])
    {
        [[WDDDataBase sharedDatabase] disconnectDatabase];
    }
    if ([(WDDAppDelegate *)[[UIApplication sharedApplication] delegate] isInternetConnected])
    {
        [self useFBAccountOnDeviceOrLoginWithCustom];
    }
    else
    {
        [self showConnectionAlert];
    }
}

- (void)useFBAccountOnDeviceOrLoginWithCustom
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
    NSArray *generalPermissions = @[@"email"];
    NSMutableDictionary *options = [@{ ACFacebookAppIdKey : kFacebookAccessKey,
                                       ACFacebookPermissionsKey : generalPermissions,
                                       ACFacebookAudienceKey : ACFacebookAudienceEveryone  } mutableCopy];
    
    void(^step3WritePermissionsObtained)(BOOL, NSError *) = ^(BOOL granted, NSError *error) {
        
        DLog(@"Step 3, Write permissions obtained: granted - %d, Error: %@, error code: %ld", granted, [error localizedDescription], (long)[error code]);
        if(granted && error == nil)
        {
            NSArray *fbAccounts = [accountStore accountsWithAccountType:accountType];
            
            if (fbAccounts.count)
            {
                ACAccount *account = [fbAccounts firstObject];
                self.facebookAccountStore = accountStore;
                
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"lskSelectAccount", @"")
                                                                         delegate:self
                                                                cancelButtonTitle:nil
                                                           destructiveButtonTitle:nil
                                                                otherButtonTitles:nil];
                
                [actionSheet addButtonWithTitle:account.username];
                [actionSheet addButtonWithTitle:NSLocalizedString(@"lskOther", @"")];
                [actionSheet addButtonWithTitle:NSLocalizedString(@"lskCancel", @"")];
                
                actionSheet.destructiveButtonIndex = LoginFacebookActionSheetButtonOther;
                actionSheet.cancelButtonIndex = LoginFacebookActionSheetButtonCancel;
                actionSheet.tag = LoginActionSheetTypeFacebook;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [actionSheet showInView:self.view];
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [[FacebookAPI instance] loginWithDelegate:self];
                });
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[FacebookAPI instance] loginWithDelegate:self];
            });
        }
    };
    
    void(^step2ReadPermissionsObtained)(BOOL, NSError *) = ^(BOOL granted, NSError *error) {
        
        DLog(@"Step 2, Read permissions obtained: granted - %d, Error: %@, error code: %ld", granted, [error localizedDescription], (long)[error code]);
        if (granted && error == nil)
        {
            NSArray *writePermissions = @[@"publish_actions", @"manage_pages", @"publish_stream"];
            options[ACFacebookPermissionsKey] = writePermissions;
            
            [accountStore requestAccessToAccountsWithType:accountType
                                                  options:options
                                               completion:step3WritePermissionsObtained];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[FacebookAPI instance] loginWithDelegate:self];
            });
        }
    };
    
    void(^step1GeneralPermissionsObtained)(BOOL, NSError *) =  ^(BOOL granted, NSError *error) {
        
        DLog(@"Step 1, General permissions obtained: granted - %d, Error: %@, error code: %ld", granted, [error localizedDescription], (long)[error code]);
        if (granted && error == nil)
        {
            NSArray *readPermissions = @[@"user_photos", @"read_stream", @"read_mailbox", @"xmpp_login", @"user_subscriptions", @"user_work_history", @"user_groups", @"user_events", @"user_about_me", @"user_relationships"];
            options[ACFacebookPermissionsKey] = readPermissions;
            
            [accountStore requestAccessToAccountsWithType:accountType
                                                  options:options
                                               completion:step2ReadPermissionsObtained];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [[FacebookAPI instance] loginWithDelegate:self];
            });
        }
     };
    
    [accountStore requestAccessToAccountsWithType:accountType
                                          options:options
                                       completion:step1GeneralPermissionsObtained];
}

- (IBAction)loginWithTwitterAction:(id)sender
{
    if ([WDDDataBase isConnectedToDB])
    {
        [[WDDDataBase sharedDatabase] disconnectDatabase];
    }
    if ([(WDDAppDelegate *)[[UIApplication sharedApplication] delegate] isInternetConnected])
    {
        [self showSystemTwitterAccountsOrLoginWithCustom];
    }
    else
    {
        [self showConnectionAlert];
    }
}

- (void)showSystemTwitterAccountsOrLoginWithCustom
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [accountStore requestAccessToAccountsWithType:accountType
                                          options:nil
                                       completion:^(BOOL granted, NSError *error) {
                                           
                                           if (granted)
                                           {
                                               NSArray *twitterAccounts = [accountStore accountsWithAccountType:accountType];
                                               self.twitterSystemAccounts = twitterAccounts;
                                               
                                               if (twitterAccounts.count)
                                               {
                                                   NSArray *accountNames = [twitterAccounts valueForKeyPath:@"@unionOfObjects.accountDescription"];
                                                   
                                                   UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"lskSelectAccount", @"")
                                                                                                            delegate:self
                                                                                                   cancelButtonTitle:nil
                                                                                              destructiveButtonTitle:nil
                                                                                                   otherButtonTitles:nil];
                                                   for (NSString *title in accountNames)
                                                   {
                                                       [actionSheet addButtonWithTitle:title];
                                                   }
                                                   [actionSheet addButtonWithTitle:NSLocalizedString(@"lskOther", @"")];
                                                   [actionSheet addButtonWithTitle:NSLocalizedString(@"lskCancel", @"")];

                                                   actionSheet.destructiveButtonIndex = [accountNames count];
                                                   actionSheet.cancelButtonIndex = [accountNames count]+1;
                                                   actionSheet.tag = LoginActionSheetTypeTwitter;
                                                   
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                      
                                                       [actionSheet showInView:self.view];
                                                   });
                                               }
                                               else
                                               {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       
                                                       [[TwitterAPI Instance] showLoginWindowWithTarget:self];
                                                   });
                                               }
                                           }
                                           else
                                           {
                                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                                               message:NSLocalizedString(@"lskNoAccessToSystemAccounts", @"")
                                                                                              delegate:nil
                                                                                     cancelButtonTitle:NSLocalizedString(@"lskOK", @"")
                                                                                     otherButtonTitles:nil];
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   
                                                   //[alert show];
                                                   [[TwitterAPI Instance] showLoginWindowWithTarget:self];
                                               });
                                           }
                                       }];
}

- (void)showConnectionAlert
{
    [[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"lskConnectInternet", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"lskOK", @"") otherButtonTitles:nil] show];
}

#pragma mark - HUD methods

- (void)showLoginHUD
{
    self.progressHUD = [[SAMHUDView alloc] initWithTitle:NSLocalizedString(@"lskLoggingIn", @"")];
    [self.progressHUD show];
}

- (void)removeLoginHUD
{
    if (self.progressHUD)
    {
        [self.progressHUD completeAndDismissWithTitle:NSLocalizedString(@"lskLoggedIn", @"")];
        self.progressHUD = nil;
    }
}

- (void)removeOnFailLoginHUD
{
    if (self.progressHUD)
    {
        [self.progressHUD failAndDismissWithTitle:NSLocalizedString(@"lskFail", @"")];
        self.progressHUD = nil;
    }
}


#pragma mark - Storyboard

- (void)goToMainSlideScreen
{
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [SocialNetworkManager sharedManager].applicationReady = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[WDDCookiesManager sharedManager] removeAllCookies];
        [self removeLoginHUD];
//        [self performSegueWithIdentifier:kStoryboardSegueIDMainSlidingScreenAfterLogin sender:nil];
#warning Add check for first start here
        [self performSegueWithIdentifier:kStoryboardSegueIDGuideScreenAfterLogin sender:nil];
        [PrivateMessagesModel sharedModel];
    });
}


#pragma mark - Facebook Delegate

-(void)loginFacebookViewController:(UIViewController *)fbViewController
{
    [self presentViewController:fbViewController animated:YES completion:nil];
}

-(void)loginWithSuccessWithToken:(NSString *)accessToken
                       andExpire:(NSDate *)expire
                       andUserID:(NSString *)userID
                   andScreenName:(NSString *)name
                     andImageURL:(NSString *)imageURL
                   andProfileURL:(NSString *)profileURLString
                       andGroups:(NSArray *)groups
{
    if (!self.progressHUD)
    {
        [self showLoginHUD];
    }
    
    void(^perfomLogin)(void) = ^{
        //  Parse login
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        
        FBAccessTokenData *fbTokenData = [FBAccessTokenData createTokenFromString:accessToken
                                                                      permissions:@[@"email", @"read_stream"]
                                                                   expirationDate:expire
                                                                        loginType:FBSessionLoginTypeWebView
                                                                      refreshDate:[NSDate date]];
        
        [FBSession.activeSession closeAndClearTokenInformation];
        
        /*        if (!*/[[[FBSession alloc] init] openFromAccessTokenData:fbTokenData
                                                         completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                                             
                                                             if (status == FBSessionStateOpen) {
                                                                 [FBSession setActiveSession:session];
                                                                 
                                                                 [PFFacebookUtils initializeFacebook];
                                                                 [PFFacebookUtils logInWithFacebookId:userID
                                                                                          accessToken:accessToken
                                                                                       expirationDate:expire
                                                                                                block:^(PFUser *user, NSError *error) {
                                                                                                    if (!error)
                                                                                                    {
                                                                                                        [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"user"];
                                                                                                        [[PFInstallation currentInstallation] saveEventually];
                                                                                                        
                                                                                                        [WDDDataBase initializeWithCallBack:^(BOOL success) {
                                                                                                            
                                                                                                            PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([SocialNetwork class])];
                                                                                                            [query whereKey:@"userOwner" equalTo:user];
                                                                                                            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
                                                                                                             {
                                                                                                                 dispatch_queue_t loggingIn = dispatch_queue_create("", NULL);
                                                                                                                 dispatch_async(loggingIn, ^{
                                                                                                                     if (objects.count)
                                                                                                                     {
                                                                                                                         [objects enumerateObjectsUsingBlock:^(PFObject *parseSocialNetwork, NSUInteger idx, BOOL *stop)
                                                                                                                          {
                                                                                                                              [[WDDDataBase sharedDatabase] updateSocialNetworkFromParse:parseSocialNetwork
                                                                                                                                                                            withDelegate:nil];
                                                                                                                              
                                                                                                                              if(idx+1==objects.count)
                                                                                                                              {
                                                                                                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                                      self.progressHUD.textLabel.text = NSLocalizedString(@"lskLoadingPosts", @"Loading posts message");
                                                                                                                                  });
                                                                                                                                  [[WDDDataBase sharedDatabase] save];
                                                                                                                                  [[SocialNetworkManager sharedManager] updateFacebookAndTwitterSocialNetworkWithComplationBlock:^{
                                                                                                                                      [Flurry setUserID:user.objectId];
                                                                                                                                      [FBSession setActiveSession:nil];
                                                                                                                                      [[WDDDataBase sharedDatabase] save];
                                                                                                                                      [self goToMainSlideScreen];
                                                                                                                                      [[SocialNetworkManager sharedManager] updatePostsWithComplationBlock:^{
                                                                                                                                          
                                                                                                                                          [SocialNetworkManager sharedManager].applicationReady = YES;
                                                                                                                                      }];
                                                                                                                                  }];
                                                                                                                              }
                                                                                                                          }];
                                                                                                                     }
                                                                                                                     else
                                                                                                                     {
                                                                                                                         [[WDDDataBase sharedDatabase] addNewSocialNetworkWithType:kSocialNetworkFacebook
                                                                                                                                                                         andUserID:userID
                                                                                                                                                                          andToken:accessToken
                                                                                                                                                                    andDisplayName:name
                                                                                                                                                                       andImageURL:imageURL
                                                                                                                                                                         andExpire:expire andFollowers:nil andProfileURL:profileURLString andGroups:groups];
                                                                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                                             self.progressHUD.textLabel.text = NSLocalizedString(@"lskLoadingPosts", @"Loading posts message");
                                                                                                                         });
                                                                                                                         [[WDDDataBase sharedDatabase] save];
                                                                                                                         [[SocialNetworkManager sharedManager] updatePostsWithComplationBlock:^{
                                                                                                                             [Flurry setUserID:user.objectId];
                                                                                                                             [FBSession setActiveSession:nil];
                                                                                                                             
                                                                                                                             [SocialNetworkManager sharedManager].applicationReady = YES;
                                                                                                                             [self goToMainSlideScreen];
                                                                                                                         }];
                                                                                                                     }
                                                                                                                 });
                                                                                                             }];
                                                                                                        }];
                                                                                                    }
                                                                                                    else
                                                                                                    {
                                                                                                        [self removeLoginHUD];
                                                                                                        
                                                                                                        UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"lskError", @"")
                                                                                                                                                             message:NSLocalizedString(@"lskLoginErrorAlert", @"")
                                                                                                                                                            delegate:self
                                                                                                                                                   cancelButtonTitle:NSLocalizedString(@"lskClose", @"")
                                                                                                                                                   otherButtonTitles:nil];
                                                                                                        [errorAlert show];
                                                                                                    }
                                                                                                }];
                                                             }
                                                             //                                               else
                                                             //                                               {
                                                             //                                                   [self removeLoginHUD];
                                                             //                                                   [self didFailLoginWithTwitter];
                                                             //                                               }
                                                         }];/*)*/
        //        {
        //            [self removeLoginHUD];
        //            [self didFailLoginWithTwitter];
        //        }
    };
    
    
    if (self.presentedViewController)
    {
        [self dismissViewControllerAnimated:YES completion:perfomLogin];
    }
    else
    {
        perfomLogin();
    }
}

-(void)loginWithFail
{
    if (self.presentedViewController)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        if (self.progressHUD)
        {
            [self removeOnFailLoginHUD];
        }
    }
}

-(void)loginFailFromDeviceFacebookAccount
{
    DLog(@"Login fail from device facebook account");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.progressHUD)
        {
            [self removeOnFailLoginHUD];
        }
        
        [[FacebookAPI instance] loginWithDelegate:self];
    });
}

#pragma mark - Twitter Delegate

- (void)didFailLoginWithTwitter
{
    if (self.progressHUD)
    {
        [self removeOnFailLoginHUD];
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:NSLocalizedString(@"lskLoginFailed", @"")
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"lskOK", @"")
                                          otherButtonTitles:nil];
    [alert show];
    
}

-(void)loginTwitterWithSuccessWithToken:(NSString *)token
                                andName:(NSString *)name
                              andUserID:(NSString *)userID
                            andImageURL:(NSString *)imageURL
                           andFollowers:(NSArray *)followers
                          andProfileURL:(NSString *)profileURLString
{
    if  (!self.progressHUD)
    {
        [self showLoginHUD];
    }
    
    NSString *authToken = [self getTwitterAccessTokenFromString:token];
    NSString *authTokenSecret = [self getTwitterSecretFromString:token];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [PFTwitterUtils initializeWithConsumerKey:kTwitterConsumerKey consumerSecret:kTwitterConsumerSecret];
    [PFTwitterUtils logInWithTwitterId:userID
                            screenName:name
                             authToken:authToken
                       authTokenSecret:authTokenSecret
                                 block:^(PFUser *user, NSError *error)
     {
         if (!error)
         {
             [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"user"];
             [[PFInstallation currentInstallation] saveEventually];
             
             [WDDDataBase initializeWithCallBack:^(BOOL success) {
                 PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([SocialNetwork class])];
                 [query whereKey:@"userOwner" equalTo:user];
                 [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
                  {
                      TF_CHECKPOINT(@"Logged in manual");
                      
                      if (objects.count)
                      {
                          [objects enumerateObjectsUsingBlock:^(PFObject *parseSocialNetwork, NSUInteger idx, BOOL *stop)
                           {
                               [[WDDDataBase sharedDatabase] updateSocialNetworkFromParse:parseSocialNetwork
                                                                             withDelegate:nil];
                               if(idx+1==objects.count)
                               {
                                   self.progressHUD.textLabel.text = NSLocalizedString(@"lskLoadingPosts", @"Loading posts message");
                                   [[SocialNetworkManager sharedManager] updateFacebookAndTwitterSocialNetworkWithComplationBlock:^{
                                       [self removeLoginHUD];
                                       [self goToMainSlideScreen];
                                       [[SocialNetworkManager sharedManager] updatePosts];
                                       [SocialNetworkManager sharedManager].applicationReady = YES;
                                   }];
                               }
                           }];
                          
                          TF_CHECKPOINT(@"Social networks added. Update started");
                      }
                      else
                      {
                          [[WDDDataBase sharedDatabase] addNewSocialNetworkWithType:kSocialNetworkTwitter
                                                                          andUserID:userID
                                                                           andToken:token
                                                                     andDisplayName:name
                                                                        andImageURL:imageURL
                                                                          andExpire:nil
                                                                       andFollowers:followers
                                                                      andProfileURL:profileURLString andGroups:nil];
                          [[SocialNetworkManager sharedManager] updatePostsWithComplationBlock:^{
                              [self removeLoginHUD];
                              
                              [SocialNetworkManager sharedManager].applicationReady = YES;
                              [self goToMainSlideScreen];
                          }];
                          
                          TF_CHECKPOINT(@"New account created. Update started");
                      }
                  }];
             }];
         }
         else
         {
             DLog(@"Twitter parse login error: %@", [error localizedDescription]);
             [self didFailLoginWithTwitter];
         }
     }];
}

- (NSString *)getTwitterAccessTokenFromString:(NSString *)fullTokenString
{
    NSString *accessToken;
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"oauth_token=[^&]*"
                                                                            options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *matches= [self getMatchesInString:fullTokenString withRegExprassion:regex];
    accessToken = [matches firstObject];
    accessToken = [accessToken stringByReplacingOccurrencesOfString:@"oauth_token=" withString:@""];
    return accessToken;
}

- (NSString *)getTwitterSecretFromString:(NSString *)fullTokenString
{
    NSString *accessTokenSecret;
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:@"oauth_token_secret=[^&]*"
                                                                            options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *matches= [self getMatchesInString:fullTokenString withRegExprassion:regex];
    accessTokenSecret = [matches firstObject];
    accessTokenSecret = [accessTokenSecret stringByReplacingOccurrencesOfString:@"oauth_token_secret=" withString:@""];
    return accessTokenSecret;
}

- (NSArray *)getMatchesInString:(NSString *)string withRegExprassion:(NSRegularExpression *)regEx
{
    NSArray *matches = [regEx matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    NSMutableArray *matchedStrings = [[NSMutableArray alloc] initWithCapacity:matches.count];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        NSString * matchedString = [string substringWithRange:matchRange];
        [matchedStrings addObject:matchedString];
    }
    return [matchedStrings copy];
}

#pragma mark - Rotation support

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

#pragma mark - SocialNetworkUpdatedDelegate protocol implementation

- (void)needUpdateAccessTokenForNetworkWithType:(SocialNetworkType)networkType
                                         userId:(NSString *)userId
                                    displayName:(NSString *)displayName
                                complitionBlock:(void(^)(SocialNetworkType socialNetwork, NSString *accessToken, NSDate *expirationDate))complitionBlock
{
    WDDSAddSocialNetworkViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDAddNetworkScreen];
    controller.loginMode = LoginModeRestoreToken;
    controller.updatingAccountId = userId;
    controller.updatingAccountName = displayName;
    controller.updatedCallback = ^(SocialNetworkType networkType, NSString *accessKey, NSDate *expirationTime)
    {
        complitionBlock(networkType, accessKey, expirationTime);
    };
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navigationController
                       animated:YES
                     completion:^{
                         
                         [controller showLoginForNetworkWithType:networkType];
                     }];
}

#pragma mark - UIActionSheetDelegate
#pragma mark

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag)
    {
            
        case LoginActionSheetTypeFacebook:
            [self actionForFacebookWithButtonIndex:buttonIndex];
            break;
        case LoginActionSheetTypeTwitter:
            [self actionForTwitterWithButtonIndex:buttonIndex];
            break;
    }
    
    self.twitterSystemAccounts = nil;
    self.facebookAccountStore = nil;
}

-(void)actionForTwitterWithButtonIndex:(NSInteger)buttonIndex
{
    if (  buttonIndex >= 0 && buttonIndex < self.twitterSystemAccounts.count )
    {
        ACAccount *selectedAccount = self.twitterSystemAccounts[buttonIndex];
        [self showLoginHUD];
        [[TwitterAPI Instance] proceedLoginWithAccount:selectedAccount target:self];
    }
    else if (buttonIndex == self.twitterSystemAccounts.count)
    {
        [[TwitterAPI Instance] showLoginWindowWithTarget:self];
    }
}

-(void)actionForFacebookWithButtonIndex:(NSInteger)buttonIndex
{
    if (  buttonIndex == LoginFacebookActionSheetButtonAccount)
    {
        DLog(@"Will login with system FB account");
        
        ACAccountType *accountType = [self.facebookAccountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
        NSArray *facebookAccounts = [self.facebookAccountStore accountsWithAccountType:accountType];
        
        DLog(@"Found %ld facebook accounts", facebookAccounts.count);
        
        ACAccount *account = [facebookAccounts firstObject];
        ACAccountCredential *credential = account.credential;
        // 60 days before expire = (24*60*60*60) in seconds
        NSDate *expireDate = [NSDate dateWithTimeIntervalSinceNow:(24*60*60*60)];
        
        
        BOOL login = [[FacebookAPI instance] loginWithToken:credential.oauthToken
                                                     expire:expireDate
                                                   delegate:self];
        if (login)
        {
             [self showLoginHUD];
        }
        else
        {
            [self removeOnFailLoginHUD];
        }
    }
    else if (buttonIndex == LoginFacebookActionSheetButtonOther)
    {
        [[FacebookAPI instance] loginWithDelegate:self];
    }
}
@end