//
//  FoursquareSN.m
//  Woddl
//
//  Created by Sergii Gordiienko on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FoursquareSN.h"
#import "FoursquarePost.h"
#import "WDDDataBase.h"
#import "Comment.h"
#import "NetworkRequest.h"
#import "WDDAppDelegate.h"
#import "FoursquareAddStatusOperation.h"
#import "FoursqaureProfile.h"
#import "FoursquareOthersProfile.h"
#import "FoursquareRequest.h"

@interface FoursquareSN()<FoursquareAddStatusOperationDelegate>
@end

@implementation FoursquareSN

@synthesize addStatusCompletionBlock;
@synthesize postCompletionBlock;
@synthesize getPostsComplationBlock;

+ (NSString *)baseURL
{
    return @"https://foursquare.com";
}

- (NSString *)socialNetworkIconName
{
    return kFoursquareIconImageName;
}

- (void)getPostsWithCompletionBlock:(ComplationGetPostBlock)completionBlock
{
    [self getPosts];
    getPostsComplationBlock = completionBlock;
    
    if(getPostsComplationBlock)
    {
        getPostsComplationBlock(nil);
        getPostsComplationBlock = nil;
    }
}

-(void)getPosts
{
    FoursquareRequest* request = [[FoursquareRequest alloc] init];
    NSArray* posts = [request getPostsWithToken:self.accessToken andUserID:self.profile.userID andCount:10];
    /*
    if (self.isCancelled)
    {
        return ;
    }
     */
    [self foursquareGetPostDidFinishWithPosts:posts];
}

- (void)getPostsFrom:(NSString*)from to:(NSString*)to isSelfPosts:(BOOL)isSelf
{
    NSInteger countPosts = [from integerValue] + [to integerValue];
    
    FoursquareRequest* request = [[FoursquareRequest alloc] init];
    NSArray* posts = [request getPostsWithToken:self.accessToken andUserID:@"" andCount:countPosts];
    [self foursquareLoadMorePostDidFinishWithPosts: posts];
}

- (void)postToWallWithMessage:(NSString *)message
                         post:(Post *)post
                      toGroup:(Group *)group
          withCompletionBlock:(ComplationPostBlock)completionBlock_
{
    
}

- (void)addStatusWithMessage:(NSString*)message andImages:(NSArray*)images andLocation:(WDDLocation*)location withCompletionBlock:(completionAddStatusBlock)completionBlock
{
    self.addStatusCompletionBlock = completionBlock;
    NSOperationQueue* bgQueue = [FoursquarePost operationQueue];
    NSData* imageData = nil;
    if(images)
    {
        imageData = [images lastObject];
    }
    UIImage* image =[UIImage imageWithData:imageData];
    FoursquareAddStatusOperation* operation = [[FoursquareAddStatusOperation alloc] initFoursquareAddStatusOperationWithToken:self.accessToken andMessage:message andImage:image andLocation:location withDelegate:self];
    [bgQueue addOperation:operation];
}

- (void)getFriends
{
    FoursquareRequest* foursquareRequest = [[FoursquareRequest alloc] init];
    NSArray* result = [foursquareRequest getFriendsWithToken:self.accessToken];
    [self foursquareRefreshFriendsDidFinishWithFriends:result];
}

#pragma mark - Delegate

-(void)foursquareGetPostDidFinishWithPosts:(NSArray *)posts
{
    [self savePostsToDataBase:posts];
}

-(void)foursquareLoadMorePostDidFinishWithPosts:(NSArray*)posts
{
    [self savePostsToDataBase:posts];
}

-(void)foursquareAddStatusDidFinishWithSuccess
{
    addStatusCompletionBlock(nil);
    addStatusCompletionBlock = nil;
}

-(void)foursquareAddStatusDidFinishWithFail:(NSError*)error
{
    addStatusCompletionBlock(error);
    addStatusCompletionBlock = nil;
}

- (Class)postClass
{
    return [FoursquarePost class];
}

#pragma mark - SearchPosts
- (void)searchPostsWithText:(NSString *)searchText
{
    //  TODO: implement if supported
}

- (void)searchPostsWithText:(NSString *)searchText completionBlock:(completionSearchPostsBlock)comletionBlock
{
    //  TODO: implement if supported
    if (comletionBlock)
    {
        comletionBlock(nil);
    }
}

-(void)foursquareRefreshFriendsDidFinishWithFriends:(NSArray*)friends
{
    for(NSDictionary* friend in friends)
    {
        FoursqaureProfile* foursquareProfile = (FoursqaureProfile*)self.profile;
        NSArray* existingFriends = [foursquareProfile.friends allObjects];
        BOOL isExistFriend = NO;
        for(FoursquareOthersProfile* friendItem in existingFriends)
        {
            if([friendItem.userID isEqualToString:[friend objectForKey:kFriendID]])
            {
                isExistFriend = YES;
                break;
            }
        }
        if(!isExistFriend)
        {
            FoursquareOthersProfile* friendProfile = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([FoursquareOthersProfile class])];
            friendProfile.userID = [friend objectForKey:kFriendID];
            friendProfile.name = [friend objectForKey:kFriendName];
            friendProfile.profileURL = [friend objectForKey:kFriendLink];
            friendProfile.avatarRemoteURL = [friend objectForKey:kFriendPicture];
            [foursquareProfile addFriendsObject:friendProfile];
        }
    }
    [[WDDDataBase sharedDatabase] save];
}

@end
