//
//  GooglePlusLoginViewController.h
//  Woddl
//
//  Created by Алексей Поляков on 30.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

@protocol gpLoginViewControllerDelegate;

#import <UIKit/UIKit.h>
#import <GooglePlus/GooglePlus.h>
#import <GoogleOpenSource/GoogleOpenSource.h>

@interface GooglePlusLoginViewController : UIViewController <GPPSignInDelegate>

@property(nonatomic,weak) id<gpLoginViewControllerDelegate> delegate;

@end

@protocol gpLoginViewControllerDelegate <NSObject>

-(void)loginSuccessWithToken:(NSString*)token timeExpire:(NSString*)expires userID:(NSString*)userID userName:(NSString *)userName imageURL:(NSString *)imageURL;
-(void)loginCancel;

@end

