//
//  IDSAppDelegate.m
//  Woddl
//
//  Created by Sergii Gordiienko on 22.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDAppDelegate.h"
#import "WDDDataBase.h"

#import "WDDLocationManager.h"
#import "WDDCookiesManager.h"
#import "WDDNotificationsManager.h"
#import "KeychainItemWrapper.h"

#import <GooglePlus/GooglePlus.h>
#import <Parse.h>
#import "SAMHUDView.h"
#import <FlurrySDK/Flurry.h>
#import <Heatmaps/Heatmaps.h>

#import "AvatarManager.h"
#import "WDDConstants.h"


BOOL isDeviceJailbroken()
{
    FILE *f = fopen("/bin/bash", "r");
    BOOL isDeviceJailbroken = (f != NULL);
    if (f) fclose(f);
    return isDeviceJailbroken;
}

@interface WDDAppDelegate () <UIGestureRecognizerDelegate>
{
    SAMHUDView *hud;
    BOOL                        shouldDismissKeyboardOnSwipe;
    UISwipeGestureRecognizer    *keyboardHideSwipeRecognizer;
}

@end

@implementation WDDAppDelegate

@synthesize networkActivityIndicatorCounter = _networkActivityIndicatorCounter;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.appStartTime = [NSDate date];
    
    [[Heatmaps instance] start];
    [Heatmaps instance].customAppName = @"Woddl";
    
#pragma mark Reachability
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    _reach = [Reachability reachabilityForInternetConnection];
    [_reach startNotifier];
    
    if ([_reach currentReachabilityStatus] != NotReachable)
    {
        _isInternetConnected = YES;
    }
    else
    {
        _isInternetConnected = NO;
    }
    
#pragma mark Google plus
    
    [[GPPSignIn sharedInstance] signOut];
    [WDDLocationManager sharedLocationManager];
    
#if IS_TESTFLIGHT_RELEASE == ON
    [TestFlight addCustomEnvironmentInformation:(isDeviceJailbroken() ? @"YES" : @"NO") forKey:@"Jailbreak"];
    [TestFlight takeOff:kTestflightSDKAppKey];
#else
    [Flurry setCrashReportingEnabled:YES];
#endif
    [Parse setApplicationId:kParseAppID clientKey:kParseClientKey];
    [Flurry startSession:kFlurryAnalyticsAppKey];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    [self loadAccessTokens];
    
    if (_isInternetConnected)
    {
        [self updateAccessTokens];
    }
    
    NSString *navigationBarImageName;
    if (IS_IOS7)
    {
        navigationBarImageName = @"MainScreen_nav_bar_ios7";
    }
    else
    {
        navigationBarImageName = @"MainScreen_nav_bar";
    }
    
    UIImage *navBackgroundImage = [[UIImage imageNamed:navigationBarImageName] resizableImageWithCapInsets:UIEdgeInsetsMake(10.f, 10.f, 10.f, 10.f)];
    [[UINavigationBar appearance] setBackgroundImage:navBackgroundImage forBarMetrics:UIBarMetricsDefault];
    
    if (!IS_IOS7)
    {
        UIColor *barItemTintColor = [UIColor colorWithWhite:0.15f alpha:1.f];
        [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTintColor:barItemTintColor];
    }
    
#ifdef DEBUG
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
#endif
     
    [AvatarManager sharedManager].placeholderImage = [UIImage imageNamed:kAvatarPlaceholderImageName];
    
#pragma mark - update posts when become active
    
    [WDDNotificationsManager sharedManager];
    
    return YES;
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    Reachability *currentReachability = [notification object];
    
    if ([currentReachability currentReachabilityStatus] != NotReachable)
    {
        _isInternetConnected = YES;
    }
    else
    {
        _isInternetConnected = NO;
    }
}

- (KeychainItemWrapper *)keychainItemForNetwork:(SocialNetworkType)network
{
    NSString *networkIdentifier = nil;
    
    switch (network) {
        case kSocialNetworkFacebook:
            networkIdentifier = @"Facebook";
        break;
            
        case kSocialNetworkTwitter:
            networkIdentifier = @"Twitter";
        break;
            
        case kSocialNetworkLinkedIN:
            networkIdentifier = @"LinkedIN";
        break;
            
        case kSocialNetworkFoursquare:
            networkIdentifier = @"Foursquare";
        break;
            
        case kSocialNetworkInstagram:
            networkIdentifier = @"Instagram";
        break;
            
        case kSocialNetworkGooglePlus:
            networkIdentifier = @"GooglePlus";
        break;
            
        default:
            networkIdentifier = @"Unknown";
        break;
    }
    
    return [[KeychainItemWrapper alloc] initWithIdentifier:networkIdentifier accessGroup:kWoddlKeychainGroup];
}

