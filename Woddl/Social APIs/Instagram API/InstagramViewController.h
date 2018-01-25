//
//  InstagramViewController.h
//  Woddl
//
//  Created by Александр Бородулин on 01.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol InstagramViewControllerDelegate;
@interface InstagramViewController : UIViewController
{
    UIWebView* instagramWebView;
    UIActivityIndicatorView* instagramWebActivityIndicator;
}
@property(nonatomic,assign) id<InstagramViewControllerDelegate> delegate;
@end

@protocol InstagramViewControllerDelegate
-(void)loginInstagramSuccessWithToken:(NSString*)token andUserID:(NSString*)userID andScreenName:(NSString*)name andImageURL:(NSString*)imageURL andProfileURL:(NSString *)profileURLString;
-(void)loginCencel;
-(void)loginFail;
@end
