//
//  InstagramRequest.h
//  Woddl
//
//  Created by Александр Бородулин on 07.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkRequest.h"

@interface InstagramRequest : NetworkRequest

-(NSArray*)getPostsWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count;
- (NSArray *)searchPostsWithSearchText:(NSString *)searchText
                            token:(NSString*)token
                            limit:(NSUInteger)limit;

-(BOOL)setUnlikeOnObjectID:(NSString*)objectID withToken:(NSString*)token;
-(BOOL)setLikeOnObjectID:(NSString*)objectID withToken:(NSString*)token;

-(BOOL)isPostLikedMe:(NSString*)postID withToken:(NSString*)token andMyID:(NSString*)myID;
-(NSDictionary*)addCommentOnObjectID:(NSString*)objectID withToken:(NSString*)token andMessage:(NSString*)message;
-(NSArray*)getCommentsWithPostID:(NSString*)postID andToken:(NSString*)token;
-(NSArray*)loadMorePostsWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count maxID:(NSString*)maxID;

-(NSArray*)getFriendsWithToken:(NSString*)token;
- (id)profileInformationWithToken:(NSString *)token userID:(NSString *)userID;

+ (NSString *)profileURLForID:(NSString *)profileID;
@end
