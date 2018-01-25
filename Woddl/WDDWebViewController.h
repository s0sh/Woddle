//
//  WDDWebViewController.h
//  Woddl
//
//  Created by Алексей Поляков on 05.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SocialNetwork;

@interface WDDWebViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) NSURL     *url;
@property (nonatomic, strong) SocialNetwork *sourceNetwork;
@property (nonatomic, assign) BOOL requireAuthorization;

@property (nonatomic, assign) NSString *customTitle;

@end
