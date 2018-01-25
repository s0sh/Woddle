//
//  WDDWebViewController.m
//  Woddl
//
//  Created by Алексей Поляков on 05.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDWebViewController.h"
#import "WDDCookiesManager.h"

#import "SocialNetwork.h"

#import "FacebookAPI.h"
#import "GoogleAPI.h"
#import "InstagramAPI.h"
#import "FoursquareAPI.h"
#import "LinkedinAPI.h"

#import "WDDChatContactTitle.h"

#import <uidevice-extension/UIDevice-Hardware.h>
#import "SAMHUDView.h"

static const NSInteger tag_LoadingError = 1024;
static const NSInteger tag_AuthentificationProposal = 2048;

@interface WDDWebViewController () <UIAlertViewDelegate, FacebookAPIDelegate, GoogleAPIDelegate, InstagramAPIDelegate, FoursquareAPIDelegate>

@property (nonatomic, assign) BOOL isLoggingInToTwitter;
@property (nonatomic, assign) BOOL isLoggingInToLinkedIn;

@property (nonatomic, assign) BOOL prepared;
@property (nonatomic, assign) BOOL isAuthorized;

@property (nonatomic, strong) NSMutableArray *alertViews;

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation WDDWebViewController

#pragma mark - life cycle

- (void)dealloc
{
    [self.alertViews enumerateObjectsUsingBlock:^(UIAlertView *alert, NSUInteger idx, BOOL *stop)
    {
        alert.delegate = nil;
    }];
}

- (void)awakeFromNib
{
    self.customTitle = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.alertViews = [NSMutableArray new];
    
    self.webView.userInteractionEnabled = YES;
    self.webView.scalesPageToFit = YES;
    self.webView.delegate = self;
    self.isLoggingInToTwitter = NO;
    self.isLoggingInToLinkedIn = NO;
    
    CGFloat buttonSize = CGRectGetHeight(self.navigationController.navigationBar.frame);
    UIButton *openInSafari = [UIButton buttonWithType:UIButtonTypeCustom];
    openInSafari.frame = (CGRect){CGPointZero, CGSizeMake(buttonSize, buttonSize)};
    [openInSafari setImage:[UIImage imageNamed:@"SafariIcon"] forState:UIControlStateNormal];
    [openInSafari addTarget:self action:@selector(openInSafari) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:openInSafari];

    
    
    [self setupNavigationBarTitle];
    
    [self customizeBackButton];
    
    UIBarButtonItem *backButton = self.navigationItem.leftBarButtonItem;
    
    UIButton *homeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [homeButton setFrame:(CGRect){CGPointZero, CGSizeMake(54.f, 44.f)}];
    [homeButton setImage:[UIImage imageNamed:@"home-icon"] forState:UIControlStateNormal];
    [homeButton addTarget:self action:@selector(dismissSelf) forControlEvents:UIControlEventTouchUpInside];
    [homeButton setImageEdgeInsets:UIEdgeInsetsMake(10, 11, 12, 11)];
    UIBarButtonItem *homeButtonItem = [[UIBarButtonItem alloc] initWithCustomView:homeButton];
    
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.navigationItem.leftBarButtonItems = @[ backButton, homeButtonItem ];
    
    self.prepared = NO;
}

