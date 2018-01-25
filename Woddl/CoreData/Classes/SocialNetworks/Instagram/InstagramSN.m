//
//  InstagramSN.m
//  Woddl
//
//  Created by Sergii Gordiienko on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.

#import "InstagramSN.h"
#import "InstagramPost.h"
#import "WDDDataBase.h"
#import "Comment.h"
#import "NetworkRequest.h"
#import "Media.h"
#import "WDDAppDelegate.h"
#import "InstagramProfile.h"
#import "InstagramOthersProfile.h"
#import "InstagramRequest.h"

@interface InstagramSN()
@end

@implementation InstagramSN

@synthesize postCompletionBlock;
@synthesize searchPostBlock = _searchPostBlock;

+(NSString *)baseURL
{
    return @"https://api.instagram.com";
}

- (NSString *)socialNetworkIconName
{
    return kInstagramIconImageName;
}

- (void)getPostsWithCompletionBlock:(ComplationGetPostBlock)completionBlock
{
    [self getPosts];
    completionBlock(nil);
}

-(void)getPosts
{
    InstagramRequest* request = [[InstagramRequest alloc] init];
    NSArray* posts = [request getPostsWithToken:self.accessToken andUserID:self.profile.userID andCount:kGetPostLimit];
    [self instagramGetPostDidFinishWithPosts:posts];
}

- (void)getPostsFrom:(NSString*)from to:(NSString*)to isSelfPosts:(BOOL)isSelf
{
    InstagramRequest* request = [[InstagramRequest alloc] init];
    NSArray* posts = [request loadMorePostsWithToken:self.accessToken andUserID:@"" andCount:[to intValue] maxID:from];
    [self instagramLoadMorePostDidFinishWithPosts:posts];
}

- (void)postToWallWithMessage:(NSString *)message
                         post:(Post *)post
                      toGroup:(Group *)group
          withCompletionBlock:(ComplationPostBlock)completionBlock
{
    
}

- (void)addStatusWithMessage:(NSString*)message andImages:(NSArray*)images andLocation:(WDDLocation*)location withCompletionBlock:(completionAddStatusBlock)completionBlock
{
    
}

-(void)getFriends
{
    InstagramRequest* instagramRequest = [[InstagramRequest alloc] init];
    NSArray* result = [instagramRequest getFriendsWithToken:self.accessToken];
    [self instagramRefreshFriendsDidFinishWithFriends:result];
}

- (void)updateProfileInfo
{
    InstagramRequest* instagramRequest = [[InstagramRequest alloc] init];
    NSDictionary *profileInfo = [instagramRequest profileInformationWithToken:self.accessToken userID:self.profile.userID];
    
    self.profile.name = profileInfo[@"username"];
    self.profile.avatarRemoteURL = profileInfo[@"profile_picture"];
}

#pragma mark - Delegate

-(void)instagramGetPostDidFinishWithPosts:(NSArray *)posts
{
    [self savePostsToDataBase:posts];
}

-(void)instagramLoadMorePostDidFinishWithPosts:(NSArray*)posts
{
    [self savePostsToDataBase:posts];
}

- (Class)postClass
{
    return [InstagramPost class];
}

#pragma mark - SearchPosts
static NSInteger kSearchPostLimit = 10;

- (void)searchPostsWithText:(NSString *)searchText
{
    InstagramRequest* request = [[InstagramRequest alloc] init];
    NSArray *posts = [request searchPostsWithSearchText:searchText
                                                  token:self.accessToken
                                                  limit:kSearchPostLimit];

    [self savePostsToDataBase:posts];
    
    if(self.searchPostBlock)
    {
        self.searchPostBlock(nil);
        self.searchPostBlock = nil;
    }
}

- (void)searchPostsWithText:(NSString *)searchText completionBlock:(completionSearchPostsBlock)comletionBlock
{
    self.searchPostBlock = comletionBlock;
    [self searchPostsWithText:searchText];
}

-(void)instagramRefreshFriendsDidFinishWithFriends:(NSArray*)friends
{
    for(NSDictionary* friend in friends)
    {
        InstagramProfile* instagramProfile = (InstagramProfile*)self.profile;
        NSArray* existingFriends = [instagramProfile.friends allObjects];
        BOOL isExistFriend = NO;
        for(InstagramOthersProfile* friendItem in existingFriends)
        {
            if([friendItem.userID isEqualToString:[friend objectForKey:kFriendID]])
            {
                isExistFriend = YES;
                break;
            }
        }
        if(!isExistFriend)
        {
            InstagramOthersProfile* friendProfile = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([InstagramOthersProfile class])];
            friendProfile.userID = [friend objectForKey:kFriendID];
            friendProfile.name = [friend objectForKey:kFriendName];
            friendProfile.profileURL = [friend objectForKey:kFriendLink];
            friendProfile.avatarRemoteURL = [friend objectForKey:kFriendPicture];
            [instagramProfile addFriendsObject:friendProfile];
        }
    }
    [[WDDDataBase sharedDatabase] save];
}

@end
