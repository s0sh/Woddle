//
//  TwitterRequest.h
//  Woddl
//
//  Created by Александр Бородулин on 05.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "NetworkRequest.h"

@class WDDLocation;

@interface TwitterRequest : NetworkRequest

- (NSArray *)getPostsWithToken:(NSString *)token andUserID:(NSString *)userID andCount:(NSUInteger)count upToPostWithID:(NSString *)postId;
- (BOOL)isPostLikedMe:(NSString *)postID withToken:(NSString *)token andMyID:(NSString *)myID;
- (BOOL)setLikeOnObjectID:(NSString *)objectID withToken:(NSString *)token;
- (BOOL)setUnlikeOnObjectID:(NSString *)objectID withToken:(NSString *)token;
- (BOOL)retweet:(NSString *)tweetID withToken:(NSString *)token;
- (BOOL)addTwitt:(NSString *)message withLink:(NSString *)link andToken:(NSString *)token;
- (NSDictionary*)replyToTwittWithMessage:(NSString *)message andTwittID:(NSString *)twittID andImage:(NSData*)image andToken:(NSString *)token;
- (NSDictionary*)addStatusWithMessage:(NSString *)message andImage:(NSData*)image location:(WDDLocation *)location andToken:(NSString *)token;
- (NSArray*)searchPostsWithSearchText:(NSString *)searchText token:(NSString*)token limit:(NSUInteger)limit;

- (NSArray *)getCommentsWithTrack:(NSString *)track postID:(NSString*)postID fromID:(NSString *)fromID count:(NSUInteger)count;

- (NSArray *)getPostsWithToken:(NSString *)token fromID:(NSString*)fromID to:(NSString*)to;
- (NSArray *)getCommentsWithTrack:(NSString *)track sinceID:(NSString *)fromID;
- (NSArray *)getFriendsWithToken:(NSString *)token userID:(NSString *)userID;
- (id)profileInformationWithToken:(NSString *)token;

- (NSDictionary*)getPostInfoWithToken:(NSString *)token andData:(NSDictionary*)post;

+ (NSString *)profileURLWithName:(NSString *)name;



@end
