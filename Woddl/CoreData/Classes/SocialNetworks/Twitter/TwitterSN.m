//
//  TwitterSN.m
//  Woddl
//
//  Created by Sergii Gordiienko on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "TwitterSN.h"
#import "TwitterPost.h"
#import "WDDDataBase.h"
#import "Tag.h"
#import "Comment.h"
#import "NetworkRequest.h"
#import "WDDAppDelegate.h"
#import "TwitterPostOperation.h"
#import "TwitterAddStatusOperation.h"
#import "TwitterOthersProfile.h"
#import "TwitterRequest.h"
#import "TwitterAPI.h"
#import "TwitterRetweetOperation.h"

#import "NSManagedObject+setValuesFromDataDictionary.h"

@interface TwitterSN()<TwitterPostOperationDelegate,TwitterAddStatusOperationDelegate>
@end

@implementation TwitterSN

@synthesize postCompletionBlock;
@synthesize addStatusCompletionBlock;
@synthesize getPostsComplationBlock;

@synthesize searchPostBlock = _searchPostBlock;

+ (NSString *)baseURL
{
    return @"https://api.twitter.com";
}

- (NSString *)socialNetworkIconName
{
    return kTwitterIconImageName;
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

- (void)getPosts
{
    WDDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.networkActivityIndicatorCounter++;
    
    NSFetchRequest *fRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([Post class])];
    fRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]];
    fRequest.predicate = [NSPredicate predicateWithFormat:@"subscribedBy == %@", self.profile];
    fRequest.fetchLimit = 1;
    NSArray *resutl = [self.managedObjectContext executeFetchRequest:fRequest error:nil];
    
    TwitterRequest* request = [[TwitterRequest alloc] init];
    NSMutableArray* posts = [[request getPostsWithToken:self.accessToken
                                              andUserID:self.profile.userID
                                               andCount:([resutl.firstObject postID] ? 200 : 50)
                                         upToPostWithID:[resutl.firstObject postID]] mutableCopy];
    
    DLog(@"Loaded %d twitter posts", posts.count);
    
    [self twitterGetPostDidFinishWithPosts:posts];
}

- (void)getPostsFrom:(NSString*)from to:(NSString*)to isSelfPosts:(BOOL)isSelf
{
    WDDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.networkActivityIndicatorCounter++;
    
    TwitterRequest* request = [[TwitterRequest alloc] init];
    NSArray* posts = [request getPostsWithToken:self.accessToken fromID:from to:to];
    /*
    if (self.isCancelled)
    {
        return ;
    }
     */
    [self twitterLoadMorePostDidFinishWithPosts:posts];
}

- (void)postToWallWithMessage:(NSString *)message
                         post:(Post *)post
                      toGroup:(Group *)group
          withCompletionBlock:(ComplationPostBlock)completionBlock_
{
    postCompletionBlock = completionBlock_;
    NSOperationQueue* bgQueue = [TwitterPost operationQueue];
    NSOperation *operation = nil;
    
    if (post.subscribedBy.socialNetwork.type.integerValue == kSocialNetworkTwitter)
    {
        operation = [[TwitterRetweetOperation alloc] initTwitterRetweetOperationWithToken:self.accessToken andPostID:post.postID withDelegate:self];
        
    }
    else
    {
        operation = [[TwitterPostOperation alloc] initTwitterPostOperationWithToken:self.accessToken andMessage:message andPost:post withDelegate:self];
    }
    [bgQueue addOperation:operation];
}

- (void)addStatusWithMessage:(NSString*)message andImages:(NSArray*)images andLocation:(WDDLocation*)location withCompletionBlock:(completionAddStatusBlock)completionBlock
{
    self.addStatusCompletionBlock = completionBlock;
    NSOperationQueue* bgQueue = [TwitterPost operationQueue];
    NSData* imageData = nil;
    if(images)
    {
        imageData = [images lastObject];
    }
    TwitterAddStatusOperation* operation = [[TwitterAddStatusOperation alloc] initTwitterAddStatusOperationWithToken:self.accessToken andMessage:message andImage:imageData andLocation:location withDelegate:self];
    [bgQueue addOperation:operation];
}

-(void)getFriends
{
    TwitterRequest *request = [[TwitterRequest alloc] init];
    NSArray *result = [request getFriendsWithToken:self.accessToken userID:self.profile.userID];
    
    for (NSDictionary *userInfo in result)
    {
        [self twitterProfileWithDescription:userInfo];
    }
    
    [[WDDDataBase sharedDatabase] save];
}

- (void)updateProfileInfo
{
    NSDictionary *profileInfo = [[TwitterRequest new] profileInformationWithToken:self.accessToken];
    
    if (profileInfo && [profileInfo isKindOfClass:[NSDictionary class]])
    {
        NSString *name = profileInfo[@"name"];
        if (!name.length)
        {
            name = profileInfo[@"screen_name"];
        }
        self.profile.name = name;
        self.profile.avatarRemoteURL = profileInfo[@"profile_image_url"];
        
        [[WDDDataBase sharedDatabase] save];
    }
}

#pragma mark - Delegate
- (void)savePostsToDataBase:(NSArray *)posts
{
    NSObject *syncObject = self.syncResources[self.type];
    
    @synchronized(syncObject)
    {
        for (NSDictionary *postDict in posts)
        {
            [self addPostToDataBase:postDict];
        }
      
        [self.managedObjectContext save:nil];
        
        DLog(@"Posts for %@ %@ saved", NSStringFromClass([self class]), self.profile.name);
    }
}

