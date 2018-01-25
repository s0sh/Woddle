//
//  GoogleLoginViewController.h
//  Woddl
//
//  Created by Александр Бородулин on 03.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol GoogleLoginViewControllerDelegate;
@interface GoogleLoginViewController : UIViewController
{
    UIWebView* googleWebView;
    UIActivityIndicatorView* googleWebActivityIndicator;
}

@property(nonatomic,assign) id<GoogleLoginViewControllerDelegate> delegate;

@end

@protocol GoogleLoginViewControllerDelegate <NSObject>

-(void)loginSuccessWithToken:(NSString*)token andTimeExpire:(NSString*)expires andUserID:(NSString*)userID andScreenName:(NSString*)name andImageURL:(NSString*)imageURL andProfileURL:(NSString *)profileURLString;
-(void)loginCencel;

@end
