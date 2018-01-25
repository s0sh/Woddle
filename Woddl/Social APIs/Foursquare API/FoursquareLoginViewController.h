//
//  FoursquareLoginViewController.h
//  Woddl
//
//  Created by Александр Бородулин on 01.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FoursquareLoginViewControllerDelegate;
@interface FoursquareLoginViewController : UIViewController
{
    UIWebView* foursquareWebView;
    UIActivityIndicatorView* fqWebActivityIndicator;
}

@property(nonatomic,assign) id<FoursquareLoginViewControllerDelegate> delegate;

@end

@protocol FoursquareLoginViewControllerDelegate
-(void)loginFoursquareSuccessWithToken:(NSString*)token andUserID:(NSString*)userID andScreenName:(NSString*)name andImageURL:(NSString*)imageURL andProfileURL:(NSString *)profileURLString;
-(void)loginCencel;
-(void)loginFailed;
@end
