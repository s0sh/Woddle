//
//  InstagramViewController.m
//  Woddl
//
//  Created by Александр Бородулин on 01.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "InstagramViewController.h"
#import "InstagramRequest.h"

#define bgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)

@interface InstagramViewController ()<UIWebViewDelegate>

@end

@implementation InstagramViewController
@synthesize delegate;

static NSString* redirectUri = @"http://www.woodleapp.com";

#pragma mark - Initialization

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
    
    CGRect screenRect = self.view.frame;
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    CGFloat navBarWidth;
    
    if(IS_IOS7)
        navBarWidth = 64;
    else
        navBarWidth = 44;
    
    UINavigationBar* instagramNavBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, navBarWidth)];
    instagramNavBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:instagramNavBar];
    
    UINavigationItem *navItem = [[UINavigationItem alloc] init];
    
    UIImageView *logoView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MainScreen_nav_bar_logo"]];
    navItem.titleView = logoView;
    
    UIImage *backButtonImage = [UIImage imageNamed:kBackButtonArrowImageName];
    UIButton *customBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customBackButton.bounds = CGRectMake( 0, 0, backButtonImage.size.width, backButtonImage.size.height );
    [customBackButton setImage:backButtonImage forState:UIControlStateNormal];
    SEL backActionSelector = @selector(cancelPressed:);
    [customBackButton addTarget:self action:backActionSelector forControlEvents:UIControlEventTouchUpInside];
    navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:customBackButton];
    
	[instagramNavBar pushNavigationItem:navItem animated:NO];
    
    instagramWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0+navBarWidth, screenWidth,screenHeight-navBarWidth)];
    instagramWebView.delegate = self;
    [self.view addSubview:instagramWebView];
    
    instagramWebActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    instagramWebActivityIndicator.center = self.view.center;
    [self.view addSubview:instagramWebActivityIndicator];
    
	// Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated
{
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *facebookCookiesApi = [cookies cookiesForURL:[NSURL URLWithString:@"https://api.instagram.com"]];
    for(NSHTTPCookie* cookie in facebookCookiesApi)
    {
        [cookies deleteCookie:cookie];
    }
    NSArray *facebookCookies = [cookies cookiesForURL:[NSURL URLWithString:@"https://instagram.com"]];
    for(NSHTTPCookie* cookie in facebookCookies)
    {
        [cookies deleteCookie:cookie];
    }
    NSString *fbAuthorizeURL = [NSString stringWithFormat:@"https://api.instagram.com/oauth/authorize/?client_id=%@&redirect_uri=%@&response_type=code&scope=likes+basic+comments",kInstagrammClientID,redirectUri];
    NSURL *url = [NSURL URLWithString:fbAuthorizeURL];
    [instagramWebView loadRequest:[NSURLRequest requestWithURL:url]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Web View Delegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [instagramWebActivityIndicator startAnimating];
    NSString *requestPath = [[request URL] absoluteString];
    if ([requestPath rangeOfString:redirectUri].location != NSNotFound)
    {
        if ([requestPath rangeOfString:@"code="].location != NSNotFound)
        {
            dispatch_async(bgQueue,^{
                NSString* code = [self stringBetweenString:@"code=" andString:@"" innerString:requestPath];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://api.instagram.com/oauth/access_token"]];
            
                [request setHTTPMethod:@"POST"];
                [request setHTTPBody:[[NSString stringWithFormat:@"client_id=%@&client_secret=%@&grant_type=authorization_code&redirect_uri=%@&code=%@",kInstagrammClientID,kInstagrammClientSecret,redirectUri,code] dataUsingEncoding:NSUTF8StringEncoding]];
            
                NSError *error = nil; NSURLResponse *response = nil;
                NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
                if(data)
                {
                    NSError* error = nil;
                    NSDictionary* json = [NSJSONSerialization
                                          JSONObjectWithData:data
                                          options:kNilOptions
                                          error:&error];
                    if ([json objectForKey:@"access_token"])
                    {
                        NSString* token = [json objectForKey:@"access_token"];
                        NSDictionary* user = [json objectForKey:@"user"];
                        NSString *userName = [user objectForKey:@"username"];
                        NSString *profilePicture = [user objectForKey:@"profile_picture"];
                        NSString *userID = [user objectForKey:@"id"];
                        NSString *profileURL = [InstagramRequest profileURLForID:userName];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(delegate)
                                [delegate loginInstagramSuccessWithToken:token
                                                               andUserID:userID
                                                           andScreenName:userName
                                                             andImageURL:profilePicture
                                                           andProfileURL:profileURL];
                        });
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if(delegate)
                                [delegate loginFail];
                        });
                    }
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(delegate)
                            [delegate loginFail];
                    });
                }
            });
            return NO;
        }
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [instagramWebActivityIndicator stopAnimating];
}

#pragma mark - Actions

-(void)cancelPressed:(id)sender
{
    [delegate loginCencel];
}

#pragma mark - Instruments

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
