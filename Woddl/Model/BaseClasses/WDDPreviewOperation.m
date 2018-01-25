//
//  WDDPreviewOperation.m
//  Woddl
//
//  Created by Oleg Komaristov on 12/17/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDPreviewOperation.h"
#import "WDDCookiesManager.h"
#import "WDDAppDelegate.h"

#import "UIImage+Blur.h"
#import "UIImage+ResizeAdditions.h"
#import "SocialNetwork.h"

static const NSInteger MaximumAttemptsCount = 5;
static NSString * const kItunesPreviewImageName = @"preview_for_itunes";
static NSString * const kAppStorePreviewImageName = @"preview_for_appstore";

@interface WDDPreviewOperation () <UIWebViewDelegate>

@property (nonatomic, strong) NSURL *previewURL;
@property (nonatomic, strong) id <WDDPreviewOperationDelegate> delegate;
@property (nonatomic, strong) UIWebView *webView;

@property (nonatomic, assign) NSInteger attemptCount;
@property (nonatomic, strong) dispatch_semaphore_t viewPreparingSemaphore;
@property (nonatomic, strong) SocialNetwork *socialNetwork;
@end

@implementation WDDPreviewOperation

- (id)initWithURL:(NSURL *)url delegate:(id <WDDPreviewOperationDelegate>)delegate socialNetwork:(SocialNetwork *)socialNetwork
{
    if (self = [super init])
    {
        self.previewURL = url;
        self.delegate = delegate;
        self.socialNetwork = socialNetwork;
    }
    
    return self;
}

- (void)main
{
    self.viewPreparingSemaphore = dispatch_semaphore_create(0);
    
    if (self.isAuthorizationRequired)
    {
        BOOL __unused unused = [[WDDCookiesManager sharedManager] activateCookieForSocialNetwork:self.socialNetwork];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.webView = [[UIWebView alloc] initWithFrame:(CGRect){CGPointMake(CGRectGetWidth([UIScreen mainScreen].bounds), 0.f), [UIScreen mainScreen].bounds.size}];
        [[[UIApplication sharedApplication].delegate window] addSubview:self.webView];
        self.webView.delegate = self;
        [self.webView loadRequest:[NSURLRequest requestWithURL:self.previewURL]];
    });
    
    if (!dispatch_semaphore_wait(self.viewPreparingSemaphore, dispatch_time(DISPATCH_TIME_NOW, 120 * NSEC_PER_SEC)))
    {
        [self setPreviewPlaceholderWithImageName:nil];
    }
    self.viewPreparingSemaphore = nil;
}

#pragma mark - UIWebViewDelegate protocol implementation

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (
        [request.URL.absoluteString rangeOfString:@"http" options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [request.URL.absoluteString rangeOfString:@"https" options:NSCaseInsensitiveSearch].location != NSNotFound)
    {
        return YES;
    }
    
    if ([request.URL.scheme isEqual:@"itms-apps"])
    {
        [self setPreviewPlaceholderWithImageName:kAppStorePreviewImageName];
    }
    else if ([request.URL.scheme isEqual:@"itmss"])
    {
        [self setPreviewPlaceholderWithImageName:kItunesPreviewImageName];
    }
    
    return NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self performSelector:@selector(getPreviewScreen) withObject:nil afterDelay:0.5];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [self.delegate previewPreparedForLink:self.previewURL preview:nil];
    [self.webView removeFromSuperview];
    self.webView = nil;

    if (self.viewPreparingSemaphore)
    {
        dispatch_semaphore_signal(self.viewPreparingSemaphore);
    }
}

- (void)setPreviewPlaceholderWithImageName:(NSString *)imageName
{
    UIImage *previewImage = [UIImage imageNamed:imageName];
    [self.delegate previewPreparedForLink:self.previewURL preview:previewImage];
    [self.webView removeFromSuperview];
    self.webView = nil;
    
    if (self.viewPreparingSemaphore)
    {
        dispatch_semaphore_signal(self.viewPreparingSemaphore);
    }
}

- (void)getPreviewScreen
{
    UIImage *preview = [UIImage imageWithView:self.webView];
    
    if (![self isImageEmpty:preview])
    {
        [self.delegate previewPreparedForLink:self.previewURL preview:preview];
        [self.webView removeFromSuperview];
        self.webView = nil;
        
        if (self.viewPreparingSemaphore)
        {
            dispatch_semaphore_signal(self.viewPreparingSemaphore);
        }
    }
    else
    {
        if (self.attemptCount >= MaximumAttemptsCount)
        {
            [self.delegate previewPreparedForLink:self.previewURL preview:nil];
            [self.webView removeFromSuperview];
            self.webView = nil;
            
            if (self.viewPreparingSemaphore)
            {
                dispatch_semaphore_signal(self.viewPreparingSemaphore);
            }
        }
        else
        {
            [self performSelector:@selector(getPreviewScreen) withObject:nil afterDelay:0.3];
        }
    }
}

- (BOOL)isImageEmpty:(UIImage *)image
{
    if (!image)
    {
        return YES;
    }
    
    BOOL result = YES;
    
    NSData *data = (__bridge_transfer NSData *)CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
    unsigned char *pixels = (unsigned char *)[data bytes];
    unsigned char color[3];
    
    if (data.length > 3)
    {
        memccpy(color, pixels, 1, 3);
    }
    
    for(int i = 0; i < [data length]; i += 4) {
        if (memcmp(color, (pixels + i), 3))
        {
            result = NO;
            break;
        }
    }
    return result;
}

@end
