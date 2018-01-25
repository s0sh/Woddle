//
//  FacebookAPI.m
//  Woddl
//
//  Created by Александр Бородулин on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookAPI.h"
#import "FacebookLoginViewController.h"
#import "FacebookPublishing.h"
#import "NetworkRequest.h"
#import "FacebookGroupsInfo.h"

#define bgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)

@interface FacebookAPI ()<fbLoginViewControllerDelegate>

@end

@implementation FacebookAPI

static FacebookAPI* myFacebook = nil;

+(FacebookAPI*)instance
{
    static dispatch_once_t pred;
    dispatch_once(&pred,^{
        myFacebook = [[super allocWithZone:NULL] init];
    });
    return myFacebook;
}

- (id) init
{
    if (self = [super init])
    {
    }
    return self;
}

-(void)loginWithDelegate:(id<FacebookAPIDelegate>)delegate_
{
    FacebookLoginViewController *fbController  = [[FacebookLoginViewController alloc] init];
    fbController.delegate = self;
    delegate = delegate_;
    if(delegate)
        [delegate loginFacebookViewController:fbController];
}

- (BOOL)loginWithToken:(NSString *)token expire:(NSDate *)expire delegate:(id<FacebookAPIDelegate>)delegate_
{
    if (!token || !expire)
    {
        if (delegate_)
        {
            [delegate_ loginFailFromDeviceFacebookAccount];
        }
        return NO;
    }
    
    delegate = delegate_;
    
    dispatch_async(bgQueue, ^{
        
        NSString *request = [NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT uid,name,pic_square,profile_url FROM user WHERE uid == me()&access_token=%@",token];
        request = [request stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSMutableURLRequest *requestURL = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:request]
                                                                  cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                              timeoutInterval:60.0];
        NSData *responseData = [NSURLConnection sendSynchronousRequest:requestURL returningResponse:nil error:nil];
        if(responseData)
        {
            NSError* error = nil;
            NSDictionary* json = [NSJSONSerialization
                                  JSONObjectWithData:responseData
                                  
                                  options:kNilOptions
                                  error:&error];
            
            DLog(@"Got response on login: %@", json);
            
            if(!error && json[@"data"])
            {
                NSDictionary *userInfo = [json[@"data"] firstObject];
                
                
                NSString *userID = userInfo[@"uid"];
                NSString* userIDStr = [NSString stringWithFormat:@"%lli",[userID longLongValue]];
                NSString *screenName = userInfo[@"name"];
                NSString *imageURL = userInfo[@"pic_square"];
                NSString *profileURL = userInfo[@"profile_url"];
                
                [self loginSuccessWithToken:token
                              andTimeExpire:expire
                                  andUserID:userIDStr
                              andScreenName:screenName
                                andImageURL:imageURL
                              andProfileURL:profileURL];
            }
            else
            {
                DLog(@"Got error on logging in: %@", error.localizedDescription);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(delegate)
                        [delegate loginFailFromDeviceFacebookAccount];
                    delegate = nil;
                });
                
            }
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(delegate)
                    [delegate loginFailFromDeviceFacebookAccount];
                delegate = nil;
            });
        }
    });
    return YES;
}

#pragma mark - Facebook Delegate

-(void)loginSuccessWithToken:(NSString*)token andTimeExpire:(NSDate *)expires andUserID:(NSString *)userID andScreenName:(NSString *)name andImageURL:(NSString *)imageURL andProfileURL:(NSString *)profileURLString
{
    OAuthToken = token;
    if ([expires isKindOfClass:[NSString class]])
    {
        NSDate *today = [NSDate date];
        expiresIn = [today dateByAddingTimeInterval:[(NSString *)expires intValue]];
    }
    else
    {
        expiresIn = expires;
    }
    
    dispatch_async(bgQueue, ^{
        
        FacebookGroupsInfo* groupsInfo = [[FacebookGroupsInfo alloc] init];
        NSArray* groups = nil;
#if FB_GROUPS_SUPPORT
        groups = [groupsInfo getAllGroupsWithUserID:userID andToken:token];
#else
        groups = [groupsInfo getOwnAndAdmistrativeGroupsForUserID:userID token:token];
#endif
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if(delegate)
            {
                [delegate loginWithSuccessWithToken:token
                                          andExpire:expiresIn
                                          andUserID:userID
                                      andScreenName:name
                                        andImageURL:imageURL
                                      andProfileURL:profileURLString
                                          andGroups:groups];
            }
            delegate = nil;
        });
    });
}

-(void)loginCencel
{
    if(delegate)
        [delegate loginWithFail];
    delegate = nil;
}
@end
