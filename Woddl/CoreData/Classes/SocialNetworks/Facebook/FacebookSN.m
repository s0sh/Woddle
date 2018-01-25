//
//  FacebookSN.m
//  Woddl
//
//  Created by Sergii Gordiienko on 02.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookSN.h"
#import "FaceBookPost.h"
#import "WDDDataBase.h"
#import "Comment.h"
#import "NetworkRequest.h"
#import "WDDAppDelegate.h"
#import "FacebookPostOperation.h"
#import "Tag.h"
#import "FacebookAddStatusOperation.h"
#import "Group.h"
#import "UserProfile.h"
#import "FaceBookProfile.h"
#import "FaceBookOthersProfile.h"
#import "FacebookRequest.h"
#import "FacebookGroupsInfo.h"

static NSInteger kSearchPostLimit = 10;

@interface FacebookSN()<FacebookPostOperationDelegate,
                        FacebookAddStatusOperationDelegate>
@end

@implementation FacebookSN
@synthesize searchPostBlock = _searchPostBlock;
@synthesize postCompletionBlock;
@synthesize addStatusCompletionBlock;
@synthesize getPostCompletionBlock;
@dynamic isChatEnabled;

+(NSString *)baseURL
{
    return @"https://graph.facebook.com";
}

- (NSString *)socialNetworkIconName
{
    return kFacebookIconImageName;
}

#pragma mark - Update methods

- (void)getPostsWithCompletionBlock:(ComplationGetPostBlock)completionBlock
{
    [self getPosts];
    completionBlock(nil);
}

-(void)getPosts
{
    NSMutableArray* groupsResultArray = [[NSMutableArray alloc] initWithCapacity:self.groups.count];
    for (Group *group in self.groups)
    {
        NSMutableDictionary *groupInfo = [@{@"groupId": group.groupID, @"name" : group.name, @"type" : group.type} mutableCopy];
        [groupsResultArray addObject:groupInfo];
    }
    
    FacebookRequest* request = [[FacebookRequest alloc] init];
    
    NSFetchRequest *fRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([Post class])];
    fRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO]];
    fRequest.predicate = [NSPredicate predicateWithFormat:@"subscribedBy == %@", self.profile];
    fRequest.fetchLimit = 1;
    NSArray *resutl = [self.managedObjectContext executeFetchRequest:fRequest error:nil];
    
    [request getPostsWithToken:self.accessToken
                         andUserID:self.profile.userID
                          andCount:kGetPostLimit
                         andGroups:groupsResultArray
                        startsFrom:[resutl.firstObject time]
               withComplationBlock:^(NSArray *resultArray)
    {
        [self facebookGetPostDidFinishWithPosts:resultArray];
    }];
}

- (void)getPostsFrom:(NSString *)from to:(NSString *)to isSelfPosts:(BOOL)isSelf
{
    FacebookRequest* request = [[FacebookRequest alloc] init];
    NSArray* posts = [request loadMorePostsWithToken:self.accessToken from:[from integerValue] count:[to integerValue]];
    /*
    if (self.isCancelled)
    {
        return ;
    }
     */
    [self facebookLoadMorePostDidFinishWithPosts:posts];
}

- (void)fetchNotifications
{
    dispatch_queue_t queue = [[self class] networkQueue];
    
    NSManagedObjectID *objectId = [self objectID];
    NSString *accessToken       = self.accessToken;
    NSString *userId            = self.profile.userID;
    
    dispatch_async(queue, ^()
    {
        FacebookRequest* request = [[FacebookRequest alloc] init];
        
        [request getNotificationsWithToken:accessToken
                                    userId:userId
                           completionBlock:^(NSDictionary *resultDictionary)
         {
             NSError *error;
             FacebookSN *bgSelf = (FacebookSN*)[[WDDDataBase sharedDatabase].managedObjectContext existingObjectWithID:objectId error:&error];
             if (bgSelf && !error)
             {
                 [bgSelf facebookRefreshGroupsDidFinishWithGroups:resultDictionary[@"groups"]];
                 [bgSelf facebookGetPostDidFinishWithPosts:resultDictionary[@"posts"]];
                 [bgSelf saveMedia:resultDictionary[@"photos"]];
                 [bgSelf saveUsers:resultDictionary[@"users"]];
                 [bgSelf saveNotificationsToDataBase:resultDictionary[@"notifications"]];
             }
         }
                           completionQueue:queue
         ];
    });
}

