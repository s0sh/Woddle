//
//  LinkedinSN.m
//  Woddl
//
//  Created by Sergii Gordiienko on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinSN.h"
#import "LinkedinPost.h"
#import "WDDDataBase.h"
#import "Comment.h"
#import "NetworkRequest.h"
#import "WDDAppDelegate.h"
#import "LinkedinPostOperation.h"
#import "LinkedinAddStatusOperation.h"
#import "LinkedinProfile.h"
#import "UserProfile.h"
#import "LinkedinOthersProfile.h"
#import "LinkedinRequest.h"

#import "DDXML.h"

@interface LinkedinSN()<LinkedinPostOperationDelegate,LinkedinAddStatusOperationDelegate>
@end

@implementation LinkedinSN

@synthesize postCompletionBlock;
@synthesize addStatusCompletionBlock;
@synthesize refreshGroupsCompletionBlock;
@synthesize getPostCompletionBlock;

static BOOL isGroupsRefreshed = NO;

+ (NSString *)baseURL
{
    return @"https://www.linkedin.com";
}

- (NSString *)socialNetworkIconName
{
    return kLinkedInIconImageName;
}

- (void)getPostsWithCompletionBlock:(ComplationGetPostBlock)completionBlock
{
    [self getPosts];
    
    getPostCompletionBlock = completionBlock;
    
    getPostCompletionBlock(nil);
    getPostCompletionBlock = nil;
}

- (void)getPostsFrom:(NSString*)from to:(NSString*)to isSelfPosts:(BOOL)isSelf
{
    LinkedinRequest* request = [[LinkedinRequest alloc] init];
    NSArray* posts = [request loadMorePostsWithToken:self.accessToken andUserID:self.profile.userID andCount:[to integerValue] from:[from integerValue] isSelf:isSelf];
    [self linkedinLoadMorePostDidFinishWithPosts:posts];
}

-(void)getPosts
{
    //[self refreshGroupsWithComplationBlock:^{
        
        isGroupsRefreshed = YES;
        
        NSSet* groups = self.groups;
        
        NSMutableArray* groupsResultArray = [[NSMutableArray alloc] init];
        for(NSManagedObject* groupObject in [groups allObjects])
        {
            NSArray *keys = [[[groupObject entity] attributesByName] allKeys];
            NSDictionary *dict = [groupObject dictionaryWithValuesForKeys:keys];
            [groupsResultArray addObject:dict];
        }
    
    LinkedinRequest* request = [[LinkedinRequest alloc] init];
    NSArray* posts = [request getPostsWithToken:self.accessToken andUserID:self.profile.userID andGroups:groupsResultArray andCount:kGetPostLimit];
    /*
    if (self.isCancelled)
    {
        return ;
    }
     */
    [self linkedinGetPostDidFinishWithPosts:posts];
        
    //}];
}

- (void)loadMoreGroupsPostsWithGroupID:(NSString *)groupID from:(NSString *)from to:(NSString *)to
{
    LinkedinRequest* request = [[LinkedinRequest alloc] init];
    NSArray* posts = [request getGroupsPostsWithToken:self.accessToken andGroupID:groupID from:[from intValue] count:[to intValue]];
    [self linkedinLoadMoreGroupsPostDidFinishWithPosts:posts];
}

- (void)postToWallWithMessage:(NSString *)message
                         post:(Post *)post
                      toGroup:(Group *)group
          withCompletionBlock:(ComplationPostBlock)completionBlock_
{
    postCompletionBlock = completionBlock_;
    NSOperationQueue* bgQueue = [LinkedinPost operationQueue];
    LinkedinPostOperation* operation = [[LinkedinPostOperation alloc] initLinkedinPostOperationWithToken:self.accessToken andMessage:message andPost:post withDelegate:self];
    [bgQueue addOperation:operation];
}

- (void)addStatusWithMessage:(NSString*)message andImages:(NSArray*)images andLocation:(WDDLocation*)location withCompletionBlock:(completionAddStatusBlock)completionBlock
{
    self.addStatusCompletionBlock = completionBlock;
    NSOperationQueue* bgQueue = [LinkedinPost operationQueue];
    NSData* imageData = nil;
    if(images)
    {
        imageData = [images lastObject];
    }
    LinkedinAddStatusOperation* operation = [[LinkedinAddStatusOperation alloc] initLinkedinAddStatusOperationWithToken:self.accessToken andMessage:message andImage:imageData andLocation:location withDelegate:self];
    [bgQueue addOperation:operation];
}

