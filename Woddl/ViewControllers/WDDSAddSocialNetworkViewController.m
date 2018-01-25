//
//  WDDSAddSocialNetworkViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 25.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDAppDelegate.h"
#import "WDDSAddSocialNetworkViewController.h"
#import "FacebookAPI.h"
#import "WDDDataBase.h"
#import "SocialNetwork.h"
#import "FacebookPublishing.h"
#import "TwitterAPI.h"
#import "InstagramAPI.h"
#import "FoursquareAPI.h"
#import "LinkedinAPI.h"
#import "FacebookSN.h"
#import "FaceBookProfile.h"
#import "SAMHUDView.h"
#import "GoogleAPI.h"
#import "SocialNetworkManager.h"

#import "TwitterRequest.h"
#import "FacebookRequest.h"

#define bgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)

@interface WDDSAddSocialNetworkViewController () <FacebookAPIDelegate, TwitterAPIDelegate, InstagramAPIDelegate, FoursquareAPIDelegate, LinkedinAPIDelegate, GoogleAPIDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;

@end

@implementation WDDSAddSocialNetworkViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self customizeBackButton];
    [self setupNavigationBarTitle];
}

- (void)showLoginForNetworkWithType:(SocialNetworkType)networkType
{
    switch (networkType)
    {
        case kSocialNetworkFacebook:
            [self facebookPressed:nil];
        break;
            
        case kSocialNetworkGooglePlus:
            [self googlePressed:nil];
            break;
            
        case kSocialNetworkTwitter:
            [self twitterPressed:nil];
        break;
            
        case kSocialNetworkInstagram:
            [self instagramPressed:nil];
        break;
            
        case kSocialNetworkFoursquare:
            [self foursquarePressed:nil];
        break;
            
        case kSocialNetworkLinkedIN:
            [self linkedinPressed:nil];
        break;
            
        default:
        break;
    }
}

#pragma mark - Actions

-(IBAction)facebookPressed:(id)sender
{
    if ([self isInternetConnected])
    {
        [[FacebookAPI instance] loginWithDelegate:self];
    }
}

-(IBAction)twitterPressed:(id)sender
{
    if ([self isInternetConnected])
    {
        [[TwitterAPI Instance] showLoginWindowWithTarget:self];
    }
}

-(IBAction)instagramPressed:(id)sender
{
    if ([self isInternetConnected])
    {
        [[InstagramAPI Instance] loginWithDelegate:self];
    }
}

-(IBAction)foursquarePressed:(id)sender
{
    if ([self isInternetConnected])
    {
        [[FoursquareAPI Instance] loginWithDelegate:self];
    }
}

-(IBAction)linkedinPressed:(id)sender
{
    if ([self isInternetConnected])
    {
        [[LinkedinAPI Instance] loginWithDelegate:self];
    }
}

-(IBAction)googlePressed:(id)sender
{
    if ([self isInternetConnected])
    {
        [[GoogleAPI Instance] loginWithDelegate:self];
    }
}

-(IBAction)postMessagePressed:(id)sender
{
}

- (BOOL)isInternetConnected
{
    if ([(WDDAppDelegate *)[[UIApplication sharedApplication] delegate] isInternetConnected])
    {
        return YES;
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"lskConnectInternet", @"Connect to the internet")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"lskOK", @"OK")
                          otherButtonTitles:nil] show];
    }
    
    return NO;
}

#pragma mark - Appearance methods

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

#pragma mark - Google Delegate

-(void)loginGoogleViewController:(UIViewController *)googleViewController
{
    if (self.loginMode == LoginModeRestoreToken)
    {
        googleViewController.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"lskLoginTo", @"Title for SN login controller on update token"), self.updatingAccountName];
    }
    
    [self presentViewController:googleViewController animated:YES completion:nil];
}

-(void)loginGoogleWithFail
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)loginGoogleWithSuccessWithToken:(NSString *)accessToken andExpire:(NSDate *)expire andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andProfileURL:(NSString *)profileURLString
{
    if (self.loginMode == LoginModeRestoreToken)
    {
        if (![userID isEqual:self.updatingAccountId])
        {
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"lskWrongAccountMessage", "Wrong account alert message"), self.updatingAccountName];
            
            UIAlertView *wrongAccountAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"lskWrongAccountTitle", "Wrong account alert title")
                                                                        message:message
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"lskCancel", @"Cancel button")
                                                              otherButtonTitles:NSLocalizedString(@"lskLogin", @"Login"), nil];
            wrongAccountAlert.tag = kSocialNetworkGooglePlus;
            [wrongAccountAlert show];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:^{
                
                self.updatedCallback(kSocialNetworkGooglePlus, accessToken, expire);
            }];
        }
    }
    else
    {
        [[WDDDataBase sharedDatabase] addNewSocialNetworkWithType:kSocialNetworkGooglePlus
                                                        andUserID:userID
                                                         andToken:accessToken
                                                   andDisplayName:name
                                                      andImageURL:imageURL
                                                        andExpire:expire
                                                     andFollowers:nil
                                                    andProfileURL:profileURLString
                                                        andGroups:nil];
        
        [self dismissViewControllerAnimated:YES completion:^{
            
                [[SocialNetworkManager sharedManager] updatePosts];
        }];
        
        TF_CHECKPOINT(@"New G+ account added");
    }
}