- (void)markNotificationAsRead:(Notification *)notification
{
    dispatch_queue_t queue      = [[self class] networkQueue];
    
    NSManagedObjectID *objectId = [notification objectID];
    
    NSString *notificationId    = notification.notificationId;
    NSString *accessToken       = self.accessToken;
    NSString *userId            = self.profile.userID;
    
    dispatch_async(queue, ^()
    {
        FacebookRequest* request = [[FacebookRequest alloc] init];
        [request markNotificationAsRead:notificationId
                             withUserId:userId
                              withToken:accessToken
                             completion:^(NSError *error)
         {
             NSError *fetchError;
             Notification *refetchedNotification = (Notification*)[[[WDDDataBase sharedDatabase] managedObjectContext] existingObjectWithID:objectId
                                                                                                                                      error:&fetchError];
             if (refetchedNotification && !fetchError)
             {
                 if (!error)
                 {
                     refetchedNotification.isUnread = @NO;
                 }
                 else
                 {
                     if (APP_DELEGATE.isInternetConnected)
                     {
                         [self markNotificationAsRead:notification];
                     }
                     else
                     {
                         refetchedNotification.isMarkingAsRead = NO;
                     }
                 }
             }
         }];
    });
}

- (void)loadMoreGroupsPostsWithGroupID:(NSString *)groupID andGroupType:(NSInteger)type from:(NSString *)from to:(NSString *)to
{
    FacebookRequest* request = [[FacebookRequest alloc] init];
    NSArray* posts = [request loadMorePostsWithTokenFromGroup:groupID untilTime:from count:[to integerValue] andGroupType:type andToken:self.accessToken];
    
    /*
    if (self.isCancelled)
    {
        return ;
    }
    */
    [self facebookLoadMoreGroupsPostDidFinishWithPosts:posts];
}

- (void)updateProfileInfo
{
    NSString *request = [NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT name,pic_square,profile_url FROM user WHERE uid == me()&access_token=%@", self.accessToken];
    request = [request stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *requestURL = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:request]
                                                              cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                          timeoutInterval:60.0];
    NSData *responseData = [NSURLConnection sendSynchronousRequest:requestURL returningResponse:nil error:nil];
    if (responseData)
    {
        NSError *error = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:responseData
                                                             options:kNilOptions
                                                               error:&error];
        
        if (!error && json[@"data"])
        {
            NSDictionary *userInfo = [json[@"data"] firstObject];

            self.displayName = userInfo[@"name"];
            self.profile.avatarRemoteURL = userInfo[@"pic_square"];
            self.profile.profileURL = userInfo[@"profile_url"];
            
            [self updateSocialNetworkOnParse];
        }
    }
}

#pragma mark - Search posts

