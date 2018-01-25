//
//  SocialNetworkUpdate.h
//  Woddl
//
//  Created by Александр Бородулин on 05.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ComplationSearchPostsBlock)(void);

extern NSString * const kLoadMorePostsFrom;
extern NSString * const kLoadMorePostsTo;
extern NSString * const kLoadMorePostsType;
extern NSString * const kLoadMorePostsUserID;
extern NSString * const kLoadMorePostsLastPostID;
extern NSString * const kLoadMorePostsSelfCount;
extern NSString * const kLoadMorePostsTheirCount;
extern NSString * const kLoadMorePostsGroups;
extern NSString * const kLoadMorePostsGroupCount;
extern NSString * const kLoadMorePostsGroupType;
extern NSString * const kLoadMorePostsGroupLastPostTimestamp;

@interface SocialNetworkManager : NSObject

@property (assign, nonatomic, getter = isApplicationReady) BOOL applicationReady;

@property (nonatomic,strong) ComplationSearchPostsBlock searchCompletionBlock;

- (BOOL)updatePosts;
- (BOOL)updatePostsWithComplationBlock:(void (^)(void))complationBlock;
- (BOOL)updateSocialNetworkPostsWithUserID:(NSString*)userID andComplationBlock:(void (^)(void))complationBlock;
- (BOOL)updateFacebookAndTwitterSocialNetworkWithComplationBlock:(void (^)(void))complationBlock;

- (BOOL)loadMorePostsFromInfoData:(NSDictionary*)infoData withComplitionBlock:(void (^)(void))complationBlock;

- (void)searchPostWithText:(NSString *)searchText;
- (void)searchPostWithText:(NSString *)searchText completionBlock:(void (^)(void))completionBlock;

- (void)cancelAllPostUpdates;

- (void)cancelSearchPosts;

+ (SocialNetworkManager*)sharedManager;

@end