-(void)addPostToDataBase:(NSDictionary*)postDict
{
    NSArray *postsWithID = [[NSArray alloc] init];
    Post *post = nil;
    NSString *postID = [postDict objectForKey:kPostIDDictKey];
    
//    postsWithID = [[WDDDataBase sharedDatabase] getItemsWithEntityName:NSStringFromClass([TwitterPost class]) andPredicate:predicate];
    NSFetchRequest *request  = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([TwitterPost class])];
    request.predicate = [NSPredicate predicateWithFormat:@"postID like %@ AND self.subscribedBy.socialNetwork.type == %@", postID, self.type];
    
    postsWithID = [self.managedObjectContext executeFetchRequest:request error:nil];
    
    if (!postsWithID.count)
    {
//        post = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([TwitterPost class])];
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([TwitterPost class]) inManagedObjectContext:self.managedObjectContext];
        post = (Post *)[[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
    }
    else
    {
        post = [postsWithID lastObject];
    }
    post.updateTime = [NSDate date];
    [post setValuesFromDataDictionary:postDict];
    
    
    TwitterOthersProfile *authorProfile = [self twitterProfileWithDescription:postDict[kPostAuthorDictKey]];
    post.author = authorProfile;
    post.subscribedBy = self.profile;
    
    [self setCommentsFromPostInfo:postDict toPost:post];
    [self setMediaFromPostInfo:postDict toPost:post];
    [self setTagsFromPostInfo:postDict toPost:post];
    [self setPlacesFromPostInfo:postDict toPost:post];
    [self updateLinksForPost:post];
}

- (TwitterOthersProfile *)twitterProfileWithDescription:(NSDictionary *)descripton
{
    if (!descripton)
    {
        return nil;
    }
    
    TwitterProfile *twProfile = (TwitterProfile *)self.profile;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID == %@", [descripton objectForKey:kPostAuthorIDDictKey]];
    
    TwitterOthersProfile *authorProfile = [[twProfile.following allObjects] filteredArrayUsingPredicate:predicate].lastObject;
    if (!authorProfile)
    {
//        authorProfile = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([TwitterOthersProfile class])];
        
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([TwitterOthersProfile class]) inManagedObjectContext:self.managedObjectContext];
        authorProfile = (TwitterOthersProfile *)[[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
        [twProfile addFollowingObject:authorProfile];
    }
    
    authorProfile.name = [descripton objectForKey:kPostAuthorNameDictKey];
    authorProfile.avatarRemoteURL = [descripton objectForKey:kPostAuthorAvaURLDictKey];
    authorProfile.userID = [descripton objectForKey:kPostAuthorIDDictKey];
    authorProfile.profileURL = descripton[kPostAuthorProfileURLDictKey];
    
    return authorProfile;
}

- (void)twitterGetPostDidFinishWithPosts:(NSArray *)posts
{
    if(getPostsComplationBlock)
    {
        getPostsComplationBlock(nil);
        getPostsComplationBlock = nil;
    }
    
    [self savePostsToDataBase:posts];
    
    WDDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.networkActivityIndicatorCounter--;
}

-(void)twitterLoadMorePostDidFinishWithPosts:(NSArray *)posts
{
    [self savePostsToDataBase:posts];
    
    WDDAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    delegate.networkActivityIndicatorCounter--;
}

#pragma mark - tweet operation deleagte

- (void)twitterPostDidFinishWithSuccess
{
    postCompletionBlock(nil);
    postCompletionBlock = nil;
}

- (void)twitterPostDidFinishWithFail
{
    NSInteger code = 103;
    NSString *errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"unlike not completed", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError *error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    postCompletionBlock(error);
    postCompletionBlock = nil;
}

#pragma mark - retweet delegate

-(void)twitterRetweetDidFinishWithSuccess
{
    postCompletionBlock(nil);
    postCompletionBlock = nil;
}

-(void)twitterRetweetDidFinishWithFail
{
    NSArray *objArray = [NSArray arrayWithObjects:@"retwitt not comlited", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError* error = [NSError errorWithDomain:kErrorDomain code:kErrorCodeReTwittFailed userInfo:userInfo];
    postCompletionBlock(error);
    postCompletionBlock = nil;
}

#pragma mark - add status delegate

-(void)twitterAddStatusDidFinishWithSuccess:(NSDictionary *)result
{
    [self addPostToDataBase:result];
    [[WDDDataBase sharedDatabase] save];
    
    addStatusCompletionBlock(nil);
    addStatusCompletionBlock = nil;
}

-(void)twitterAddStatusDidFinishWithFail
{
    NSInteger code = 103;
    NSString *errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"unlike not completed", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError *error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    addStatusCompletionBlock(error);
    addStatusCompletionBlock = nil;
}

- (Class)postClass
{
    return [TwitterPost class];
}

#pragma mark - SearchPosts
static NSInteger kSearchPostLimit = 10;
- (void)searchPostsWithText:(NSString *)searchText
{
    TwitterRequest* request = [[TwitterRequest alloc] init];
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

- (void)fetchNotifications
{
    [[TwitterAPI Instance] fetchNotificationsForUserId:self.profile.userID  accessToken:self.accessToken];
}

- (void)markNotificationAsRead:(Notification *)notification
{
    notification.isUnread           = @NO;
    notification.isMarkingAsRead    = NO;
}

@end