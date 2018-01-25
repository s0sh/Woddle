//
//  FoursquareLoginViewController.m
//  Woddl
//
//  Created by Александр Бородулин on 01.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FoursquareLoginViewController.h"
#import "FoursquareRequest.h"

#define bgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)

@interface FoursquareLoginViewController ()<UIWebViewDelegate>

@end

@implementation FoursquareLoginViewController

static NSString* redirectUri = @"http://www.woodleapp.com";
static NSString* version = @"20131101";

@synthesize delegate;

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
    
    UINavigationBar* foursquareNavBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, navBarWidth)];
    foursquareNavBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:foursquareNavBar];
    
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
    
	[foursquareNavBar pushNavigationItem:navItem animated:NO];
    
    foursquareWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0+navBarWidth, screenWidth,screenHeight-navBarWidth)];
    foursquareWebView.delegate = self;
    [self.view addSubview:foursquareWebView];
    
    fqWebActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    fqWebActivityIndicator.center = self.view.center;
    [self.view addSubview:fqWebActivityIndicator];
    
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *fqCookiesApi = [cookies cookiesForURL:[NSURL URLWithString:@"https://foursquare.com"]];
    for(NSHTTPCookie* cookie in fqCookiesApi)
    {
        [cookies deleteCookie:cookie];
    }
    NSString *fqAuthorizeURL = [NSString stringWithFormat:@"https://foursquare.com/oauth2/authorize?response_type=token&redirect_uri=%@&client_id=%@",redirectUri,kFourSquareClientID];
    NSURL *url = [NSURL URLWithString:fqAuthorizeURL];
    [foursquareWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

#pragma mark - Web View Delegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [fqWebActivityIndicator startAnimating];
    NSString *requestPath = [[request URL] absoluteString];
    if ([requestPath rangeOfString:redirectUri].location != NSNotFound)
    {
        if ([requestPath rangeOfString:@"#access_token="].location != NSNotFound)
        {
            dispatch_async(bgQueue,^{
                NSString* token = [self stringBetweenString:@"#access_token=" andString:@"" innerString:requestPath];
                DLog(@"token = %@",token);
                NSDictionary* userData = [self getUserInfoWithToken:token];
                if(userData)
                {
                    NSString* userID = [userData objectForKey:@"id"];
                    NSString* displayName = [userData objectForKey:@"displayName"];
                    NSString* photo = [userData objectForKey:@"photo"];
                    NSString *profileURL = [FoursquareRequest profileURLWithID:userID];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(delegate)
                            [delegate loginFoursquareSuccessWithToken:token
                                                            andUserID:userID
                                                        andScreenName:displayName
                                                          andImageURL:photo
                                                        andProfileURL:profileURL];
                    });
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(delegate)
                            [delegate loginFailed];
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
    [fqWebActivityIndicator stopAnimating];
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

-(NSDictionary*)getUserInfoWithToken:(NSString*)token
{
    NSMutableURLRequest *userRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.foursquare.com/v2/users/self?oauth_token=%@&v=%@",token,version]]];
    
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:userRequest returningResponse:&response error:&error];
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if([json objectForKey:@"response"])
        {
            NSDictionary* response = [json objectForKey:@"response"];
            NSDictionary* user = [response objectForKey:@"user"];
            [result s_setObject:[user objectForKey:@"id"] forKey:@"id"];
            NSString* firstName = [user objectForKey:@"firstName"];
            NSString* lastName = [user objectForKey:@"lastName"];
            NSString* displayName;
            if(firstName)
            {
                displayName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
            }
            else
            {
                displayName = [NSString stringWithFormat:@"%@",lastName];
            }
            [result s_setObject:displayName forKey:@"displayName"];
            NSDictionary* photoJSON = [user objectForKey:@"photo"];
            NSString* photoPrefix = [photoJSON objectForKey:@"prefix"];
            NSString* photoSuffix = [photoJSON objectForKey:@"suffix"];
            NSString* photoURL = [NSString stringWithFormat:@"%@150x150%@",photoPrefix,photoSuffix];
            [result s_setObject:photoURL forKey:@"photo"];
        }
        else
            return nil;
    }
    
    return result;
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