- (void)getAccessAndSecretTokensFromItem:(KeychainItemWrapper *)keychainItem accessToken:(NSString **)accessToken secretToken:(NSString **)secretToken
{
    *accessToken = [keychainItem objectForKey:(__bridge id)kSecAttrAccount];
    *secretToken = [keychainItem objectForKey:(__bridge id)kSecValueData];
    
    DLog(@"Got item for: %@ values: %@ %@", [keychainItem.genericPasswordQuery objectForKey:(__bridge id)kSecAttrAccessGroup], *accessToken, *secretToken);
}

- (void)setAccessAndSecretTokensForItem:(KeychainItemWrapper *)keychainItem accessToken:(NSString *)accessToken secretToken:(NSString *)secretToken
{
    [keychainItem resetKeychainItem];
    
    DLog(@"Will save item for: %@ values: %@ %@", [keychainItem.genericPasswordQuery objectForKey:(__bridge id)kSecAttrAccessGroup], accessToken, secretToken);
    
    if (accessToken)
    {
        [keychainItem setObject:accessToken forKey:(__bridge id)kSecAttrAccount];
    }
    if (secretToken)
    {
        [keychainItem setObject:secretToken forKey:(__bridge id)kSecValueData];
    }
}

- (void)loadAccessTokens
{
    NSString *accessKey = nil;
    NSString *secretKey = nil;
    [self getAccessAndSecretTokensFromItem:[self keychainItemForNetwork:kSocialNetworkFacebook]
                               accessToken:&accessKey
                               secretToken:&secretKey];
    if (accessKey)
    {
        kFacebookAccessKey = accessKey;
    }
    
    [self getAccessAndSecretTokensFromItem:[self keychainItemForNetwork:kSocialNetworkFoursquare]
                               accessToken:&accessKey
                               secretToken:&secretKey];
    if (accessKey && secretKey)
    {
        kFourSquareClientID = accessKey;
        kFourSquareSecret = secretKey;
    }
    
    [self getAccessAndSecretTokensFromItem:[self keychainItemForNetwork:kSocialNetworkGooglePlus]
                               accessToken:&accessKey
                               secretToken:&secretKey];
    if (accessKey && secretKey)
    {
        kGooglePlusClientID = accessKey;
        kGooglePlusClientSecret = secretKey;
    }
    
    [self getAccessAndSecretTokensFromItem:[self keychainItemForNetwork:kSocialNetworkInstagram]
                               accessToken:&accessKey
                               secretToken:&secretKey];
    if (accessKey && secretKey)
    {
        kInstagrammClientID = accessKey;
        kInstagrammClientSecret = secretKey;
    }
    
    [self getAccessAndSecretTokensFromItem:[self keychainItemForNetwork:kSocialNetworkLinkedIN]
                               accessToken:&accessKey
                               secretToken:&secretKey];
    if (accessKey && secretKey)
    {
        kLinkedInApiKey = accessKey;
        kLinkedInSecret = secretKey;
    }
    
    [self getAccessAndSecretTokensFromItem:[self keychainItemForNetwork:kSocialNetworkTwitter]
                               accessToken:&accessKey
                               secretToken:&secretKey];
    if (accessKey && secretKey)
    {
        kTwitterConsumerKey = accessKey;
        kTwitterConsumerSecret = secretKey;
    }
}

- (void)updateAccessTokens
{
    PFQuery *query = [PFQuery queryWithClassName:@"Keys"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        if (objects)
        {
            [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
            {
                [self setAccessAndSecretTokensForItem:[self keychainItemForNetwork:[obj[@"network"] integerValue]]
                                          accessToken:obj[@"accessKey"]
                                          secretToken:obj[@"secretKey"]];
                
                
                switch ([obj[@"network"] integerValue])
                {
                    case kSocialNetworkFacebook:
                        kFacebookAccessKey = obj[@"accessKey"];
                    break;
                        
                    case kSocialNetworkGooglePlus:
                        kGooglePlusClientID = obj[@"accessKey"];
                        kGooglePlusClientSecret = obj[@"secretKey"];
                    break;

                    case kSocialNetworkLinkedIN:
                        kLinkedInApiKey = obj[@"accessKey"];
                        kLinkedInSecret = obj[@"secretKey"];
                    break;

                    case kSocialNetworkTwitter:
                        kTwitterConsumerKey = obj[@"accessKey"];
                        kTwitterConsumerSecret = obj[@"secretKey"];
                    break;

                    case kSocialNetworkFoursquare:
                        kFourSquareClientID = obj[@"accessKey"];
                        kFourSquareSecret = obj[@"secretKey"];
                    break;

                    case kSocialNetworkInstagram:
                        kInstagrammClientID = obj[@"accessKey"];
                        kInstagrammClientSecret = obj[@"secretKey"];
                    break;
                        
                    default:
                    break;
                }                
            }];
        }
    }];

#if FB_GROUPS_SUPPORT == ON
    PFQuery *settingsQuery = [PFQuery queryWithClassName:@"Settings"];
    NSArray *objects = [settingsQuery findObjects];
    if (objects.count)
    {
        self.loadFBGroupsOneByOne = [[objects.firstObject objectForKey:@"LoadFBGroupsOneByOne"] boolValue];
    }