- (void)dismissSelf
{
    [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
                                                
- (void)openInSafari
{
    [[UIApplication sharedApplication] openURL:_webView.request.URL];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (![APP_DELEGATE isInternetConnected])
    {
        [[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"lskConnectInternet", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"lskOK", @"") otherButtonTitles:nil] show];
        
        UIButton *backButton = (UIButton *)self.navigationItem.leftBarButtonItem.customView;
        [backButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        
        return ;
    }
    
    if (!self.prepared)
    {
        if (!self.sourceNetwork || ![[WDDCookiesManager sharedManager] activateCookieForSocialNetwork:self.sourceNetwork])
        {
            self.isAuthorized = NO;
            if (self.requireAuthorization && self.sourceNetwork)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[self socialNetwork:self.sourceNetwork.type.integerValue]
                                                                message:[NSString stringWithFormat:NSLocalizedString(@"lskLoginToAccountMessage", @""), self.sourceNetwork.profile.name]
                                                               delegate:self
                                                      cancelButtonTitle:NSLocalizedString(@"lskCancel", @"")
                                                      otherButtonTitles:NSLocalizedString(@"lskLogin", @""), nil];
                alert.tag = tag_AuthentificationProposal;
                [alert show];
                [self.alertViews addObject:alert];
            }
            else
            {
                self.titleLabel.text = (self.customTitle ?: NSLocalizedString(@"lskLoggedOut", @"Logged Out"));
            }
        }
        else
        {
            self.isAuthorized = YES;
            
            if (!self.customTitle)
            {
                
            }
            else
            {
                self.navigationItem.title = self.customTitle;
            }
        }
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url];
        [_webView loadRequest:request];
        self.prepared = YES;
    }
    else
    {
        if (!self.titleLabel.text.length)
        {
            self.titleLabel.text = NSLocalizedString(@"lskLoggedOut", @"Logged Out");
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Web view navigation

- (BOOL)goBackIfNeed
{
    BOOL canGoBack = [_webView canGoBack];
    if (canGoBack)
    {
        [_webView goBack];
    }
    
    return canGoBack;
}

#pragma mark - Process going out from viewController

- (void)popBackViewController
{
    if (![self goBackIfNeed])
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)dismissViewController
{
    if ([self goBackIfNeed])
    {
        return;
    }
    
    // update cookies if user logged in
    if (self.sourceNetwork && self.isAuthorized)
    {
        [self registerCookie];
    }
    
    if (self.navigationController.presentingViewController)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [UIView animateWithDuration:0.15 animations:^{
            
            self.parentViewController.view.alpha = 0.f;
        } completion:^(BOOL finished) {
            
            [self.parentViewController.view removeFromSuperview];
        }];
    }
}

#pragma mark - WebView delegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    DLog(@"webViewDidStartLoad");
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    DLog(@"webViewDidFinishLoad");
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    DLog(@"Will load URL: %@", request.URL);
    
    if ((self.isLoggingInToTwitter && [request.URL.absoluteString isEqualToString:@"https://mobile.twitter.com/"]) ||
        (self.isLoggingInToLinkedIn && [request.URL.absoluteString isEqualToString:@"https://touch.www.linkedin.com/"]))
    {
        
        if (self.isLoggingInToLinkedIn)
        {
            TF_CHECKPOINT(@"Logged in to LinkedIn account");
        }
        else
        {
            TF_CHECKPOINT(@"Logged in to Twitter account");
        }
        
        [self registerCookie];
        [[WDDCookiesManager sharedManager] activateCookieForSocialNetwork:self.sourceNetwork];
        self.titleLabel.text = self.sourceNetwork.profile.name;
        
        BOOL result = NO;
        SAMHUDView *logginInHud = nil;;
        if (self.isLoggingInToTwitter)
        {
            result = YES;
            logginInHud = [[SAMHUDView alloc] initWithTitle:NSLocalizedString(@"lskLoggingIn", @"")];
            self.webView.hidden = YES;
        }
        [logginInHud show];
        
        self.isLoggingInToLinkedIn = NO;
        self.isLoggingInToTwitter = NO;
        
        double delayInSeconds = 1.2f / [UIDevice currentDevice].cpuCount;
        __weak WDDWebViewController *wSelf = self;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){

            [wSelf.webView stopLoading];

            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:wSelf.url];
            [wSelf.webView loadRequest:request];
            
            [logginInHud completeAndDismissWithTitle:NSLocalizedString(@"lskLoggedIn", @"")];
            self.webView.hidden = NO;
        });
        
        DLog(@"Loading canceled");
        return result;
    }
    
    return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
//    BOOL shouldDisplayError =   (([error.domain isEqualToString:@"WebKitErrorDomain"] && (error.code == 100 || error.code == 102)) && !self.isLoggingInToTwitter) ||
//                                ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code >= 200 && error.code <= 202) ||
//    ([error.domain isEqualToString:NSURLErrorDomain] && ((error.code >= NSURLErrorBadServerResponse && error.code <= NSURLErrorBadURL) || error.code <= NSURLErrorZeroByteResource));
    
//    if ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code >= 100 && error.code <= 102)
//    {
//        // DOTO : Process this
//    }
//    if ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code >= 200 && error.code <= 202 )
//    {
//        
//    }
//    if ([error.domain isEqualToString:NSURLErrorDomain] && ((error.code >= NSURLErrorBadServerResponse && error.code <= NSURLErrorBadURL) || error.code <= NSURLErrorZeroByteResource))
//    {
//        
//    }
    
    DLog(@"Can't open URL: %@ because of: %@", _url, error.localizedDescription);
    
//    if (shouldDisplayError)
//    {
//        UIAlertView *cantOpenURLAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"lskError", @"")
//                                                                   message:NSLocalizedString(@"lskCantOpenURL", @"Can't open URL in web view")
//                                                                  delegate:self
//                                                         cancelButtonTitle:NSLocalizedString(@"lskClose", @"")
//                                                         otherButtonTitles:nil];
//        cantOpenURLAlert.tag = tag_LoadingError;
//        [cantOpenURLAlert show];
//        [self.alertViews addObject:cantOpenURLAlert];
//    }
}

#pragma mark - Rotation support

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if ([self.navigationItem.titleView isKindOfClass:[WDDChatContactTitle class]])
    {
        [(WDDChatContactTitle *)self.navigationItem.titleView didRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }
}

