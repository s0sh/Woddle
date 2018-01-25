//
//  FoursquareAPI.m
//  Woddl
//
//  Created by Александр Бородулин on 01.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FoursquareAPI.h"
#import "FoursquareLoginViewController.h"

@interface FoursquareAPI ()<FoursquareLoginViewControllerDelegate>

@end

@implementation FoursquareAPI

static FoursquareAPI* myFoursquare = nil;

#pragma mark - Initialization

+(FoursquareAPI*)Instance
{
    static dispatch_once_t pred;
    dispatch_once(&pred,^{
        myFoursquare = [[super allocWithZone:NULL] init];
    });
    return myFoursquare;
}

- (id) init
{
    if (self = [super init])
    {
    }
    return self;
}

#pragma mark - Login

-(void)loginWithDelegate:(id<FoursquareAPIDelegate>)delegate_
{
    FoursquareLoginViewController *foursquareController  = [[FoursquareLoginViewController alloc] init];
    foursquareController.delegate = self;
    delegate = delegate_;
    if(delegate)
        [delegate loginFoursquareViewController:foursquareController];
}

#pragma mark - Delegate

-(void)loginCencel
{
    if(delegate)
        [delegate loginFoursquareFailed];
    delegate = nil;
}

-(void)loginFoursquareSuccessWithToken:(NSString *)token andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andProfileURL:(NSString *)profileURLString
{
    if(delegate)
        [delegate loginFoursquareSuccessWithToken:token andUserID:userID andScreenName:name andImageURL:imageURL andProfileURL:profileURLString];
    delegate = nil;
}

-(void)loginFailed
{
    if(delegate)
        [delegate loginFoursquareFailed];
    delegate = nil;
}

@end