- (void)getFriends
{
    LinkedinRequest* linkedinRequest = [[LinkedinRequest alloc] init];
    NSArray* result = [linkedinRequest getFriendsWithToken:self.accessToken];
    [self linkedinRefreshFriendsDidFinishWithFriends:result];
}

- (void)refreshGroups
{
#if LINKEDIN_GROUPS_SUPPORT == ON
    LinkedinRequest* groupsInfo = [[LinkedinRequest alloc] init];
    NSArray* groups = [groupsInfo getGroupsWithToken:self.accessToken];
    [self linkedinRefreshGroupsDidFinishWithGroups:groups];
#endif
}

- (void)refreshGroupsWithComplationBlock:(completionRefreshGroupsBlock)complationBlock
{
    if(!isGroupsRefreshed&&false)
    {
        self.refreshGroupsCompletionBlock = complationBlock;
        [self refreshGroups];
    }
    else
    {
        if (self.refreshGroupsCompletionBlock)
        {
            self.refreshGroupsCompletionBlock();
        }
        if (complationBlock)
        {
            complationBlock();
        }
        self.refreshGroupsCompletionBlock = nil;
    }
}

#pragma mark - Delegate

-(void)linkedinGetPostDidFinishWithPosts:(NSArray *)posts
{
    [self savePostsToDataBase:posts];
}

-(void)linkedinLoadMorePostDidFinishWithPosts:(NSArray*)posts
{
    [self savePostsToDataBase:posts];
}

-(void)linkedinPostDidFinishWithSuccess
{
    postCompletionBlock(nil);
    postCompletionBlock = nil;
}

-(void)linkedinPostDidFinishWithFail
{
    NSInteger code = 104;
    NSString* errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"unlike not completed", @"probably no connection", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    postCompletionBlock(error);
    postCompletionBlock = nil;
}

-(void)linkedinAddStatusDidFinishWithSuccess
{
    addStatusCompletionBlock(nil);
    addStatusCompletionBlock = nil;
}

-(void)linkedinAddStatusDidFinishWithFail
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
    return [LinkedinPost class];
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

-(void)linkedinRefreshFriendsDidFinishWithFriends:(NSArray*)friends
{
    for(NSDictionary* friend in friends)
    {
        LinkedinProfile* linkedinProfile = (LinkedinProfile*)self.profile;
        NSArray* existingFriends = [linkedinProfile.friends allObjects];
        BOOL isExistFriend = NO;
        for(LinkedinOthersProfile* friendItem in existingFriends)
        {
            if([friendItem.userID isEqualToString:[friend objectForKey:kFriendID]])
            {
                isExistFriend = YES;
                break;
            }
        }
        if(!isExistFriend)
        {
            LinkedinOthersProfile* friendProfile = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([LinkedinOthersProfile class])];
            friendProfile.userID = [friend objectForKey:kFriendID];
            friendProfile.name = [friend objectForKey:kFriendName];
            friendProfile.profileURL = [friend objectForKey:kFriendLink];
            friendProfile.avatarRemoteURL = [friend objectForKey:kFriendPicture];
            [linkedinProfile addFriendsObject:friendProfile];
        }
    }
    [[WDDDataBase sharedDatabase] save];
}

-(void)linkedinRefreshGroupsDidFinishWithGroups:(NSArray *)groups
{
    for(NSDictionary* group in groups)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"groupID like %@", [group objectForKey:kGroupIDKey]];
        NSArray *mediaEntityArray = [[WDDDataBase sharedDatabase] getItemsWithEntityName:NSStringFromClass([Group class]) andPredicate:predicate];
        if(mediaEntityArray.count==0)
        {
            Group* groupEntity = nil;
            groupEntity = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([Group class])];
            groupEntity.type = [group objectForKey:kGroupTypeKey];
            groupEntity.groupID = [group objectForKey:kGroupIDKey];
            groupEntity.name = [group objectForKey:kGroupNameKey];
            groupEntity.imageURL = [group objectForKey:kGroupImageURLKey];
            groupEntity.groupURL = [group objectForKey:kGroupURLKey];
            
            SocialNetwork* socNetwork = self;
            
            [socNetwork addGroupsObject:groupEntity];
        }
    }
    [[WDDDataBase sharedDatabase] save];
    if(self.refreshGroupsCompletionBlock)
    {
        self.refreshGroupsCompletionBlock();
        self.refreshGroupsCompletionBlock = nil;
    }
}

