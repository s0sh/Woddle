//
//  FacebookRequest.h
//  Woddl
//
//  Created by Александр Бородулин on 05.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "NetworkRequest.h"

@class WDDLocation;
@interface FacebookRequest : NetworkRequest

+ (NSDate*)convertFacebookDateToNSDate:(NSString*)created_at;

- (BOOL)setLikeOnObjectID:(NSString*)objectID withToken:(NSString*)token;
- (BOOL)isPostLikedMe:(NSString*)postID withToken:(NSString*)token andMyID:(NSString*)myID;
- (BOOL)setUnlikeOnObjectID:(NSString*)objectID withToken:(NSString*)token;

- (BOOL)sharePostWithToken:(NSString*)token andMessage:(NSString*)message withLink:(NSString*)link;

- (BOOL)addPostToWallWithToken:(NSString*)token
                    andMessage:(NSString*)message
                       andLink:(NSString*)link
                       andName:(NSString*)name
               withDescription:(NSString*)description
                   andImageURL:(NSString*)imageURL
                 toGroupWithID:(NSString *)groupID;

- (NSDictionary*)getPostWithDictionary:(NSDictionary*)dataDict andToken:(NSString*)token;
- (BOOL)getPostsWithToken:(NSString*)token
                andUserID:(NSString*)userID
                 andCount:(NSUInteger)count
                andGroups:(NSArray*)groups
               startsFrom:(NSDate *)date
      withComplationBlock:(void (^)(NSArray *resultArray))completionBlock;
- (NSArray *)searchPostsWithSearchText:(NSString *)searchText
                                 token:(NSString*)token
                                 limit:(NSUInteger)limit;
- (NSArray *)loadMorePostsWithToken:(NSString*)token from:(NSInteger)from count:(NSInteger)count;
- (NSArray *)loadMorePostsWithTokenFromGroup:(NSString*)groupID untilTime:(NSString*)untilTime count:(NSInteger)count andGroupType:(NSInteger)groupType andToken:(NSString*)token;
- (NSDictionary *)getTopStoryPostWithDictionary:(NSDictionary*)dataDict
                                       forGroupWithInfo:(NSDictionary *)groupInfo
                                       andToken:(NSString*)token;

- (void)getNotificationsWithToken:(NSString*)accessToken
                           userId:(NSString*)userId
                  completionBlock:(void (^)(NSDictionary *resultDictionary))completionBlock
                  completionQueue:(dispatch_queue_t)completionQueue;

- (void)markNotificationAsRead:(NSString*)notificationId
                    withUserId:(NSString*)userId
                     withToken:(NSString*)accessToken
                    completion:(void(^)(NSError *error))completionBlock;

- (BOOL)addStatusWithToken:(NSString*)token
                andMessage:(NSString*)message
                  location:(WDDLocation *)location
               andImageURL:(NSString*)imageURL;
- (BOOL)addStatusWithToken:(NSString *)token
                andMessage:(NSString *)message
                  location:(WDDLocation *)location
                  andImage:(UIImage *)image;
- (BOOL)addStatusWithToken:(NSString *)token
                andMessage:(NSString *)message
                  location:(WDDLocation *)location
                  andImage:(UIImage *)image
                   toGroup:(NSString *)groupId;

- (NSArray*)getCommentsOnPostID:(NSString*)postID withToken:(NSString*)token;
- (NSDictionary*)addCommentOnObjectID:(NSString*)objectID withUserID:(NSString*)userID withToken:(NSString*)token andMessage:(NSString*)message;
- (NSArray*)getCommentsOnPostID:(NSString*)postID offset:(NSUInteger)offset withToken:(NSString*)token;

- (NSDictionary*)fetchInboxWithToken:(NSString*)token;
+ (NSString *)profileURLWithID:(NSString *)profileID;

- (NSArray*)getFriendsWithToken:(NSString*)token;
- (void)getLocationsWithLocation:(WDDLocation*)location
                     accessToken:(NSString*)accessToken
                      completion:(void(^)(NSArray *locations))completion;

@end
