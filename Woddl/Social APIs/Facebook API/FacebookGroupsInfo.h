//
//  FacebookUserInfo.h
//  Woddl
//
//  Created by Александр Бородулин on 16.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FacebookGroupsInfo : NSObject

- (NSArray *)getAllGroupsWithUserID:(NSString *)userID andToken:(NSString *)token;
- (NSArray *)getOwnAndAdmistrativeGroupsForUserID:(NSString *)userId token:(NSString *)token;

- (NSArray*)parseGroups:(NSArray*)resultSet;
- (NSArray*)parsePages:(NSArray*)resultSet;

@end
