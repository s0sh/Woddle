//
//  FacebookLoginViewController.m
//  Woddl
//
//  Created by Александр Бородулин on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookLoginViewController.h"
#import "FacebookPictures.h"
#import "FacebookRequest.h"

@interface FacebookLoginViewController ()<UIWebViewDelegate>

@end

@implementation FacebookLoginViewController

static NSString* redirectUri = @"https://www.woddleapp.com/post_login_page";
static NSString* extended_permissions = @"offline_access,publish_actions,read_stream,read_mailbox,xmpp_login,user_subscriptions,user_relationships,user_work_history,user_groups,user_events,user_about_me,publish_stream,user_photos,manage_pages,manage_notifications";

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
    
    fbWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0+navBarWidth, screenWidth,screenHeight-navBarWidth)];
    fbWebView.delegate = self;
    [self.view addSubview:fbWebView];
    
    fbWebActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    fbWebActivityIndicator.center = self.view.center;
    [self.view addSubview:fbWebActivityIndicator];
	// Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated
{
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *facebookCookies = [cookies cookiesForURL:[NSURL URLWithString:@"https://graph.facebook.com"]];
    for(NSHTTPCookie* cookie in facebookCookies)
    {
        [cookies deleteCookie:cookie];
    }
    NSString *fbAuthorizeURL = [NSString stringWithFormat:@"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=%@&scope=%@&type=user_agent&display=touch", kFacebookAccessKey, redirectUri, extended_permissions];
    NSURL *url = [NSURL URLWithString:fbAuthorizeURL];
    [fbWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [fbWebActivityIndicator startAnimating];
    NSString *requestPath = [[request URL] absoluteString];
    if ([requestPath rangeOfString:redirectUri].location != NSNotFound)
    {
        if([requestPath rangeOfString:@"access_token="].location != NSNotFound)
        {
            NSString * token = [self stringBetweenString:@"access_token=" andString:@"&" innerString:requestPath];
            NSString* expire = [self stringBetweenString:@"expires_in=" andString:@"" innerString:requestPath];
            if (!expire.integerValue)
            {
                expire = @(INT32_MAX).stringValue;
            }
            
//            NSString *request = [NSString stringWithFormat:@"https://graph.facebook.com/me?fields=id,name&access_token=%@",token];
            NSString *request = [NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT uid,name,pic_square,profile_url FROM user WHERE uid == me()&access_token=%@",token];
            request = [request stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            NSMutableURLRequest *requestURL = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:request]
                                                                      cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                                  timeoutInterval:60.0];
            NSData *responseData = [NSURLConnection sendSynchronousRequest:requestURL returningResponse:nil error:nil];
            if(responseData)
            {
                NSError* error = nil;
                NSDictionary* json = [NSJSONSerialization
                                      JSONObjectWithData:responseData
                                      
                                      options:kNilOptions
                                      error:&error];
                if(!error && json[@"data"])
                {
                    NSDictionary *userInfo = [json[@"data"] firstObject];
                    

                    NSString *userID = userInfo[@"uid"];
                    NSString *profileURL = userInfo[@"profile_url"];
                    NSString* userIDStr = [NSString stringWithFormat:@"%lli",[userID longLongValue]];
                    NSString *screenName = userInfo[@"name"];
                    NSString *imageURL = userInfo[@"pic_square"];
                    
                    [delegate loginSuccessWithToken:token
                                      andTimeExpire:expire
                                          andUserID:userIDStr
                                      andScreenName:screenName
                                        andImageURL:imageURL
                                      andProfileURL:profileURL];
                }
            }
        }
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [fbWebActivityIndicator stopAnimating];
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