- (void)searchPostsWithText:(NSString *)searchText
{
    FacebookRequest* request = [[FacebookRequest alloc] init];
    NSArray *posts = [request searchPostsWithSearchText:searchText
                                                  token:self.accessToken
                                                  limit:kSearchPostLimit];
    [self savePostsToDataBase:posts];
    
    //WDDAppDelegate* delegate = [[UIApplication sharedApplication] delegate];
    //delegate.networkActivityIndicatorCounter--;
    
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

#pragma mark - Post to wall

- (void)postToWallWithMessage:(NSString *)message
                         post:(Post *)post
                      toGroup:(Group *)group
          withCompletionBlock:(ComplationPostBlock)completionBlock_
{
    postCompletionBlock = completionBlock_;
    NSOperationQueue* bgQueue = [FaceBookPost operationQueue];
    FacebookPostOperation* operation = [[FacebookPostOperation alloc] initFacebookPostOperationWithToken:self.accessToken andMessage:message andPost:post toGroup:group withDelegate:self];
    [bgQueue addOperation:operation];
}

- (void)addStatusWithMessage:(NSString*)message
                   andImages:(NSArray*)images
                 andLocation:(WDDLocation*)location
         withCompletionBlock:(completionAddStatusBlock)completionBlock
{
    self.addStatusCompletionBlock = completionBlock;
    NSOperationQueue* bgQueue = [FaceBookPost operationQueue];
    NSData* imageData = nil;
    if(images)
    {
        imageData = [images lastObject];
    }
    FacebookAddStatusOperation* operation = [[FacebookAddStatusOperation alloc] initFacebookAddStatusOperationWithToken:self.accessToken andMessage:message andImage:imageData andLocation:location withDelegate:self];
    [bgQueue addOperation:operation];
}

- (void)addStatusWithMessage:(NSString *)message andImages:(NSArray *)images andLocation:(WDDLocation *)location toGroup:(Group *)group withCompletionBlock:(completionAddStatusBlock)completionBlock;
{
    NSString *accessToken = self.accessToken;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        UIImage * image = nil;
        
        if ([images.firstObject isKindOfClass:[NSData class]])
        {
            image = [UIImage imageWithData:images.firstObject];
        }
        else if ([images.firstObject isKindOfClass:[UIImage class]])
        {
            image = images.firstObject;
        }
        
        NSError *error = nil;
        FacebookRequest *request = [FacebookRequest new];
        if (![request addStatusWithToken:accessToken
                              andMessage:message
                                 location:location
                                andImage:image
                                 toGroup:group.groupID])
        {
            error = [NSError errorWithDomain:@"WDDFacebookDomain"
                                        code:1024
                                    userInfo:@{ NSLocalizedDescriptionKey : @"Can't add post to group" }];
        }
        
        if (completionBlock)
        {
            completionBlock(error);
        }
    });
    
}

- (void)refreshGroups
{
    FacebookGroupsInfo* groupsInfo = [[FacebookGroupsInfo alloc] init];
    NSArray* groups = [groupsInfo getAllGroupsWithUserID:self.profile.userID andToken:self.accessToken];
    
//#if FB_GROUPS_SUPPORT == ON
//    groups = [groupsInfo getAllGroupsWithUserID:self.profile.userID andToken:self.accessToken];
//#else
//    groups = [groupsInfo getOwnAndAdmistrativeGroupsForUserID:self.profile.userID token:self.accessToken];
//#endif
    
    [self facebookRefreshGroupsDidFinishWithGroups:groups];
}

- (void)getFriends
{
    FacebookRequest* fbRequest = [[FacebookRequest alloc] init];
    NSArray* result = [fbRequest getFriendsWithToken:self.accessToken];
    
    [self facebookRefreshFriendsDidFinishWithFriends:result];
}

#pragma mark - Delegate

-(void)facebookGetPostDidFinishWithPosts:(NSArray *)posts
{
    [self savePostsToDataBase:posts];
}

-(void)facebookLoadMorePostDidFinishWithPosts:(NSArray*)posts
{
    [self savePostsToDataBase:posts];
}

-(void)facebookLoadMoreGroupsPostDidFinishWithPosts:(NSArray*)posts
{
    [self savePostsToDataBase:posts];
}


-(void)facebookPostDidFinishWithSuccess
{
    postCompletionBlock(nil);
    postCompletionBlock = nil;
}

-(void)facebookPostDidFinishWithFail
{
    NSInteger code = 103;
    NSString* errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"unlike not completed", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    postCompletionBlock(error);
    postCompletionBlock = nil;
}

-(void)facebookAddStatusDidFinishWithSuccess
{
    addStatusCompletionBlock(nil);
    addStatusCompletionBlock = nil;
}

-(void)facebookAddStatusDidFinishWithFail
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