#pragma mark - UIAlertViewDelegate protocol implementation

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    alertView.delegate = nil;
    [self.alertViews removeObject:alertView];
    
    if (alertView.tag == tag_AuthentificationProposal)
    {
        if (buttonIndex != alertView.cancelButtonIndex)
        {
            DLog(@"Displaying login controller");
            [self showLoginController];
        }
        else
        {
            self.titleLabel.text = NSLocalizedString(@"lskLoggedOut", @"Logged Out");
        }
    }
    else
    {
        if ([self.navigationController.viewControllers indexOfObject:self])
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - Login to SN methods

- (void)showLoginController
{
    switch (self.sourceNetwork.type.integerValue)
    {
        case kSocialNetworkFacebook :
            
            TF_CHECKPOINT(@"Login to FB requested");
            [[FacebookAPI instance] loginWithDelegate:self];
        break;
            
        case kSocialNetworkTwitter : {
            
            TF_CHECKPOINT(@"Login to Twitter requested");
            self.isLoggingInToTwitter = YES;
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://mobile.twitter.com/session/new?bypass_interstitial=true"]];
            [self.webView loadRequest:request];
        break; }
            
        case kSocialNetworkLinkedIN : {
            
            TF_CHECKPOINT(@"Login to LinkedIn requested");
            self.isLoggingInToLinkedIn = YES;
            NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://touch.www.linkedin.com/login.html"]];
            [self.webView loadRequest:request];
        break; }
            
        case kSocialNetworkGooglePlus :
            
            TF_CHECKPOINT(@"Login to G+ requested");
            [[GoogleAPI Instance] loginWithDelegate:self];
        break;
            
        case kSocialNetworkInstagram :
            
            TF_CHECKPOINT(@"Login to Instagram requested");
            [[InstagramAPI Instance] loginWithDelegate:self];
        break;
            
        case kSocialNetworkFoursquare :
            
            TF_CHECKPOINT(@"Login to Foursquare requested");
            [[FoursquareAPI Instance] loginWithDelegate:self];
        break;
    }
}

- (void)registerCookie
{
    [[WDDCookiesManager sharedManager] registerCookieForSocialNetwork:self.sourceNetwork];
    self.prepared = NO;
}

#pragma mark - Google Delegate

-(void)loginGoogleViewController:(UIViewController *)googleViewController
{
    [self presentViewController:googleViewController animated:YES completion:nil];
}

-(void)loginGoogleWithFail
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)loginGoogleWithSuccessWithToken:(NSString *)accessToken andExpire:(NSDate *)expire andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andProfileURL:(NSString *)profileURLString
{
    TF_CHECKPOINT(@"Logged in to G+ account");
    [self registerCookie];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Facebook Delegate

-(void)loginFacebookViewController:(UIViewController*) fbViewController
{
    [self presentViewController:fbViewController animated:YES completion:nil];
}

-(void)loginWithSuccessWithToken:(NSString*)accessToken andExpire:(NSDate*) expire andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andProfileURL:(NSString *)profileURLString andGroups:(NSArray *)groups
{
    TF_CHECKPOINT(@"Logged in to Facebook account");
    [self registerCookie];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)loginWithFail
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Instagram Delegate

-(void)loginInstagramSuccessWithToken:(NSString *)token andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andProfileURL:(NSString *)profileURLString
{
    TF_CHECKPOINT(@"Logged in to Instagram account");
    [self registerCookie];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)loginInstagramViewController:(UIViewController *)controller
{
    [self presentViewController:controller animated:YES completion:nil];
}

-(void)loginInstagramFailed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Foursquare Delegate

-(void)loginFoursquareViewController:(UIViewController *)controller
{
    [self presentViewController:controller animated:YES completion:nil];
}

-(void)loginFoursquareFailed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)loginFoursquareSuccessWithToken:(NSString *)token andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andProfileURL:(NSString *)profileURLString
{
    TF_CHECKPOINT(@"Logged in to Foursquare account");
    [self registerCookie];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Setters/getters implementation

- (void)setUrl:(NSURL *)url
{
    if ([url.absoluteString rangeOfString:@"http"].location != 0)
    {
        _url = [NSURL URLWithString:[@"http://" stringByAppendingString:url.absoluteString]];
    }
    else
    {
        _url = url;
    }
    
//    if (url.isFileURL && [url.absoluteString rangeOfString:@"file:"].location == NSNotFound)
//    {
//        _url = [NSURL URLWithString:[@"http://" stringByAppendingString:url.absoluteString]];
//    }
//    else
//    {
//        _url = url;
//    }
}

#pragma mark - Utility methods

- (NSString *)socialNetwork:(SocialNetworkType)section
{
    NSString *result;
    
    switch (section)
    {
        case kSocialNetworkFacebook:
            result = NSLocalizedString(@"Facebook", @"");
            break;
            
        case kSocialNetworkTwitter:
            result = NSLocalizedString(@"Twitter", @"");
            break;
            
        case kSocialNetworkGooglePlus:
            result = NSLocalizedString(@"Google Plus", @"");
            break;
            
        case kSocialNetworkFoursquare:
            result = NSLocalizedString(@"Foursquare", @"");
            break;
            
        case kSocialNetworkInstagram:
            result = NSLocalizedString(@"Instagram", @"");
            break;
            
        case kSocialNetworkLinkedIN:
            result = NSLocalizedString(@"LinkedIn", @"");
            break;
            
        case kSocialNetworkUnknown:
            result = NSLocalizedString(@"lskUnknown", @"");
            break;
    }
    
    return result;
}

@end
