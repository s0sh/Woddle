//
//  GoogleAPI.m
//  Woddl
//
//  Created by Александр Бородулин on 03.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "GoogleAPI.h"
#import "GoogleLoginViewController.h"

@interface GoogleAPI ()<GoogleLoginViewControllerDelegate>

@end

@implementation GoogleAPI

static GoogleAPI* myGoogle = nil;

+(GoogleAPI*)Instance
{
    static dispatch_once_t pred;
    dispatch_once(&pred,^{
        myGoogle = [[super allocWithZone:NULL] init];
    });
    return myGoogle;
}

- (id) init
{
    if (self = [super init])
    {
    }
    return self;
}

-(void)loginWithDelegate:(id<GoogleAPIDelegate>)delegate_
{
    GoogleLoginViewController *googleController  = [[GoogleLoginViewController alloc] init];
    googleController.delegate = self;
    delegate = delegate_;
    if(delegate)
        [delegate loginGoogleViewController:googleController];
}

#pragma mark - Facebook Delegate

-(void)loginSuccessWithToken:(NSString *)token andTimeExpire:(NSString *)expires andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andProfileURL:(NSString *)profileURLString
{
    OAuthToken = token;
    expiresIn = expires;
    //NSDate *today = [NSDate date];
    //NSDate *expireDate = [today dateByAddingTimeInterval:[expiresIn intValue]];
    if(delegate)
    {
        [delegate loginGoogleWithSuccessWithToken:OAuthToken
                                        andExpire:nil
                                        andUserID:userID
                                    andScreenName:name
                                      andImageURL:imageURL
                                    andProfileURL:profileURLString];
    }
    delegate = nil;
}

-(void)loginCencel
{
    if(delegate)
        [delegate loginGoogleWithFail];
    delegate = nil;
}

@end