-(void)facebookRefreshGroupsDidFinishWithGroups:(NSArray *)groups
{
    for(NSDictionary* group in groups)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"groupID like %@", [group objectForKey:kGroupIDKey]];
        Group *groupObj = [[WDDDataBase sharedDatabase] getItemsWithEntityName:NSStringFromClass([Group class]) andPredicate:predicate].firstObject;
        if(!groupObj)
        {
            groupObj = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([Group class])];
            groupObj.type = [group objectForKey:kGroupTypeKey];
            groupObj.groupID = [group objectForKey:kGroupIDKey];
        }
        
        groupObj.name = [group objectForKey:kGroupNameKey];
        groupObj.imageURL = [group objectForKey:kGroupImageURLKey];
        groupObj.groupURL = [group objectForKey:kGroupURLKey];
        
        if ([[group objectForKey:kGroupIsManagedByMeKey] boolValue])
        {
            [groupObj addManagedByObject:self.profile];
        }
        
        SocialNetwork* socNetwork = self;
        
        [socNetwork addGroupsObject:groupObj];
    
    }
    [[WDDDataBase sharedDatabase] save];
}

- (Class)postClass
{
    return [FaceBookPost class];
}

-(void)facebookRefreshFriendsDidFinishWithFriends:(NSArray *)friends
{
    NSMutableSet *friendsToAdd = [[NSMutableSet alloc] initWithCapacity:friends.count];
    NSMutableSet *friendsToRemove = [[NSMutableSet alloc] initWithCapacity:friends.count];
    
    friendsToRemove = [[(FaceBookProfile *)self.profile friends] mutableCopy];
    
    for (NSDictionary *friendInfo in friends)
    {
        __block FaceBookProfile *friendProfile = nil;
        
        [friendsToRemove enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            
            if ([[(FaceBookProfile *)obj userID] isEqualToString:friendInfo[kFriendID]])
            {
                friendProfile = obj;
                *stop = YES;
            }
        }];
        
        if (friendProfile)
        {
            [friendsToRemove removeObject:friendProfile];
        }
        else
        {
            friendProfile = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([FaceBookOthersProfile class])];
            friendProfile.userID = [friendInfo objectForKey:kFriendID];
            friendProfile.name = [friendInfo objectForKey:kFriendName];
            friendProfile.profileURL = [friendInfo objectForKey:kFriendLink];
            friendProfile.avatarRemoteURL = [friendInfo objectForKey:kFriendPicture];
            [friendsToAdd addObject:friendProfile];
        }
    }
    [(FaceBookProfile *)self.profile removeFriends:friendsToRemove];
    [(FaceBookProfile *)self.profile addFriends:friendsToAdd];
    
    [[WDDDataBase sharedDatabase] save];
}

#pragma mark - helper

- (void)saveMedia:(NSArray*)media
{
    if (!media.count) return;
    
    NSObject *syncObject = self.syncResources[self.type];
    
    @synchronized(syncObject)
    {
        NSManagedObjectContext * context = [WDDDataBase sharedDatabase].managedObjectContext;
     
        [media enumerateObjectsUsingBlock:^(NSDictionary *mediaDict, NSUInteger idx, BOOL *stop)
        {
            NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Media class])];
            fetchRequest.predicate          = [NSPredicate predicateWithFormat:@"mediaObjectId == %@", mediaDict[@"mediaObjectId"]];
            fetchRequest.fetchLimit         = 1;
            Media *media                    = [[context executeFetchRequest:fetchRequest error:nil] firstObject];
            if (!media)
            {
                media = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Media class])
                                                      inManagedObjectContext:context];
            }
            [media setValuesForKeysWithDictionary:mediaDict];
        }];
    }
}

- (void)saveUsers:(NSArray*)users
{
    if (!users.count) return;
    
    NSObject *syncObject = self.syncResources[self.type];
    
    @synchronized(syncObject)
    {
        NSManagedObjectContext * context = [WDDDataBase sharedDatabase].managedObjectContext;
        
        [users enumerateObjectsUsingBlock:^(NSDictionary *userDict, NSUInteger idx, BOOL *stop)
         {
             NSFetchRequest *fetchRequest       = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([FaceBookOthersProfile class])];
             fetchRequest.predicate             = [NSPredicate predicateWithFormat:@"userID == %@", userDict[@"userID"]];
             fetchRequest.fetchLimit            = 1;
             FaceBookOthersProfile *profile     = [[context executeFetchRequest:fetchRequest error:nil] firstObject];
             if (!profile)
             {
                 profile = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([FaceBookOthersProfile class])
                                                         inManagedObjectContext:context];
             }
             [profile setValuesForKeysWithDictionary:userDict];       
         }];
    }
}

@end
