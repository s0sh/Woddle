//
//  NetworkRequest.m
//  Woddl
//
//  Created by Александр Бородулин on 05.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "NetworkRequest.h"

NSString * const kPostIDDictKey = @"postID";
NSString * const kPostTextDictKey = @"text";
NSString * const kPostDateDictKey = @"time";
NSString * const kPostLikesCountDictKey = @"likesCount";
NSString * const kPostCommentsCountDictKey = @"commentsCount";
NSString * const kPostLikesIsLikableDictKey = @"likable";
NSString * const kPostAuthorDictKey = @"author";
NSString * const kPostAuthorAvaURLDictKey = @"avatarRemoteURL";
NSString * const kPostAuthorNameDictKey = @"name";
NSString * const kPostAuthorScreenNameDictKey = @"screenName";
NSString * const kPostAuthorIDDictKey = @"userID";
NSString * const kPostAuthorProfileURLDictKey = @"profileURL";
NSString * const kPostCommentsDictKey = @"comments";
NSString * const kPostCommentDateDictKey = @"commentDate";
NSString * const kPostCommentTextDictKey = @"commentText";
NSString * const kPostCommentIDDictKey = @"commentID";
NSString * const kPostCommentLikesCountDictKey = @"commentLikes";
NSString * const kPostCommentAuthorDictKey = @"commentAuthor";
NSString * const kPostCommentAuthorAvaURLDictKey = @"commentAuthorAva";
NSString * const kPostCommentAuthorNameDictKey = @"commentAuthorName";
NSString * const kPostCommentAuthorIDDictKey = @"commentAuthorID";
NSString * const kPostMediaSetDictKey = @"media";
NSString * const kPostMediaURLDictKey = @"mediaURL";
NSString * const kPostMediaTypeDictKey = @"mediaType";
NSString * const kPostMediaPreviewDictKey = @"previewURLString";
NSString * const kPostLinkOnWebKey = @"linkURLString";
NSString * const kPostTagsListKey = @"tags";
NSString * const kPostPlacesListKey = @"places";
NSString * const kPostIsCommentableDictKey = @"postIsCommentable";
NSString * const kGroupTypeKey = @"groupeType";
NSString * const kGroupIDKey = @"groupeID";
NSString * const kGroupNameKey = @"groupeName";
NSString * const kGroupImageURLKey = @"groupeImageURL";
NSString * const kGroupURLKey = @"groupeURL";
NSString * const kGroupIsManagedByMeKey = @"isManagedByMe";
NSString * const kPostType = @"type";
NSString * const kPostIsSearched = @"isSearchedPost";
NSString * const kFriendID = @"friendID";
NSString * const kFriendLink = @"friendLink";
NSString * const kFriendName = @"friendName";
NSString * const kFriendPicture = @"friendPicture";
NSString * const kPostGroupID = @"postGroupID";
NSString * const kPostGroupName = @"postGroupName";
NSString * const kPostGroupType = @"postGroupType";
NSString * const kPostUpdateKey = @"updateKey";
NSString * const kPostRetweetsCountDictKey = @"retweetsCount";
NSString * const kPlaceIdDictKey = @"placeId";
NSString * const kPlaceNetworkTypeDictKey = @"networkType";
NSString * const kPlaceLatitudeDictKey = @"latitude";
NSString * const kPlaceLongitudeDictKey = @"longitude";
NSString * const kPlaceAddressDictKey = @"address";
NSString * const kPlaceCheckinsCountDictKey = @"checkinsCount";
NSString * const kPlaceVerifiedDictKey = @"verified";
NSString * const kPlaceCountryCodeDictKey = @"countryCode";
NSString * const kPlaceNameDictKey = @"name";
NSString * const kPostUpdateDateDictKey = @"updateTime";


@implementation NetworkRequest

-(NSArray*)getPostsWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count
{
    DLog(@"Need to define");
    return nil;
}

- (NSString *)textWithReplacedWrongSimbolsWithText:(NSString *)text
{
    NSString *resultText = text;
    
    resultText = [resultText stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
    resultText = [resultText stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
    resultText = [resultText stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
    
    return resultText;
}

- (BOOL)getUsersWhosLikedPostWithID:(NSString *)postId accessToken:(NSString *)accessToken
{
    NSAssert(![self isKindOfClass:[NetworkRequest class]], @"This is abstract class. Method should be overloaded by subclass");
    return NO;
}

- (BOOL)updateLikesAndFavoritesForPostWithID:(NSString *)postId accessToken:(NSString *)accessToken
{
    NSAssert(![self isKindOfClass:[NetworkRequest class]], @"This is abstract class. Method should be overloaded by subclass");
    return NO;
}

@end