-(void)linkedinLoadMoreGroupsPostDidFinishWithPosts:(NSArray*)posts
{
    [self savePostsToDataBase:posts];
}

- (void)fetchNotifications
{
    dispatch_queue_t queue = [[self class] networkQueue];
    
    NSManagedObjectID *objectId = [self objectID];
    NSString *accessToken       = self.accessToken;
    NSString *userId            = self.profile.userID;
    
    NSFetchRequest *fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Notification class])];
    
    fetchRequest.predicate          = [NSPredicate predicateWithFormat:@"socialNetwork.profile.userID == %@", userId];
    fetchRequest.sortDescriptors    = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
    fetchRequest.fetchLimit         = 1;
    
    Notification *lastLinkedInNotification = [[self.managedObjectContext executeFetchRequest:fetchRequest error:nil] firstObject];
    
    NSString *afterDate;
    
    if (lastLinkedInNotification)
    {
        afterDate = [NSString stringWithFormat:@"%llu", (unsigned long long)([lastLinkedInNotification.date timeIntervalSince1970] * 1000)];
    }
    else
    {
        afterDate = [NSString stringWithFormat:@"%llu", (unsigned long long)(([[NSDate date] timeIntervalSince1970] - 3 * 24 * 60 * 60) * 1000)];
    }
    
    dispatch_async(queue, ^()
    {
        LinkedinRequest* request = [[LinkedinRequest alloc] init];

        [request getNotificationsWithToken:accessToken
                                   userId:userId
                                    after:afterDate
                          completionBlock:^(NSDictionary *resultDictionary)
        {
            NSError *error;
            LinkedinSN *bgSelf = (LinkedinSN*)[[WDDDataBase sharedDatabase].managedObjectContext existingObjectWithID:objectId error:&error];
            if (bgSelf && !error)
            {
//                [bgSelf facebookRefreshGroupsDidFinishWithGroups:resultDictionary[@"groups"]];
//                [bgSelf facebookGetPostDidFinishWithPosts:resultDictionary[@"posts"]];
//                [bgSelf saveMedia:resultDictionary[@"photos"]];
//                [bgSelf saveUsers:resultDictionary[@"users"]];
                [bgSelf saveNotificationsToDataBase:resultDictionary[@"notifications"]];
            }
        }
                          completionQueue:queue
        ];
    });
}

- (void)markNotificationAsRead:(Notification *)notification
{
    notification.isUnread           = @NO;
    notification.isMarkingAsRead    = NO;
}

- (void)updateProfileInfo
{
    NSString *urlString = [NSString stringWithFormat:@"https://api.linkedin.com/v1/people/~:(first-name,last-name,picture-url,id)?oauth2_access_token=%@", self.accessToken];
    NSURL *requestURL = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest *userRequest = [NSMutableURLRequest requestWithURL:requestURL];
    
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:userRequest returningResponse:&response error:&error];
    
    if(data)
    {
        NSString *stringData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        DLog(@"Got info about LinkedIN profile: %@", stringData);
        
        DDXMLDocument *xmlDocument = [[DDXMLDocument alloc] initWithData:data options:0 error:&error];
        DDXMLElement *rootElement = xmlDocument.rootElement;
        DDXMLElement *statusElement = [[rootElement elementsForName:@"status"] firstObject];
        NSString *status = [statusElement stringValue];
        if (status.integerValue < 400)
        {
            DDXMLElement* firstNameElement = [[rootElement elementsForName:@"first-name"] firstObject];
            NSString* firstName = [firstNameElement stringValue];
            DDXMLElement* lastNameElement = [[rootElement elementsForName:@"last-name"] firstObject];
            NSString* lastName = [lastNameElement stringValue];
            NSString* name = nil;
            if(firstName)
            {
                if(firstName.length>0)
                {
                    name = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                }
                else
                {
                    name = [NSString stringWithFormat:@"%@",lastName];
                }
            }
            else
            {
                name = [NSString stringWithFormat:@"%@",lastName];
            }
            
            NSArray* photoURLElementsArray = [rootElement elementsForName:@"picture-url"]; //check if image-url exist
            NSString* photoURL = nil;
            if(photoURLElementsArray)
            {
                DDXMLElement* photoURLElement = [photoURLElementsArray lastObject];
                photoURL = [photoURLElement stringValue];
            }
            
            if (name)
            {
                self.displayName = name;
            }
            if (photoURL)
            {
                self.profile.avatarRemoteURL = photoURL;
            }
        }
    }
}

@end
