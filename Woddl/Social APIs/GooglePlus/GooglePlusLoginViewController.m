//
//  GooglePlusLoginViewController.m
//  Woddl
//
//  Created by Алексей Поляков on 30.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "GooglePlusLoginViewController.h"
#import <GoogleOpenSource/GoogleOpenSource.h>
#import "WDDAppDelegate.h"



@interface GooglePlusLoginViewController ()

@end

@implementation GooglePlusLoginViewController
{
    NSString *OAuthToken;
    NSNumber *expireDate;
    NSString *idToken;
    NSString *refreshToken;
    NSString *tokenType;
    NSString *serviceProvider;
    NSString *userID;
    NSString *userEmail;
    NSString *userImage;
    NSString *userName;
    GPPSignIn *signIn;
    GPPSignInButton *signInButton;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(urlWasHandled) name:@"HandleURL" object:nil];
    
    signInButton = [[GPPSignInButton alloc] initWithFrame:CGRectZero];
    signInButton.center = self.view.center;
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:signInButton];

    [self loginToGooglePlus];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"HandleURL" object:nil];
}

- (void)loginToGooglePlus
{
    [self clearCookie];
    
    signIn = [GPPSignIn sharedInstance];
    //[signIn signOut];
    [signIn disconnect];
    
    signIn.delegate = self;
    signIn.shouldFetchGooglePlusUser = YES;
    signIn.shouldFetchGoogleUserID = YES;
    signIn.shouldFetchGoogleUserEmail = YES;
    signIn.clientID = kGooglePlusClientID;
    signIn.scopes = [NSArray arrayWithObjects: kGTLAuthScopePlusLogin, kGTLAuthScopePlusMe, nil];
    
    [signIn authenticate];
}

- (void)urlWasHandled
{
    WDDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate showHUDWithTitle:@""];
}

- (void)clearCookie
{
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *arrayOfCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    
    for(NSHTTPCookie* cookie in arrayOfCookies)
    {
        [cookies deleteCookie:cookie];
    }
}

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error
{
    
    if (!error)
    {
        OAuthToken = [[auth parameters] objectForKey:@"access_token"];
        idToken = [[auth parameters] objectForKey:@"id_token"];
        refreshToken = [[auth parameters] objectForKey:@"refresh_token"];
        tokenType = [[auth parameters] objectForKey:@"token_type"];
        serviceProvider = [[auth parameters] objectForKey:@"serviceProvider"];
        expireDate = [[auth parameters] objectForKey:@"expires_in"];
        userID = [signIn userID];
        userName = [[signIn googlePlusUser] displayName];
        userImage = [[[signIn googlePlusUser] image] url];
        
        [_delegate loginSuccessWithToken:OAuthToken timeExpire:[NSString stringWithFormat:@"%@", expireDate] userID:userID userName:userName imageURL:userImage];
    }
    
    WDDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate dismissHUD];
    
    [self.navigationController popViewControllerAnimated:YES];
    //[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didDisconnectWithError:(NSError *)error
{
    //[self dismissViewControllerAnimated:YES completion:nil];
}

@end
