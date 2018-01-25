//
//  WDDCookiesManager.h
//  Woddl
//
//  Created by Oleg Komaristov on 25.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocialNetwork.h"

@interface WDDCookiesManager : NSObject

+ (instancetype)sharedManager;

- (void)removeAllCookies;
- (void)registerCookieForSocialNetwork:(SocialNetwork *)socialNetwork;
- (BOOL)activateCookieForSocialNetwork:(SocialNetwork *)socialNetwork;

@end
