//
//  TwitterAPI.h
//  Woddl
//
//  Created by Александр Бородулин on 30.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TWAPIManager.h"

@class FHSTwitterEngine, ACAccount;

@protocol TwitterAPIDelegate;
@interface TwitterAPI : TWAPIManager
{
    NSString* userAccessToken;
}

+ (TwitterAPI*)Instance;
+ (FHSTwitterEngine *) createTwitterEngine;
+ (FHSTwitterEngine *) createTwitterEngineWithToken:(NSString *)token;
- (void)showLoginWindowWithTarget:(UIViewController*)target;

- (void)proceedLoginWithAccount:(ACAccount*)account target:(UIViewController *)target;
- (void)switchOnToken:(NSString*)newToken;
- (NSString*)getOAuthSecret;

- (void)fetchNotificationsForUserId:(NSString*)userId
                        accessToken:(NSString*)accessToken;
- (void)cancelFetchingNotificationsForUserId:(NSString*)userId;

@end

@protocol TwitterAPIDelegate <NSObject>
@optional
- (void)loginTwitterWithSuccessWithToken:(NSString*)token andName:(NSString*)name andUserID:(NSString*)userID andImageURL:(NSString*)imageURL andFollowers:(NSArray*)followers andProfileURL:(NSString *)profileURLString;
- (void)didFailLoginWithTwitter;
@end
