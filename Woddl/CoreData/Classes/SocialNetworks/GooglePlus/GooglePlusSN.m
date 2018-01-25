//
//  GooglePlusSN.m
//  Woddl
//
//  Created by Sergii Gordiienko on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "GooglePlusSN.h"
#import "NetworkRequest.h"
#import "Post.h"
#import "WDDDataBase.h"
#import "GooglePlusPost.h"
#import "Comment.h"
#import "WDDAppDelegate.h"
#import "GooglePlusProfile.h"
#import "GoogleOthersProfile.h"
#import "GoogleRequest.h"

@interface GooglePlusSN()
@end

@implementation GooglePlusSN

@synthesize postCompletionBlock;
@synthesize searchPostBlock = _searchPostBlock;

@dynamic updateToken;

- (NSString *)socialNetworkIconName
{
    return kGoogleIconImageName;
}

- (void)getPostsWithCompletionBlock:(ComplationGetPostBlock)completionBlock
{
    [self getPosts];
    completionBlock(nil);
}

-(void)getPosts
{
    GoogleRequest* request = [[GoogleRequest alloc] initWithToken:self.accessToken];
    NSArray* posts = [request getPostsWithCount:10 andUserID:self.profile.userID];
    [self googlePlusGetPostDidFinishWithPosts:posts];
}

- (void)getPostsFrom:(NSString*)from to:(NSString*)to isSelfPosts:(BOOL)isSelf
{
    GoogleRequest* request = [[GoogleRequest alloc] initWithToken:self.accessToken];
    NSArray* posts = [request getPostsWithCount:[to intValue] from:from];
    [self googlePlusLoadMorePostDidFinishWithPosts:posts];
}

- (void)postToWallWithMessage:(NSString *)message
                         post:(Post *)post
                      toGroup:(Group *)group
          withCompletionBlock:(ComplationPostBlock)completionBlock_
{
    
}

- (void)addStatusWithMessage:(NSString*)message andImages:(NSArray*)images andLocation:(WDDLocation*)location withCompletionBlock:(completionAddStatusBlock)completionBlock
{
    
}

- (void)getFriends
{    
    GoogleRequest* googleRequest = [[GoogleRequest alloc] initWithToken:self.accessToken];
    NSArray* result = [googleRequest getFriends];
    [self googlePlusRefreshFriendsDidFinishWithFriends:result];
}

- (void)getAllactivities:(NSMutableArray *)activities socialNetwork:(SocialNetwork *)network
{
    [self savePostsToDataBase:activities];
}

-(void)googlePlusGetPostDidFinishWithPosts:(NSArray *)posts
{
    [self savePostsToDataBase:posts];
    
    if(postCompletionBlock)
    {
        postCompletionBlock(nil);
        postCompletionBlock = nil;
    }
}

-(void)googlePlusLoadMorePostDidFinishWithPosts:(NSArray*)posts
{
    [self savePostsToDataBase:posts];
}

- (Class)postClass
{
    return [GooglePlusPost class];
}

#pragma mark - SearchPosts
static NSInteger kSearchPostLimit = 10;
- (void)searchPostsWithText:(NSString *)searchText
{
    GoogleRequest* request = [[GoogleRequest alloc] initWithToken:self.accessToken];
    
    NSArray *posts = [request searchPostsWithSearchText:searchText
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

#pragma mark - Delegate

-(void)googlePlusRefreshFriendsDidFinishWithFriends:(NSArray *)friends
{
    GooglePlusProfile *googleProfile = (GooglePlusProfile *)self.profile;
    NSMutableSet *existFriendIds = [[NSMutableSet alloc] initWithCapacity:googleProfile.friends.count];
    for (GooglePlusProfile *profile in googleProfile.friends)
    {
        [existFriendIds addObject:profile.userID];
    }
    
    NSArray *newFriends = [friends filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT friendID IN %@", existFriendIds]];
    for (NSDictionary *friendInfo in newFriends)
    {
        GoogleOthersProfile* friendProfile = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([GoogleOthersProfile class])];
        friendProfile.userID = [friendInfo objectForKey:kFriendID];
        friendProfile.name = [friendInfo objectForKey:kFriendName];
        friendProfile.profileURL = [friendInfo objectForKey:kFriendLink];
        friendProfile.avatarRemoteURL = [friendInfo objectForKey:kFriendPicture];
        [googleProfile addFriendsObject:friendProfile];
    }
    
//    for(NSDictionary* friend in friends)
//    {
//        GooglePlusProfile* googleProfile = (GooglePlusProfile*)self.profile;
//        NSArray* existingFriends = [googleProfile.friends allObjects];
//        BOOL isExistFriend = NO;
//        for(GoogleOthersProfile* friendItem in existingFriends)
//        {
//            if([friendItem.userID isEqualToString:[friend objectForKey:kFriendID]])
//            {
//                isExistFriend = YES;
//                break;
//            }
//        }
//        if(!isExistFriend)
//        {
//            GoogleOthersProfile* friendProfile = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([GoogleOthersProfile class])];
//            friendProfile.userID = [friend objectForKey:kFriendID];
//            friendProfile.name = [friend objectForKey:kFriendName];
//            friendProfile.profileURL = [friend objectForKey:kFriendLink];
//            friendProfile.avatarRemoteURL = [friend objectForKey:kFriendPicture];
//            [googleProfile addFriendsObject:friendProfile];
//        }
//    }
    [[WDDDataBase sharedDatabase] save];
}

@end