#endif
    
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [self observeKeyboard:NO];
    [self stopKeyboardDismissOnSwipe];

    if ([PFUser currentUser])
    {
        
        [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"user"];
        [[PFInstallation currentInstallation] saveEventually];
        //        NSDate *currentTime = [NSDate date];
        
        [[WDDCookiesManager sharedManager] removeAllCookies];
        [WDDDataBase initializeWithCallBack:^(BOOL success) {
            
            PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([SocialNetwork class])];
            [query whereKey:@"userOwner" equalTo:[PFUser currentUser]];
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
             {
                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                     [objects enumerateObjectsUsingBlock:^(PFObject *parseSocialNetwork, NSUInteger idx, BOOL *stop)
                      {
                          [[WDDDataBase sharedDatabase] updateSocialNetworkFromParse:parseSocialNetwork
                                                                        withDelegate:nil];
                      }];
                     
                     [Flurry setUserID:[PFUser currentUser].objectId];
//                     [[SocialNetworkManager Instance] updatePosts]; do not update posts on applicaiton come from background
                 });
             }];
        }];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self observeKeyboard:YES];
    [self startKeyboardDismissOnSwipe];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#ifdef DEBUG
void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
}
#endif

- (BOOL)application: (UIApplication *)application
            openURL: (NSURL *)url
  sourceApplication: (NSString *)sourceApplication
         annotation: (id)annotation
{
    if (url)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"HandleURL" object:nil];
    }
    
    return [GPPURLHandler handleURL:url
                  sourceApplication:sourceApplication
                         annotation:annotation];
}

- (BOOL)isFirstStart
{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:kFirstStartUserDefaultsKey];
}

#pragma mark - Local notifications

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateActive)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUnreadMessageRecieved object:nil];
    }
}

#pragma mark SAMHudView

- (void)showHUDWithTitle:(NSString *)title
{
    hud = [[SAMHUDView alloc] initWithTitle:title loading:YES];
    [hud show];
}

- (void)dismissHUD
{
    [hud dismissAnimated:YES];
}

#pragma mark - networkActivityIndicator

-(void)setNetworkActivityIndicatorCounter:(NSInteger)networkActivityIndicatorCounter
{
    @synchronized(self)
    {
        _networkActivityIndicatorCounter = networkActivityIndicatorCounter;
        if(self.networkActivityIndicatorCounter<=0)
        {
            _networkActivityIndicatorCounter = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                [[WDDDataBase sharedDatabase] save];
            });
//            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
//            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidDownloadNewPots object:nil];
        }
        else
        {
//            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        }
    }
}

-(NSInteger)networkActivityIndicatorCounter
{
    @synchronized(self)
    {
        return _networkActivityIndicatorCounter;
    }
}

#pragma mark - keyboard helper
#pragma mark public

- (void)startKeyboardDismissOnSwipe
{
    shouldDismissKeyboardOnSwipe = YES;
}

- (void)stopKeyboardDismissOnSwipe
{
    shouldDismissKeyboardOnSwipe = NO;
}

#pragma mark private
- (void)observeKeyboard:(BOOL)observe
{
    if (observe)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)keyboardDidShow:(NSNotification*)note
{
    UIView *keyboard = [self findKeyboardView];
    [keyboard addGestureRecognizer:[self keyboardHideSwipeRecognizer]];
}

- (void)keyboardWillHide:(NSNotification*)note
{
    UIView *keyboard = [self findKeyboardView];
    [keyboard removeGestureRecognizer:[self keyboardHideSwipeRecognizer]];
}

- (UIView *)findKeyboardView
{
    __block UIView *keyboardView = nil;
    
    NSArray *windowsArr = [[UIApplication sharedApplication] windows];
    [windowsArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if([obj isKindOfClass:NSClassFromString(@"UITextEffectsWindow")])
        {
            NSArray *subviewsArr = [obj subviews];
            [subviewsArr enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                if([obj isKindOfClass:NSClassFromString(@"UIPeripheralHostView")])
                {
                    keyboardView = (UIView *)obj;
                    *stop = YES;
                }
            }];
            if(keyboardView)
            {
                *stop = YES;
            }
        }
    }];
    
    return keyboardView;
}

- (UIView*)keyboardView
{
    return [self findKeyboardView];
}

- (UISwipeGestureRecognizer*)keyboardHideSwipeRecognizer
{
    if (!keyboardHideSwipeRecognizer)
    {
        keyboardHideSwipeRecognizer             = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                            action:@selector(keyboardHideSwipeRecognized:)];
        keyboardHideSwipeRecognizer.direction   = UISwipeGestureRecognizerDirectionDown;
        keyboardHideSwipeRecognizer.delegate    = self;
    }
    return keyboardHideSwipeRecognizer;
}

- (void)keyboardHideSwipeRecognized:(UISwipeGestureRecognizer*)recognizer
{
    [self.window endEditing:NO];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (gestureRecognizer == [self keyboardHideSwipeRecognizer])
    {
        return shouldDismissKeyboardOnSwipe;
    }
    return YES;
}

@end