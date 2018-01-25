//
//  LinkedinAPI.m
//  Woddl
//
//  Created by Александр Бородулин on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinAPI.h"
#import "LinkedinLoginViewController.h"
#import "LinkedinRequest.h"


#define bgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)

@interface LinkedinAPI ()<LinkedinLoginViewControllerDelegate>

@end

@implementation LinkedinAPI

static LinkedinAPI* myLinkedin = nil;

#pragma mark - Initialization

+(LinkedinAPI*)Instance
{
    static dispatch_once_t pred;
    dispatch_once(&pred,^{
        myLinkedin = [[super allocWithZone:NULL] init];
    });
    return myLinkedin;
}

- (id) init
{
    if (self = [super init])
    {
    }
    return self;
}

#pragma mark - Login

-(void)loginWithDelegate:(id<LinkedinAPIDelegate>)delegate_
{
    LinkedinLoginViewController *inController  = [[LinkedinLoginViewController alloc] init];
    inController.delegate = self;
    delegate = delegate_;
    if(delegate)
        [delegate loginLinkedinViewController:inController];
}

#pragma mark - Delegate

-(void)loginCencel
{
    if(delegate)
        [delegate loginLinkedinFailed];
    delegate = nil;
}

-(void)loginFailed
{
    if(delegate)
        [delegate loginLinkedinFailed];
    delegate = nil;
}

-(void)loginLinkedinSuccessWithToken:(NSString *)token andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andTimeExpire:(NSString*)expires andProfileURL:(NSString *)profileURLString
{
    NSDate *today = [NSDate date];
    NSDate *expireDate = [today dateByAddingTimeInterval:[expires intValue]];
    dispatch_async(bgQueue, ^{
        
        NSArray *groups = nil;
#if LINKEDIN_GROUPS_SUPPORT == ON

        LinkedinRequest* linkedinRequest = [[LinkedinRequest alloc] init];
        groups = [linkedinRequest getGroupsWithToken:token];
#endif
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(delegate)
            {
                [delegate loginLinkedinSuccessWithToken:token
                                              andUserID:userID
                                          andScreenName:name
                                            andImageURL:imageURL
                                          andTimeExpire:expireDate
                                          andProfileURL:profileURLString
                                              andGroups:groups];
                delegate = nil;
        }
        });
    });
}

@end