#pragma mark - Facebook Delegate

-(void)loginFacebookViewController:(UIViewController*) fbViewController
{
    if (self.loginMode == LoginModeRestoreToken)
    {
        fbViewController.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"lskLoginTo", @"Title for SN login controller on update token"), self.updatingAccountName];
    }
    [self presentViewController:fbViewController animated:YES completion:nil];
}

-(void)loginWithSuccessWithToken:(NSString*)accessToken andExpire:(NSDate*) expire andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andProfileURL:(NSString *)profileURLString andGroups:(NSArray *)groups
{
    if (self.loginMode == LoginModeRestoreToken)
    {
        if (![userID isEqual:self.updatingAccountId])
        {
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"lskWrongAccountMessage", "Wrong account alert message"), self.updatingAccountName];
            
            UIAlertView *wrongAccountAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"lskWrongAccountTitle", "Wrong account alert title")
                                                                        message:message
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"lskCancel", @"Cancel button")
                                                              otherButtonTitles:NSLocalizedString(@"lskLogin", @"Login"), nil];
            wrongAccountAlert.tag = kSocialNetworkFacebook;
            [wrongAccountAlert show];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:^{
                self.updatedCallback(kSocialNetworkFacebook, accessToken, expire);
            }];
        }
    }
    else
    {
        [[WDDDataBase sharedDatabase] addNewSocialNetworkWithType:kSocialNetworkFacebook
                                                        andUserID:userID
                                                         andToken:accessToken
                                                   andDisplayName:name
                                                      andImageURL:imageURL
                                                        andExpire:expire
                                                     andFollowers:nil
                                                    andProfileURL:profileURLString
                                                        andGroups:groups];
        
        [self dismissViewControllerAnimated:YES completion:^{
            
            [[SocialNetworkManager sharedManager] updatePosts];
        }];
        
        TF_CHECKPOINT(@"New FB account added");
    }
}

-(void)loginWithFail
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Twitter Delegate

-(void)loginTwitterWithSuccessWithToken:(NSString *)token andName:(NSString *)name andUserID:(NSString *)userID andImageURL:(NSString *)imageURL andFollowers:(NSArray *)followers andProfileURL:(NSString *)profileURLString
{
    if (self.loginMode == LoginModeRestoreToken)
    {
        if (![userID isEqual:self.updatingAccountId])
        {
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"lskWrongAccountMessage", "Wrong account alert message"), self.updatingAccountName];
            
            UIAlertView *wrongAccountAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"lskWrongAccountTitle", "Wrong account alert title")
                                                                        message:message
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"lskCancel", @"Cancel button")
                                                              otherButtonTitles:NSLocalizedString(@"lskLogin", @"Login"), nil];
            wrongAccountAlert.tag = kSocialNetworkTwitter;
            [wrongAccountAlert show];
        }
        else
        {
            self.updatedCallback(kSocialNetworkTwitter, token, nil);
        }
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
                                                    andProfileURL:profileURLString
                                                        andGroups:nil];
        [[SocialNetworkManager sharedManager] updatePosts];
        
        TF_CHECKPOINT(@"New Twitter account added");
    }
}

#pragma mark - Instagram Delegate

-(void)loginInstagramSuccessWithToken:(NSString *)token andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andProfileURL:(NSString *)profileURLString
{
    SAMHUDView *hud = [[SAMHUDView alloc] init];
    [hud dismissAnimated:YES];
    
    if (self.loginMode == LoginModeRestoreToken)
    {
        if (![userID isEqual:self.updatingAccountId])
        {
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"lskWrongAccountMessage", "Wrong account alert message"), self.updatingAccountName];
            
            UIAlertView *wrongAccountAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"lskWrongAccountTitle", "Wrong account alert title")
                                                                        message:message
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"lskCancel", @"Cancel button")
                                                              otherButtonTitles:NSLocalizedString(@"lskLogin", @"Login"), nil];
            wrongAccountAlert.tag = kSocialNetworkInstagram;
            [wrongAccountAlert show];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:^{
                self.updatedCallback(kSocialNetworkInstagram, token, nil);
            }];
        }
    }
    else
    {
        [[WDDDataBase sharedDatabase] addNewSocialNetworkWithType:kSocialNetworkInstagram
                                                        andUserID:userID
                                                         andToken:token
                                                   andDisplayName:name
                                                      andImageURL:imageURL
                                                        andExpire:nil
                                                     andFollowers:nil
                                                    andProfileURL:profileURLString andGroups:nil];
        
        [self dismissViewControllerAnimated:YES completion:^{
            
            [[SocialNetworkManager sharedManager] updatePosts];
        }];
        
        TF_CHECKPOINT(@"New Instagramm account added");
    }
}

