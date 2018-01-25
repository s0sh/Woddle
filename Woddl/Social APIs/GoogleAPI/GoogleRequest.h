//
//  GoogleRequest.h
//  Woddl
//
//  Created by Александр Бородулин on 04.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkRequest.h"

@interface GoogleRequest : NetworkRequest
{
    NSString* updateToken;
}

@property(nonatomic,retain) NSString* accessToken;

-(id)initWithToken:(NSString*)token;
- (NSArray *)getPostsWithCount:(NSUInteger)count andUserID:(NSString*) userID;
- (NSArray *)searchPostsWithSearchText:(NSString *)searchText
                                 limit:(NSUInteger)limit;
- (NSArray *)getPostsWithCount:(NSUInteger)count from:(NSString*)from;

- (void)addCommentWithMessage:(NSString *)message toPostURL:(NSString *)postURL;
-(NSArray*)getCommentsFromActivityID:(NSString*)activityID count:(NSUInteger)count;
-(NSArray*)getCommentsFromActivityID:(NSString*)activityID;

-(NSArray*)getFriends;

- (NSArray *)getStatusesFromPersonID:(NSString *)personID
                               count:(NSInteger)count
                              pageId:(NSString *)pageId
                          needPageId:(BOOL)needPageId;

@end
