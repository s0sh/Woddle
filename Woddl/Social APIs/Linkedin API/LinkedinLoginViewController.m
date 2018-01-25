//
//  LinkedinLoginViewController.m
//  Woddl
//
//  Created by Александр Бородулин on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinLoginViewController.h"
#import "DDXML.h"
#import "LinkedinRequest.h"

#define bgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)

@interface LinkedinLoginViewController ()<UIWebViewDelegate>

@end

@implementation LinkedinLoginViewController

static NSString* scope = @"r_fullprofile%20r_emailaddress%20r_network%20rw_groups%20r_contactinfo%20w_messages%20rw_nus%20rw_company_admin%20r_basicprofile";
static NSString* redirectUri = @"http://www.woddl.com";

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
    
    UINavigationBar* inNavBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, navBarWidth)];
    inNavBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:inNavBar];
    
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
    
	[inNavBar pushNavigationItem:navItem animated:NO];
    
    inWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0+navBarWidth, screenWidth,screenHeight-navBarWidth)];
    inWebView.delegate = self;
    [self.view addSubview:inWebView];
    
    inWebActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    inWebActivityIndicator.center = self.view.center;
    [self.view addSubview:inWebActivityIndicator];
}

-(void)viewDidAppear:(BOOL)animated
{
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *inCookiesApi = [cookies cookiesForURL:[NSURL URLWithString:@"https://www.linkedin.com"]];
    for(NSHTTPCookie* cookie in inCookiesApi)
    {
        [cookies deleteCookie:cookie];
    }
    NSString *inAuthorizeURL = [NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth2/authorization?response_type=code&client_id=%@&scope=%@&state=LFEEFWF45KJGsdffef151&redirect_uri=%@",kLinkedInApiKey,scope,redirectUri];
    NSURL *url = [NSURL URLWithString:inAuthorizeURL];
    [inWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Web View Delegate

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    [inWebActivityIndicator startAnimating];
    NSString *requestPath = [[request URL] absoluteString];
    if ([requestPath rangeOfString:redirectUri].location != NSNotFound && [requestPath rangeOfString:@"code="].location != NSNotFound)
    {
        dispatch_async(bgQueue,^{
            NSString* code = [self stringBetweenString:@"code=" andString:@"&" innerString:requestPath];
            NSMutableURLRequest *requestToken = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.linkedin.com/uas/oauth2/accessToken?grant_type=authorization_code&code=%@&redirect_uri=%@&client_id=%@&client_secret=%@",code,redirectUri,kLinkedInApiKey,kLinkedInSecret]]];
            NSError *error = nil; NSURLResponse *response = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:requestToken returningResponse:&response error:&error];
        
            if(data)
            {
                NSError* error = nil;
                NSDictionary* json = [NSJSONSerialization
                                  JSONObjectWithData:data
                                  options:kNilOptions
                                  error:&error];
                NSString* token = [json objectForKey:@"access_token"];
                NSString* expired_in = [json objectForKey:@"access_token"];
                NSDictionary* user = [self getUserInfoWithToken:token];
                if(user)
                {
                    NSString* userID = [user objectForKey:@"id"];
                    NSString* name = [user objectForKey:@"name"];
                    NSString* photoURL = [user objectForKey:@"photo"];
                    NSString *profileURL = [LinkedinRequest publicProfileURLWithID:userID
                                                                             token:token];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(delegate)
                            [delegate loginLinkedinSuccessWithToken:token
                                                          andUserID:userID
                                                      andScreenName:name
                                                        andImageURL:photoURL
                                                      andTimeExpire:expired_in
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
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(delegate)
                        [delegate loginFailed];
                });
            }
        });
    }
    else if([requestPath rangeOfString:@"the+user+denied+your+request"].location != NSNotFound)
    {
        [delegate loginCencel];
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [inWebActivityIndicator stopAnimating];
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
    NSMutableURLRequest *userRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/~:(first-name,last-name,picture-url,id)?oauth2_access_token=%@",token]]];
    
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:userRequest returningResponse:&response error:&error];
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    
    if(data)
    {
        DDXMLDocument *xmlDocument = [[DDXMLDocument alloc] initWithData:data options:0 error:&error];
        DDXMLElement *rootElement = xmlDocument.rootElement;
        DDXMLElement* userIDElement = [[rootElement elementsForName:@"id"] firstObject];
        NSString* userID = [userIDElement stringValue];
        DDXMLElement* firstNameElement = [[rootElement elementsForName:@"first-name"] firstObject];
        NSString* firstName = [firstNameElement stringValue];
        DDXMLElement* lastNameElement = [[rootElement elementsForName:@"last-name"] firstObject];
        NSString* lastName = [lastNameElement stringValue];
        NSString* name = nil;
        if(firstName)
        {
            if(firstName.length>0)
            {
                name = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
            }
            else
            {
                name = [NSString stringWithFormat:@"%@",lastName];
            }
        }
        else
        {
            name = [NSString stringWithFormat:@"%@",lastName];
        }
        
        NSArray* photoURLElementsArray = [rootElement elementsForName:@"picture-url"]; //check if image-url exist
        NSString* photoURL = nil;
        if(photoURLElementsArray)
        {
            DDXMLElement* photoURLElement = [photoURLElementsArray lastObject];
            photoURL = [photoURLElement stringValue];
        }
        if (userID)
            [result setObject:userID forKey:@"id"];
        if(name)
            [result setObject:name forKey:@"name"];
        if(photoURL)
            [result setObject:photoURL forKey:@"photo"];
    }
    return result;
}

@end