-(void)loginInstagramViewController:(UIViewController *)controller
{
    if (self.loginMode == LoginModeRestoreToken)
    {
        controller.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"lskLoginTo", @"Title for SN login controller on update token"), self.updatingAccountName];
    }
    
    [self presentViewController:controller animated:YES completion:nil];
}

-(void)loginInstagramFailed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Foursquare Delegate

-(void)loginFoursquareViewController:(UIViewController *)controller
{
    if (self.loginMode == LoginModeRestoreToken)
    {
        controller.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"lskLoginTo", @"Title for SN login controller on update token"), self.updatingAccountName];
    }
    [self presentViewController:controller animated:YES completion:nil];
}

-(void)loginFoursquareFailed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)loginFoursquareSuccessWithToken:(NSString *)token andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andProfileURL:(NSString *)profileURLString
{
    if (self.loginMode == LoginModeRestoreToken)
    {
        if (![userID isEqual:self.updatingAccountId])
        {
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"lskWrongAccountMessage", "Wrong account alert message"), self.updatingAccountName];
            
            UIAlertView *wrongAccountAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"lskWrongAccountTitle", "Wrong account alert title")
                                                                        message:message
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"lskCancel", @"Cancel button")
                                                              otherButtonTitles:NSLocalizedString(@"lskLogin", @"Login"), nil];
            wrongAccountAlert.tag = kSocialNetworkFoursquare;
            [wrongAccountAlert show];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:^{
                self.updatedCallback(kSocialNetworkFoursquare, token, nil);
            }];
        }
    }
    else
    {
        [[WDDDataBase sharedDatabase] addNewSocialNetworkWithType:kSocialNetworkFoursquare
                                                        andUserID:userID
                                                         andToken:token
                                                   andDisplayName:name
                                                      andImageURL:imageURL
                                                        andExpire:nil
                                                     andFollowers:nil
                                                    andProfileURL:profileURLString
                                                        andGroups:nil];
        
        [self dismissViewControllerAnimated:YES completion:^{
            
            [[SocialNetworkManager sharedManager] updatePosts];
        }];
        
        TF_CHECKPOINT(@"New Foursquare account added");
    }
}

#pragma mark - Linkedin Delegate

-(void)loginLinkedinViewController:(UIViewController *)controller
{
    if (self.loginMode == LoginModeRestoreToken)
    {
        controller.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"lskLoginTo", @"Title for SN login controller on update token"), self.updatingAccountName];
    }
    
    [self presentViewController:controller animated:YES completion:nil];
}

-(void)loginLinkedinFailed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)loginLinkedinSuccessWithToken:(NSString *)token andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andTimeExpire:(NSDate *)expires andProfileURL:(NSString *)profileURLString andGroups:(NSArray *)grpups
{
    if (self.loginMode == LoginModeRestoreToken)
    {
        if (![userID isEqual:self.updatingAccountId])
        {
            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"lskWrongAccountMessage", "Wrong account alert message"), self.updatingAccountName];
            
            UIAlertView *wrongAccountAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"lskWrongAccountTitle", "Wrong account alert title")
                                                                        message:message
                                                                       delegate:self
                                                              cancelButtonTitle:NSLocalizedString(@"lskCancel", @"Cancel button")
                                                              otherButtonTitles:NSLocalizedString(@"lskLogin", @"Login"), nil];
            wrongAccountAlert.tag = kSocialNetworkLinkedIN;
            [wrongAccountAlert show];
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:^{
                self.updatedCallback(kSocialNetworkLinkedIN, token, nil);
            }];
        }
    }
    else
    {
        [[WDDDataBase sharedDatabase] addNewSocialNetworkWithType:kSocialNetworkLinkedIN
                                                        andUserID:userID andToken:token
                                                   andDisplayName:name
                                                      andImageURL:imageURL
                                                        andExpire:expires
                                                     andFollowers:nil
                                                    andProfileURL:profileURLString
                                                        andGroups:grpups];
        
        [self dismissViewControllerAnimated:YES completion:^{
            
            [[SocialNetworkManager sharedManager] updatePosts];
        }];
        
        TF_CHECKPOINT(@"New LinkedIn account added");
    }
    
    
}

#pragma mark - UIAlertViewDelegate protocol implementation

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.cancelButtonIndex)
    {
        [self dismissViewControllerAnimated:YES completion:^{

            self.updatedCallback(alertView.tag, nil, nil);
        }];
    }
    else
    {
        [self showLoginForNetworkWithType:alertView.tag];
    }
}


@end
