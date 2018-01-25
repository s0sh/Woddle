//
//  LinkedinLoginViewController.h
//  Woddl
//
//  Created by Александр Бородулин on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LinkedinLoginViewControllerDelegate;

@interface LinkedinLoginViewController : UIViewController
{
    UIWebView* inWebView;
    UIActivityIndicatorView* inWebActivityIndicator;
}

@property(nonatomic,assign) id<LinkedinLoginViewControllerDelegate> delegate;

@end

@protocol LinkedinLoginViewControllerDelegate

-(void)loginLinkedinSuccessWithToken:(NSString*)token
                           andUserID:(NSString*)userID
                       andScreenName:(NSString*)name
                         andImageURL:(NSString*)imageURL
                       andTimeExpire:(NSString*)expires
                       andProfileURL:(NSString *)profileURLString;
-(void)loginCencel;
-(void)loginFailed;

@end
