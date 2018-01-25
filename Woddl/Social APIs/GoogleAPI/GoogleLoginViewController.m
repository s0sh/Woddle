//
//  GoogleLoginViewController.m
//  Woddl
//
//  Created by Александр Бородулин on 03.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "GoogleLoginViewController.h"

static NSString * const redirectUri = @"http://localhost";

@interface GoogleLoginViewController ()<UIWebViewDelegate>

@end

@implementation GoogleLoginViewController

@synthesize delegate;

static NSInteger const kRefreshError = 401;

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
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    CGFloat navBarWidth;
    
    if(IS_IOS7)
        navBarWidth = 64;
    else
        navBarWidth = 44;
    
    UINavigationBar* fbNavBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, navBarWidth)];
    fbNavBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:fbNavBar];
    
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
    
    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MainScreen_nav_bar_logo"]];
    navItem.titleView = logoView;
	
    //  Back button
	UIImage *backButtonImage = [UIImage imageNamed:kBackButtonArrowImageName];
    UIButton *customBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customBackButton.bounds = CGRectMake( 0, 0, backButtonImage.size.width, backButtonImage.size.height );
    [customBackButton setImage:backButtonImage forState:UIControlStateNormal];
    SEL backActionSelector = @selector(cancelPressed:);
    [customBackButton addTarget:self action:backActionSelector forControlEvents:UIControlEventTouchUpInside];
    navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:customBackButton];
    
	[fbNavBar pushNavigationItem:navItem animated:NO];
    
    googleWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0+navBarWidth, screenWidth,screenHeight-navBarWidth)];
    googleWebView.delegate = self;
    [self.view addSubview:googleWebView];
    
    googleWebActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    googleWebActivityIndicator.center = self.view.center;
    [self.view addSubview:googleWebActivityIndicator];
	// Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated
{
     NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
     NSArray *facebookCookies = [cookies cookiesForURL:[NSURL URLWithString:@"https://accounts.google.com"]];
     for(NSHTTPCookie* cookie in facebookCookies)
     {
     [cookies deleteCookie:cookie];
     }
    NSString *fbAuthorizeURL = [NSString stringWithFormat:@"https://accounts.google.com/o/oauth2/auth?client_id=%@&redirect_uri=%@&scope=https://www.googleapis.com/auth/plus.login&response_type=code&access_type=offline&request_visible_actions=http://schemas.google.com/CommentActivity", kGooglePlusClientID, redirectUri];
    NSURL *url = [NSURL URLWithString:fbAuthorizeURL];
    [googleWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    //http://localhost/oauth2callback?code=4/ux5gNj-_mIu4DOD_gNZdjX9EtOFf
    //http://localhost/oauth2callback#error=access_denied
    [googleWebActivityIndicator startAnimating];
    NSString *requestPath = [[request URL] absoluteString];
    if ([requestPath rangeOfString:redirectUri].location != NSNotFound)
    {
        if([requestPath rangeOfString:@"code="].location != NSNotFound)
        {
            NSString* code = [self stringBetweenString:@"code=" andString:@"&" innerString:requestPath];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://accounts.google.com/o/oauth2/token"]]];
            [request setHTTPMethod:@"POST"];
            [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPBody:[[NSString stringWithFormat:@"code=%@&client_id=%@&client_secret=%@&redirect_uri=%@&grant_type=authorization_code",code,kGooglePlusClientID, kGooglePlusClientSecret, redirectUri] dataUsingEncoding:NSUTF8StringEncoding]];
            NSError *error = nil; NSURLResponse *response = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            if(data)
            {
                NSError* error = nil;
                NSDictionary* json = [NSJSONSerialization
                                      JSONObjectWithData:data
                                      options:kNilOptions
                                      error:&error];
                if(!error)
                {
                    if ([json objectForKey:@"access_token"])
                    {
                        //refresh_token
                        NSString* refresh_token = [json objectForKey:@"refresh_token"];
                        NSString* token = [json objectForKey:@"access_token"];
                        NSDictionary* userInfo = [self getInformationAboutMeWithToken:token];
                        if(userInfo)
                        {
                            NSDictionary* image = [userInfo objectForKey:@"image"];
                            NSString* imageURL = nil;
                            if(image)
                            {
                                imageURL = [image objectForKey:@"url"];
                            }
                            //[delegate loginSuccessWithToken:refresh_token andRefreshToken:refresh_token andTimeExpire:nil andUserID:[userInfo objectForKey:@"id"] andScreenName:[userInfo objectForKey:@"displayName"] andImageURL:imageURL];
                            NSString* accessToken = [NSString stringWithFormat:@"token=%@refresh_token=%@",token,refresh_token];
                            NSString *profileURL = userInfo[@"url"];
                            
                            [delegate loginSuccessWithToken:accessToken
                                              andTimeExpire:nil
                                                  andUserID:[userInfo objectForKey:@"id"]
                                              andScreenName:[userInfo objectForKey:@"displayName"]
                                                andImageURL:imageURL
                                              andProfileURL:profileURL];
                        }
                        else
                        {
                            [delegate loginCencel];
                        }
                    }
                    else
                    {
                        [delegate loginCencel];
                    }
                }
                else
                {
                    [delegate loginCencel];
                }
            }
            else
            {
                [delegate loginCencel];
            }
        }
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [googleWebActivityIndicator stopAnimating];
}

-(NSDictionary*)getInformationAboutMeWithToken:(NSString*)token
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://www.googleapis.com/plus/v1/people/me?access_token=%@",token]]];
    
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if ([json objectForKey:@"id"])
            {
                return json;
            }
        }
    }
    return nil;
}


-(NSString*)stringBetweenString:(NSString*)start andString:(NSString*)end innerString:(NSString*)str
{
    NSScanner* scanner = [NSScanner scannerWithString:str];
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanUpToString:start intoString:NULL];
    if([scanner scanString:start intoString:NULL])
    {
        NSString* result = nil;
        if([scanner scanUpToString:end intoString:&result])
        {
            return result;
        }
    }
    return nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

-(void)cancelPressed:(id)sender
{
    [delegate loginCencel];
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

@end
