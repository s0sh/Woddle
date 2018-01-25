//
//  LinkedinRequest.h
//  Woddl
//
//  Created by Александр Бородулин on 06.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkRequest.h"

@interface LinkedinRequest : NetworkRequest

-(NSArray*)getPostsWithToken:(NSString*)token andUserID:(NSString*)userID andGroups:(NSArray*)groups andCount:(NSUInteger)count;
-(BOOL)addStatusPostWithToken:(NSString*)token andMessage:(NSString*)message withLink:(NSString*)link andDescription:(NSString*)description andImageURL:(NSString*)imageURL;
-(BOOL)addStatusWithToken:(NSString*)token andMessage:(NSString*)message andImageURL:(NSString*)imageURL;
-(NSArray*)loadMorePostsWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count from:(NSUInteger)from isSelf:(BOOL)isSelf;
-(NSArray*)getGroupsPostsWithToken:(NSString*) token andGroupID:(NSString *) groupID from:(NSInteger)from count:(NSInteger) count;

-(BOOL)setLikeOnObjectID:(NSString*)objectID withToken:(NSString*)token;
-(BOOL)setLikeOnGroupObjectID:(NSString*)objectID withToken:(NSString*)token;
-(BOOL)setUnlikeOnObjectID:(NSString*)objectID withToken:(NSString*)token;
-(BOOL)setUnlikeOnGroupObjectID:(NSString*)objectID withToken:(NSString*)token;
-(NSDictionary*)isPostLikedMe:(NSString*)postID withToken:(NSString*)token andMyID:(NSString*)myID;
-(NSDictionary*)isGroupPostLikedMe:(NSString*)postID withToken:(NSString*)token andMyID:(NSString*)myID;

-(NSArray*) getCommentsFromPostID:(NSString*)postID andToken:(NSString*) token;
-(NSArray*) getMoreCommentsFromPostID:(NSString*)postID andToken:(NSString*) token;
-(NSDictionary*)addCommentToPost:(NSString*)postID withToken:(NSString*)token andMessage:(NSString*)message andUserID:(NSString*)userID;
-(NSDictionary*)addCommentToGroupPost:(NSString*)postID withToken:(NSString*)token andMessage:(NSString*)message andUserID:(NSString*)userID;
-(NSArray*)getCommentsFromGroupPostID:(NSString*)postID andToken:(NSString*)token;
-(NSArray*)getPostsWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count isSelf:(BOOL)isSelf;
-(NSArray*)loadMoreCommentsFromGroupPostID:(NSString*)postID from:(NSInteger)from count:(NSInteger)count andToken:(NSString*)token;

+ (NSString *)publicProfileURLWithID:(NSString *)profileID token:(NSString *)token;

-(NSArray*)getFriendsWithToken:(NSString*)token;

-(NSArray*)getGroupsWithToken:(NSString*)token;

- (void)getNotificationsWithToken:(NSString*)accessToken
                           userId:(NSString*)userId
                            after:(NSString*)after
                  completionBlock:(void(^)(NSDictionary *resultDictionary))completionBlock
                  completionQueue:(dispatch_queue_t)queue;

@end
