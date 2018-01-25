//
//  WDDPoweredByViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDPoweredByViewController.h"
#import "WDDDataBase.h"
#import "SocialNetwork.h"
#import "PrivateMessagesModel.h"
#import "WDDSAddSocialNetworkViewController.h"
#import "WDDWebViewController.h"

#import "WDDCookiesManager.h"

#import <Parse.h>
#import <FlurrySDK/Flurry.h>
#import <uidevice-extension/UIDevice-Hardware.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

#import "WDDAppDelegate.h"

#define bgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)

@interface WDDPoweredByViewController () <SocialNetworkUpdatedDelegate>

@property (nonatomic, strong) NSURL *sponsorURL;
@property (nonatomic, strong) NSString *sponsorLinkTitle;

@end

@implementation WDDPoweredByViewController

#pragma mark - lifecycle methods

- (void)viewDidLoad
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    self.sponsorURL = [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] objectForKey:kSponsorURLKey]];
    self.sponsorLinkTitle = [[NSUserDefaults standardUserDefaults] objectForKey:kSponsorLinkTitleKey];
    
    if (!self.sponsorURL)
    {
        [[NSUserDefaults standardUserDefaults] setObject:DefaultSposorsSiteURL forKey:kSponsorURLKey];
        [[NSUserDefaults standardUserDefaults] setObject:DefaultSposorsLinkTitle forKey:kSponsorLinkTitleKey];
        self.sponsorURL = [NSURL URLWithString:DefaultSposorsSiteURL];
        self.sponsorLinkTitle = DefaultSposorsLinkTitle;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    NSString *path = [cacheDirectory stringByAppendingPathComponent:@"poweredBy.jpg"];
    
    UIImage *poweredByImage = [UIImage imageWithContentsOfFile:path];
    if (poweredByImage)
    {
        self.backgroundImage.image = poweredByImage;
        self.backgroundImage.contentMode = UIViewContentModeScaleAspectFit;
    }
    else
    {
        self.backgroundImage.image = [UIImage imageNamed:ASSET_BY_SCREEN_HEIGHT(@"PoweredByScreen_background")];
        self.backgroundImage.contentMode = UIViewContentModeBottom;
    }
    
    CTTelephonyNetworkInfo *networkInfo = [CTTelephonyNetworkInfo new];
    CTCarrier *carrier = networkInfo.subscriberCellularProvider;
    NSString *countyCode = carrier.isoCountryCode;

    if (!countyCode)
    {
        countyCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    }
    countyCode = [countyCode uppercaseString];
    
    NSString *poweredByType = nil;
    if ([UIDevice has4InchDisplay])
    {
        poweredByType = @"poweredByRetina4";
    }
    else if ([UIDevice hasRetinaDisplay])
    {
        poweredByType = @"poweredByRetina";
    }
    else
    {
        poweredByType = @"poweredBy";
    }
    
    PFQuery *countryQuery = [PFQuery queryWithClassName:@"AD"];
    [countryQuery whereKey:@"countryCode" equalTo:countyCode];
    PFQuery *defaultQuery = [PFQuery queryWithClassName:@"AD"];
    [defaultQuery whereKey:@"countryCode" equalTo:@"default"];
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[countryQuery, defaultQuery]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        __block PFFile *defaultPoweredBy = nil;
        __block PFFile *countyPoweredBy = nil;
        __block NSString *defaultSposonrsURL = nil;
        __block NSString *countySposonrsURL = nil;
        __block NSString *countySponsorsLinkTitle = nil;
        __block NSString *defaultSponsorsLinkTitle = nil;
        
        [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            PFObject *object = (PFObject *)obj;
            if ([object[@"countryCode"] isEqual:countyCode])
            {
                countyPoweredBy = object[poweredByType];
                countySposonrsURL = object[@"url"];
                countySponsorsLinkTitle = object[@"linkTitle"];
            }
            else
            {
                defaultPoweredBy = object[poweredByType];
                defaultSposonrsURL = object[@"url"];
                defaultSponsorsLinkTitle = object[@"linkTitle"];
            }
        }];
        
        
        NSData *imageData = nil;
        NSString *sponsorURL = nil;
        NSString *linkTitle = nil;
        
        if (countyPoweredBy)
        {
            imageData = countyPoweredBy.getData;
            sponsorURL = countySposonrsURL;
            linkTitle = countySponsorsLinkTitle;
        }
        else
        {
            imageData = defaultPoweredBy.getData;
            sponsorURL = defaultSposonrsURL;
            linkTitle = defaultSponsorsLinkTitle;
        }
        
        if (imageData)
        {
            [imageData writeToFile:path atomically:YES];
            if (sponsorURL)
            {
                [[NSUserDefaults standardUserDefaults] setObject:sponsorURL
                                                          forKey:kSponsorURLKey];
            }
            else
            {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSponsorURLKey];
            }
            
            if (linkTitle)
            {
                [[NSUserDefaults standardUserDefaults] setObject:linkTitle
                                                          forKey:kSponsorLinkTitleKey];
            }
            else
            {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSponsorLinkTitleKey];
            }
        }
    }];
    
}

