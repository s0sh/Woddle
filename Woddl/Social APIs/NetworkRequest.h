//
//  NetworkRequest.h
//  Woddl
//
//  Created by Александр Бородулин on 05.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kPostIDDictKey;
extern NSString * const kPostTextDictKey;
extern NSString * const kPostDateDictKey;
extern NSString * const kPostIsCommentableDictKey;
extern NSString * const kPostLikesCountDictKey;
extern NSString * const kPostCommentsCountDictKey;
extern NSString * const kPostLikesIsLikableDictKey;
extern NSString * const kPostAuthorDictKey;
extern NSString * const kPostAuthorAvaURLDictKey;
extern NSString * const kPostAuthorNameDictKey;
extern NSString * const kPostAuthorScreenNameDictKey;
extern NSString * const kPostAuthorIDDictKey;
extern NSString * const kPostAuthorProfileURLDictKey;
extern NSString * const kPostCommentsDictKey;
extern NSString * const kPostCommentDateDictKey;
extern NSString * const kPostCommentTextDictKey;
extern NSString * const kPostCommentIDDictKey;
extern NSString * const kPostCommentLikesCountDictKey;
extern NSString * const kPostCommentAuthorDictKey;
extern NSString * const kPostCommentAuthorAvaURLDictKey;
extern NSString * const kPostCommentAuthorNameDictKey;
extern NSString * const kPostCommentAuthorIDDictKey;
extern NSString * const kPostMediaSetDictKey;
extern NSString * const kPostMediaURLDictKey;
extern NSString * const kPostMediaTypeDictKey;
extern NSString * const kPostMediaPreviewDictKey;
extern NSString * const kPostLinkOnWebKey;
extern NSString * const kPostTagsListKey;
extern NSString * const kPostPlacesListKey;
extern NSString * const kPostGroupID;
extern NSString * const kPostGroupName;
extern NSString * const kPostUpdateKey;
extern NSString * const kPostRetweetsCountDictKey;
extern NSString * const kPostType;
extern NSString * const kPostIsSearched;
extern NSString * const kGroupTypeKey;
extern NSString * const kGroupIDKey;
extern NSString * const kGroupNameKey;
extern NSString * const kPostGroupType;
extern NSString * const kGroupImageURLKey;
extern NSString * const kGroupURLKey;
extern NSString * const kGroupIsManagedByMeKey;
extern NSString * const kFriendID;
extern NSString * const kFriendLink;
extern NSString * const kFriendName;
extern NSString * const kFriendPicture;
extern NSString * const kPlaceIdDictKey;
extern NSString * const kPlaceLatitudeDictKey;
extern NSString * const kPlaceLongitudeDictKey;
extern NSString * const kPlaceAddressDictKey;
extern NSString * const kPlaceCheckinsCountDictKey;
extern NSString * const kPlaceVerifiedDictKey;
extern NSString * const kPlaceCountryCodeDictKey;
extern NSString * const kPlaceNameDictKey;
extern NSString * const kPostUpdateDateDictKey;

@interface NetworkRequest : NSObject

- (NSArray *)getPostsWithToken:(NSString *)token andUserID:(NSString *)userID andCount:(NSUInteger)count;
- (NSString *)textWithReplacedWrongSimbolsWithText:(NSString *)text;

- (BOOL)getUsersWhosLikedPostWithID:(NSString *)postId accessToken:(NSString *)accessToken;
- (BOOL)updateLikesAndFavoritesForPostWithID:(NSString *)postId accessToken:(NSString *)accessToken;

@end