const NSTimeInterval kPresentPoweredByDelay = 2.0f;

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([PFUser currentUser])
    {
        [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"user"];
        [[PFInstallation currentInstallation] saveEventually];
        
        [[WDDCookiesManager sharedManager] removeAllCookies];
        [WDDDataBase initializeWithCallBack:^(BOOL success) {
            
            [self updateContent];
            
            PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([SocialNetwork class])];
            [query whereKey:@"userOwner" equalTo:[PFUser currentUser]];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
             {
                 dispatch_async(bgQueue, ^{
                     [objects enumerateObjectsUsingBlock:^(PFObject *parseSocialNetwork, NSUInteger idx, BOOL *stop)
                      {
                          [[WDDDataBase sharedDatabase] updateSocialNetworkFromParse:parseSocialNetwork
                                                                        withDelegate:nil];
                      }];
                 
                     [Flurry setUserID:[PFUser currentUser].objectId];
                     [PrivateMessagesModel sharedModel];

                     [SocialNetworkManager sharedManager].applicationReady = YES;
                 });
             }];
            
            NSTimeInterval timeToShow = kPresentPoweredByDelay - [[NSDate date] timeIntervalSinceDate:((WDDAppDelegate *)[UIApplication sharedApplication].delegate).appStartTime];
            if (timeToShow < 0)
            {
                timeToShow = 0;
            }
            
            [self performSelector:@selector(goToMainScreen) withObject:nil afterDelay:timeToShow];
        }];
    }
    else
    {
        NSTimeInterval timeToShow = kPresentPoweredByDelay - [[NSDate date] timeIntervalSinceDate:((WDDAppDelegate *)[UIApplication sharedApplication].delegate).appStartTime];
        if (timeToShow < 0)
        {
            timeToShow = 0;
        }
        
        [self performSelector:@selector(goToLoginScreen) withObject:nil afterDelay:timeToShow];
    }
}

- (void)updateContent
{
    [[SocialNetworkManager sharedManager] updatePosts];
}

#pragma mark - Storyboard

- (void)goToLoginScreen
{
    [self performSegueWithIdentifier:kStoryboardSegueIDLoginScreen sender:nil];
}

- (void)goToMainScreen
{
    WDDAppDelegate* delegate = [[UIApplication sharedApplication] delegate];
    delegate.networkActivityIndicatorCounter++;
    [self performSegueWithIdentifier:kStoryboardSegueIDMainSlidingScreen sender:nil];
    delegate.networkActivityIndicatorCounter--;
}

#pragma makr - User actions

- (IBAction)showSponsorsLink:(id)sender
{
    static WDDWebViewController *webViewController = nil;
    static UINavigationController *navigationController = nil;
    
    if (self.sponsorURL.absoluteString.length)
    {
        webViewController = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDWebViewViewController];
        webViewController.url = self.sponsorURL;
        webViewController.requireAuthorization = NO;
        webViewController.customTitle = (self.sponsorLinkTitle ?: @"");
        webViewController.sourceNetwork = nil;
        
        navigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];

        [[[UIApplication sharedApplication].delegate window] addSubview:navigationController.view];
    }
}

- (IBAction)backToLoginViewController:(UIStoryboardSegue *)segue
{
    WDDAppDelegate * appDelegate = (WDDAppDelegate *)[[UIApplication sharedApplication] delegate];
    [SocialNetworkManager sharedManager].applicationReady = NO;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [appDelegate performSelector:@selector(dismissHUD) withObject:nil afterDelay:3.0f];
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

@end