//
//  SocialNetworkUpdate.m
//  Woddl
//
//  Created by Александр Бородулин on 05.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "SocialNetworkManager.h"
#import "SocialNetwork.h"
#import "WDDDataBase.h"
#import "TwitterRequest.h"
#import "FacebookRequest.h"
#import "FaceBookPost.h"
#import "TwitterPost.h"
#import "GooglePlusPost.h"
#import "LinkedinPost.h"
#import "InstagramPost.h"
#import "LinkedinRequest.h"
#import "InstagramRequest.h"
#import "FoursquareRequest.h"
#import "FoursquarePost.h"
#import "Comment.h"
#import "WDDAppDelegate.h"
#import "FacebookSN.h"
#import "LinkedinSN.h"

//NSString * const kPostIDDictKey = @"postID";
NSString * const kLoadMorePostsFrom = @"loadMoreFrom";
NSString * const kLoadMorePostsTo = @"loadMoreTo";
NSString * const kLoadMorePostsType = @"loadMoreType";
NSString * const kLoadMorePostsUserID = @"loadMoreUserID";
NSString * const kLoadMorePostsLastPostID = @"loadMoreLastPostID";
NSString * const kLoadMorePostsSelfCount = @"loadMoreSelfCount";
NSString * const kLoadMorePostsTheirCount = @"loadMoreTheirCount";
NSString * const kLoadMorePostsGroups = @"loadMoreGroups";
NSString * const kLoadMorePostsGroupCount = @"loadMoreGroupCount";
NSString * const kLoadMorePostsGroupType = @"loadMoreGroupType";
NSString * const kLoadMorePostsGroupLastPostTimestamp = @"loadMoreGroupLastPostTimestamp";

typedef void (^UpdatePosts)();

@interface SocialNetworkManager()

@property (assign, nonatomic) NSInteger numberOFSNsForSearchLeft;
@property (assign, nonatomic) BOOL isUpdatePostsInProgress;
@property (assign, nonatomic) BOOL isLoadingMoreInProgress;

@property (assign, nonatomic) BOOL isGoogleInProgress;

@end

@implementation SocialNetworkManager

@synthesize searchCompletionBlock;

static SocialNetworkManager* mySocialNetworkManager = nil;

#pragma mark - Initialization

+ (SocialNetworkManager *)sharedManager
{
    static dispatch_once_t pred;
    dispatch_once(&pred,^{
        mySocialNetworkManager = [[super allocWithZone:NULL] init];
    });
    return mySocialNetworkManager;
}

- (id)init
{
    if (self = [super init])
    {
        self.isUpdatePostsInProgress = NO;
        self.isLoadingMoreInProgress = NO;
        self.isGoogleInProgress = NO;
    }
    return self;
}

- (void)setIsUpdatePostsInProgress:(BOOL)isUpdatePostsInProgress
{
    WDDAppDelegate* delegate = [[UIApplication sharedApplication] delegate];
    
    if (!_isUpdatePostsInProgress && isUpdatePostsInProgress)
    {
        delegate.networkActivityIndicatorCounter++;
        DLog(@"Start update");
    }
    else if (_isUpdatePostsInProgress && !isUpdatePostsInProgress)
    {
        delegate.networkActivityIndicatorCounter--;
        DLog(@"Finish update");
    }
    
    _isUpdatePostsInProgress = isUpdatePostsInProgress;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUpdatingStatusChanged
                                                        object:nil
                                                      userInfo:@{kNotificationParamaterStatus : @(isUpdatePostsInProgress)}];
}

- (BOOL)updatePosts
{
    DLog(@"updatePosts called, update status: %d", self.isUpdatePostsInProgress);
    
    if (!self.isUpdatePostsInProgress)
    {
        
        UpdatePosts update = ^void()
        {
            __block UIBackgroundTaskIdentifier updateTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                
                [[WDDDataBase sharedDatabase] save];
            }];
            
            self.isUpdatePostsInProgress = YES;
            NSArray* socialNateworks = [[WDDDataBase sharedDatabase] getItemsWithEntityName:NSStringFromClass([SocialNetwork class]) andPredicate:nil];
            
            if ([(WDDAppDelegate *)[[UIApplication sharedApplication] delegate] isInternetConnected])
            {
                __block NSUInteger networksCount = socialNateworks.count;
#if IGNORE_GOOGLE == ON
                __block NSUInteger googleCount = 0;
                
                NSMutableArray *objectsToRemove = [[NSMutableArray alloc] initWithCapacity:socialNateworks.count];
                [socialNateworks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    
                    if ([(SocialNetwork *)obj type].integerValue == kSocialNetworkGooglePlus)
                    {
                        --networksCount;
                        if (self.isGoogleInProgress)
                        {
                            [objectsToRemove addObject:obj];
                        }
                        else
                        {
                            googleCount++;
                        }
                    }
                }];
                
                if (googleCount)
                {
                    self.isGoogleInProgress = YES;
                }
                else if (objectsToRemove.count)
                {
                    socialNateworks = [socialNateworks mutableCopy];
                    [(NSMutableArray *)socialNateworks removeObjectsInArray:objectsToRemove];
                }
#endif
                
                if(networksCount>0)
                {
                    for(SocialNetwork* socNetwork in socialNateworks)
                    {
                        if(socNetwork.activeState.boolValue && [[WDDDataBase sharedDatabase] activeSocialNetworkOfType:socNetwork.type.integerValue])
                        {
                            NSManagedObjectID *socialNetworkId = socNetwork.objectID;
                            
                            NSString *queueName = [NSString stringWithFormat:@"sn_%@_update", socNetwork.profile.userID];
                            dispatch_queue_t updateQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
                            
                            dispatch_async(updateQueue, ^{
                                
                                SocialNetwork *socialNetwork = (SocialNetwork *)[[WDDDataBase sharedDatabase].managedObjectContext objectWithID:socialNetworkId];
                                
                                DLog(@"Posts getting started for network %@ account : %@", socialNetwork.type, socialNetwork.profile.name);
                                
                                [socialNetwork refreshGroups];
                                [socialNetwork getPostsWithCompletionBlock:^(NSError *error) {
                                
#if IGNORE_GOOGLE == ON
                                    if (socialNetwork.type.integerValue == kSocialNetworkGooglePlus)
                                    {
                                        if (!--googleCount)
                                        {
                                            self.isGoogleInProgress = NO;
                                        }
                                    }
#endif
                                    
                                    if (--networksCount == 0)
                                    {
                                        [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                                        updateTask = UIBackgroundTaskInvalid;
                                        
                                        self.isUpdatePostsInProgress = NO;
                                    }
                                    
                                    [[WDDDataBase sharedDatabase] save];
                                }];
                            });
                        }
                        else
                        {
#if IGNORE_GOOGLE == ON
                            if (socNetwork.type.integerValue == kSocialNetworkGooglePlus)
                            {
                                if (!--googleCount)
                                {
                                    self.isGoogleInProgress = NO;
                                }
                            }
#endif
                            
                            if (!--networksCount)
                            {
                                [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                                updateTask = UIBackgroundTaskInvalid;
                                
                                self.isUpdatePostsInProgress = NO;
                            }
                        }
                    }
                }
                else
                {
                    [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                    updateTask = UIBackgroundTaskInvalid;
                    
                    self.isUpdatePostsInProgress = NO;
                }
            }
            else
            {
                [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                updateTask = UIBackgroundTaskInvalid;
                
                self.isUpdatePostsInProgress = NO;
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationInternetNotConnected object:nil];
            }
        };
        
        if ([[NSThread currentThread] isEqual:[NSThread mainThread]])
        {
            dispatch_queue_t postsUpdateQueue = dispatch_queue_create("post updating queue", NULL);
            dispatch_async(postsUpdateQueue, update);
        }
        else
        {
            update();
        }
        
        return YES;
    }
    
    return NO;
}

-(BOOL)updatePostsWithComplationBlock:(void (^)(void))complationBlock
{
    DLog(@"updatePostsWithComplationBlock: called, update status: %d", self.isUpdatePostsInProgress);
    
    if(!self.isUpdatePostsInProgress)
    {
        UpdatePosts update = ^void()
        {
            __block UIBackgroundTaskIdentifier updateTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                
                [[WDDDataBase sharedDatabase] save];
            }];
            
            
            self.isUpdatePostsInProgress = YES;
            NSArray* socialNateworks = [[WDDDataBase sharedDatabase] getItemsWithEntityName:NSStringFromClass([SocialNetwork class]) andPredicate:nil];
            
            if ([(WDDAppDelegate *)[[UIApplication sharedApplication] delegate] isInternetConnected])
            {
                __block NSUInteger networksCount = socialNateworks.count;
#if IGNORE_GOOGLE == ON
                __block NSUInteger googleCount = 0;
                
                NSMutableArray *objectsToRemove = [[NSMutableArray alloc] initWithCapacity:socialNateworks.count];
                [socialNateworks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    
                    if ([(SocialNetwork *)obj type].integerValue == kSocialNetworkGooglePlus)
                    {
                        --networksCount;
                        if (self.isGoogleInProgress)
                        {
                            [objectsToRemove addObject:obj];
                        }
                        else
                        {
                            googleCount++;
                        }
                    }
                }];
                
                if (googleCount)
                {
                    self.isGoogleInProgress = YES;
                }
                else if (objectsToRemove.count)
                {
                    socialNateworks = [socialNateworks mutableCopy];
                    [(NSMutableArray *)socialNateworks removeObjectsInArray:objectsToRemove];
                }
#endif
                DLog(@"Internet connection is up. Perform update for %ld networks", socialNateworks.count);
                if (networksCount > 0)
                {
                    for (SocialNetwork* socNetwork in socialNateworks)
                    {
                        DLog(@"%@ will check and update if active", NSStringFromClass([socNetwork class]));
                        if (socNetwork.activeState.boolValue && [[WDDDataBase sharedDatabase] activeSocialNetworkOfType:socNetwork.type.integerValue])
                        {
                            DLog(@"%@ is active, start updating posts", NSStringFromClass([socNetwork class]));
                            
                            NSManagedObjectID *socialNetworkId = socNetwork.objectID;
                            
                            NSString *queueName = [NSString stringWithFormat:@"sn_%@_update", socNetwork.profile.userID];
                            dispatch_queue_t updateQueue = dispatch_queue_create(queueName.UTF8String, 0);
                            
                            dispatch_async(updateQueue, ^{
                                
                                SocialNetwork *socialNetwork = (SocialNetwork *)[[WDDDataBase sharedDatabase].managedObjectContext objectWithID:socialNetworkId];
                                DLog(@"Posts getting started for network %@ account : %@", NSStringFromClass([socialNetwork class]), socialNetwork.profile.name);
                            
                                [socialNetwork getPostsWithCompletionBlock:^(NSError *error) {
                                    
                                    [[WDDDataBase sharedDatabase] save];
                                    
                                    if (error)
                                    {
                                        DLog(@"Erro while getting posts for network %@ account : %@", NSStringFromClass([socialNetwork class]), socialNetwork.profile.name);
                                    }
                                    else
                                    {
                                        DLog(@"Succeed getting posts for network %@ account : %@", NSStringFromClass([socialNetwork class]), socialNetwork.profile.name);
                                    }
#if IGNORE_GOOGLE == ON
                                    if (socialNetwork.type.integerValue == kSocialNetworkGooglePlus)
                                    {
                                        if (!--googleCount)
                                        {
                                            self.isGoogleInProgress = NO;
                                        }
                                    }
#endif
                                    
                                    networksCount--;
                                    if (networksCount == 0)
                                    {
                                        [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                                        updateTask = UIBackgroundTaskInvalid;
                                        
                                        self.isUpdatePostsInProgress = NO;
                                        complationBlock();
                                    }
                                    
                                }];
                            });
                        }
                        else
                        {
                            DLog(@"%@ is not active, skip it", NSStringFromClass([socNetwork class]));
                            
#if IGNORE_GOOGLE == ON
                            if (socNetwork.type.integerValue == kSocialNetworkGooglePlus)
                            {
                                if (!--googleCount)
                                {
                                    self.isGoogleInProgress = NO;
                                }
                            }
#endif
                            
                            networksCount--;
                            if (networksCount == 0)
                            {
                                [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                                updateTask = UIBackgroundTaskInvalid;
                                
                                self.isUpdatePostsInProgress = NO;
                                complationBlock();
                            }
                        }
                    }
                }
                else
                {
                    [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                    updateTask = UIBackgroundTaskInvalid;
                    
                    self.isUpdatePostsInProgress = NO;
                    complationBlock();
                }
            }
            else
            {
                DLog(@"Can't update - no internet connection");
                [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                updateTask = UIBackgroundTaskInvalid;
                
                self.isUpdatePostsInProgress = NO;
                complationBlock();
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationInternetNotConnected object:nil];
            }
        };
        
        if ([[NSThread currentThread] isEqual:[NSThread mainThread]])
        {
            dispatch_queue_t postsUpdateQueue = dispatch_queue_create("post updating queue", NULL);
            dispatch_async(postsUpdateQueue, update);
        }
        else
        {
            update();
        }
        
        return YES;
    }

    return NO;
}

-(BOOL)updateSocialNetworkPostsWithUserID:(NSString*)userID andComplationBlock:(void (^)(void))complationBlock
{
    DLog(@"updateSocialNetworkPostsWithUserID: called, update status: %d", self.isUpdatePostsInProgress);
    
    if(!self.isUpdatePostsInProgress)
    {
        UpdatePosts update = ^void()
        {
            self.isUpdatePostsInProgress = YES;
            NSArray* socialNateworks = [[WDDDataBase sharedDatabase] getItemsWithEntityName:NSStringFromClass([SocialNetwork class]) andPredicate:nil];
            
            if ([(WDDAppDelegate *)[[UIApplication sharedApplication] delegate] isInternetConnected])
            {
                DLog(@"Internet connection is up. Perform update for %ld networks", (unsigned long)socialNateworks.count);
                __block NSUInteger networksCount = socialNateworks.count;
                if (networksCount > 0)
                {
                    for (SocialNetwork* socNetwork in socialNateworks)
                    {
                        DLog(@"Internet connection is up. Perform update for %ld networks", (unsigned long)socialNateworks.count);
                        if (socNetwork.activeState.boolValue && [[WDDDataBase sharedDatabase] activeSocialNetworkOfType:socNetwork.type.integerValue] && [socNetwork.profile.userID isEqualToString:userID])
                        {
                            NSManagedObjectID *socialNetworkId = socNetwork.objectID;
                            
                            NSString *queueName = [NSString stringWithFormat:@"sn_%@_update", socNetwork.profile.userID];
                            dispatch_queue_t updateQueue = dispatch_queue_create(queueName.UTF8String, nil);
                            
                            dispatch_async(updateQueue, ^{
                                
                                SocialNetwork *socialNetwork = (SocialNetwork *)[[WDDDataBase sharedDatabase].managedObjectContext objectWithID:socialNetworkId];
                                
                                [socialNetwork getPostsWithCompletionBlock:^(NSError *error) {
                                    
                                    [socialNetwork refreshGroups];
                                    
                                    networksCount--;
                                    if (networksCount == 0)
                                    {
                                        self.isUpdatePostsInProgress = NO;
                                        complationBlock();
                                    }
                                }];
                            });
                        }
                        else
                        {
                            networksCount--;
                            if (networksCount == 0)
                            {
                                self.isUpdatePostsInProgress = NO;
                                complationBlock();
                            }
                        }
                    }
                }
                else
                {
                    self.isUpdatePostsInProgress = NO;
                    complationBlock();
                }
            }
            else
            {
                DLog(@"Can't update - no internet connection");
                self.isUpdatePostsInProgress = NO;
                complationBlock();
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationInternetNotConnected object:nil];
            }
        };
        
        if ([[NSThread currentThread] isEqual:[NSThread mainThread]])
        {
            dispatch_queue_t postsUpdateQueue = dispatch_queue_create("post updating queue", NULL);
            dispatch_async(postsUpdateQueue, update);
        }
        else
        {
            update();
        }
        
        return YES;
    }
    
    return NO;
}

-(BOOL)updateFacebookAndTwitterSocialNetworkWithComplationBlock:(void (^)(void))complationBlock
{
    DLog(@"updateSocialNetworkPostsWithUserID: called, update status: %d", self.isUpdatePostsInProgress);
    
    if(!self.isUpdatePostsInProgress)
    {
        UpdatePosts update = ^void()
        {
            self.isUpdatePostsInProgress = YES;
            NSArray* socialNateworks = [[WDDDataBase sharedDatabase] getItemsWithEntityName:NSStringFromClass([SocialNetwork class]) andPredicate:nil];
            
            if ([(WDDAppDelegate *)[[UIApplication sharedApplication] delegate] isInternetConnected])
            {
                DLog(@"Internet connection is up. Perform update for %ld networks", (unsigned long)socialNateworks.count);
                __block NSUInteger networksCount = socialNateworks.count;
                if (networksCount > 0)
                {
                    for (SocialNetwork* socNetwork in socialNateworks)
                    {
                        DLog(@"Internet connection is up. Perform update for %ld networks", (unsigned long)socialNateworks.count);
                        if (socNetwork.activeState.boolValue && [[WDDDataBase sharedDatabase] activeSocialNetworkOfType:socNetwork.type.integerValue] && (socNetwork.type.integerValue == kSocialNetworkTwitter || socNetwork.type.integerValue == kSocialNetworkFacebook))
                        {
                            NSManagedObjectID *socialNetworkId = socNetwork.objectID;
                            
                            NSString *queueName = [NSString stringWithFormat:@"sn_%@_update", socNetwork.profile.userID];
                            dispatch_queue_t updateQueue = dispatch_queue_create(queueName.UTF8String, nil);
                            
                            dispatch_async(updateQueue, ^{
                                
                                SocialNetwork *socialNetwork = (SocialNetwork *)[[WDDDataBase sharedDatabase].managedObjectContext objectWithID:socialNetworkId];
                                
                                [socialNetwork getPostsWithCompletionBlock:^(NSError *error) {
                                    
                                    [socialNetwork refreshGroups];
                                    
                                    networksCount--;
                                    if (networksCount == 0)
                                    {
                                        self.isUpdatePostsInProgress = NO;
                                        complationBlock();
                                    }
                                }];
                            });
                        }
                        else
                        {
                            networksCount--;
                            if (networksCount == 0)
                            {
                                self.isUpdatePostsInProgress = NO;
                                complationBlock();
                            }
                        }
                    }
                }
                else
                {
                    self.isUpdatePostsInProgress = NO;
                    complationBlock();
                }
            }
            else
            {
                DLog(@"Can't update - no internet connection");
                self.isUpdatePostsInProgress = NO;
                complationBlock();
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationInternetNotConnected object:nil];
            }
        };
        
        if ([[NSThread currentThread] isEqual:[NSThread mainThread]])
        {
            dispatch_queue_t postsUpdateQueue = dispatch_queue_create("post updating queue", NULL);
            dispatch_async(postsUpdateQueue, update);
        }
        else
        {
            update();
        }
        
        return YES;
    }
    
    return NO;
}

- (BOOL)loadMorePostsFromInfoData:(NSDictionary*)infoData withComplitionBlock:(void (^)(void))complationBlock
{
    
    if(!self.isLoadingMoreInProgress)
    {
        self.isLoadingMoreInProgress = YES;
        
        UpdatePosts update = ^void()
        {
            __block UIBackgroundTaskIdentifier updateTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
                
                [[WDDDataBase sharedDatabase] save];
            }];
            
            __block NSInteger allActionsCount = 0;
            
            NSArray* allUsersID = [infoData allKeys];
            NSManagedObjectID *networkID = nil;
     
            for(NSString* userID in allUsersID)
            {
                NSDictionary* getPostsInfo = [infoData objectForKey:userID];
     
                NSPredicate* predicate = [NSPredicate predicateWithFormat:@"self.profile.userID == %@ AND self.type == %i", userID,[[getPostsInfo objectForKey:kLoadMorePostsType] intValue]];
                
                NSArray* socialNateworks = [[WDDDataBase sharedDatabase] getItemsWithEntityName:NSStringFromClass([SocialNetwork class]) andPredicate:predicate];
                
                SocialNetwork* socNetwork = [socialNateworks lastObject];
                
                if([[getPostsInfo objectForKey:kLoadMorePostsType] intValue] == kSocialNetworkTwitter ||
                   [[getPostsInfo objectForKey:kLoadMorePostsType] intValue] == kSocialNetworkInstagram)
                {
                    networkID = socNetwork.objectID;
                    ++allActionsCount;
                    
                    NSString *queueName = [NSString stringWithFormat:@"sn_%@_update", socNetwork.profile.userID];
                    dispatch_queue_t updateQueue = dispatch_queue_create(queueName.UTF8String, nil);
                    
                    dispatch_async(updateQueue, ^{
                        
                        SocialNetwork *network = (SocialNetwork *)[[WDDDataBase sharedDatabase].managedObjectContext objectWithID:networkID];
                        [network getPostsFrom:[getPostsInfo objectForKey:kLoadMorePostsLastPostID]
                                              to:[getPostsInfo objectForKey:kLoadMorePostsTo]
                                     isSelfPosts:YES];
                        
                        [[WDDDataBase sharedDatabase] save];
                        
                        if (!--allActionsCount)
                        {
                            [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                            updateTask = UIBackgroundTaskInvalid;
                            
                            self.isLoadingMoreInProgress = NO;
                            complationBlock();
                        }
                    });
                }
                else if([[getPostsInfo objectForKey:kLoadMorePostsType] intValue] == kSocialNetworkLinkedIN)
                {
                    networkID = socNetwork.objectID;
                    ++allActionsCount;
                    
                    NSString *queueName = [NSString stringWithFormat:@"sn_%@_update", socNetwork.profile.userID];
                    dispatch_queue_t updateQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_CONCURRENT);
                    
                    __block NSInteger operationsCount = 0;
                    
                    dispatch_async(updateQueue, ^{
                        
                        ++operationsCount;
                        SocialNetwork *network = (SocialNetwork *)[[WDDDataBase sharedDatabase].managedObjectContext objectWithID:networkID];
                        [network getPostsFrom:[getPostsInfo objectForKey:kLoadMorePostsSelfCount]
                                              to:[getPostsInfo objectForKey:kLoadMorePostsTo]
                                     isSelfPosts:YES];
                        [network getPostsFrom:[getPostsInfo objectForKey:kLoadMorePostsTheirCount]
                                              to:[getPostsInfo objectForKey:kLoadMorePostsTo]
                                     isSelfPosts:NO];
                        
                        
                        
                        [[WDDDataBase sharedDatabase] save];
                        
                        if (!--operationsCount)
                        {
                            [[WDDDataBase sharedDatabase] save];
                            
                            if (!--allActionsCount)
                            {
                                [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                                updateTask = UIBackgroundTaskInvalid;
                                
                                self.isLoadingMoreInProgress = NO;
                                complationBlock();
                            }
                        }

                    });
                    
                    dispatch_async(updateQueue, ^{
                        
                        LinkedinSN *network = (LinkedinSN *)[[WDDDataBase sharedDatabase].managedObjectContext objectWithID:networkID];
                        
                        NSArray* groupsInfo = [getPostsInfo objectForKey:kLoadMorePostsGroups];
                        
                        for(NSDictionary* groupInfo in groupsInfo)
                        {
                            NSString* groupID = [[groupInfo allKeys] lastObject];
                            NSDictionary* groupDict = [groupInfo objectForKey:groupID];
                            
                            ++operationsCount;
                            
                            [network loadMoreGroupsPostsWithGroupID:groupID
                                                               from:[groupDict objectForKey:kLoadMorePostsGroupCount]
                                                                 to:[getPostsInfo objectForKey:kLoadMorePostsTo]];
                            
                            if (!--operationsCount)
                            {
                                [[WDDDataBase sharedDatabase] save];
                                
                                if (!--allActionsCount)
                                {
                                    [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                                    updateTask = UIBackgroundTaskInvalid;
                                    
                                    self.isLoadingMoreInProgress = NO;
                                    complationBlock();
                                }
                            }
                        }
                    });
                }
                else if([[getPostsInfo objectForKey:kLoadMorePostsType] intValue] == kSocialNetworkFacebook)
                {
                    ++allActionsCount;
                    
                    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([Post class])];
                    request.predicate = [NSPredicate predicateWithFormat:@"postID == %@ AND subscribedBy == %@",
                                         getPostsInfo[kLoadMorePostsLastPostID], socNetwork.profile];
                    NSError *fetchError = nil;
                    NSArray *posts = [socNetwork.managedObjectContext executeFetchRequest:request
                                                                                    error:&fetchError];
                    if (fetchError)
                    {
                        DLog(@"Can't get information about last exist FB post: %@", fetchError);
                    }
                    
                    NSString *timestamp = [@((int)[[posts.firstObject time] timeIntervalSince1970]) stringValue];
                    
                    networkID = socNetwork.objectID;
                    __block NSInteger operationsCount = 0;
                    
                    NSString *queueName = [NSString stringWithFormat:@"sn_%@_update", socNetwork.profile.userID];
                    dispatch_queue_t updateQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_CONCURRENT);
                    
                    dispatch_async(updateQueue, ^{
                        
                        SocialNetwork *network = (SocialNetwork *)[[WDDDataBase sharedDatabase].managedObjectContext objectWithID:networkID];
                        ++operationsCount;
                        [network getPostsFrom:timestamp
                                           to:[getPostsInfo objectForKey:kLoadMorePostsTo] isSelfPosts:YES];
                        
                        if (!--operationsCount)
                        {
                            [[WDDDataBase sharedDatabase] save];
                            
                            if (!--allActionsCount)
                            {
                                [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                                updateTask = UIBackgroundTaskInvalid;
                                
                                self.isLoadingMoreInProgress = NO;
                                complationBlock();
                            }
                        }
                    });
                    
                    dispatch_async(updateQueue, ^{

                        NSArray* groupsInfo = [getPostsInfo objectForKey:kLoadMorePostsGroups];
                        
                        NSInteger postsPerGroupCount = 0;
                        if (groupsInfo.count)
                        {
                            postsPerGroupCount = 20 / groupsInfo.count;
                        }
                        
                        if (!postsPerGroupCount)
                        {
                            postsPerGroupCount = 1;
                        }
                        
                        for(NSDictionary* groupInfo in groupsInfo)
                        {
                            NSString* groupID = [[groupInfo allKeys] lastObject];
                            NSDictionary* groupDict = [groupInfo objectForKey:groupID];
                            
                            FacebookSN *network = (FacebookSN *)[[WDDDataBase sharedDatabase].managedObjectContext objectWithID:networkID];
                            NSNumber* typeGroup = [groupDict objectForKey:kLoadMorePostsGroupType];
                            
                            ++operationsCount;
                            [network loadMoreGroupsPostsWithGroupID:groupID
                                                       andGroupType:typeGroup.integerValue
                                                               from:[groupDict objectForKey:kLoadMorePostsGroupLastPostTimestamp]
                                                                 to:@(postsPerGroupCount).stringValue];
                            
                            if (!--operationsCount)
                            {
                                [[WDDDataBase sharedDatabase] save];
                                
                                if (!--allActionsCount)
                                {
                                    [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                                    updateTask = UIBackgroundTaskInvalid;
                                    
                                    self.isLoadingMoreInProgress = NO;
                                    complationBlock();
                                }
                            }
                        }
                    });
                }
                else
                {
#if IGNORE_GOOGLE == ON
                   if([[getPostsInfo objectForKey:kLoadMorePostsType] intValue] == kSocialNetworkGooglePlus &&
                      self.isGoogleInProgress)
                   {
                       continue;
                   }
#endif
                    
                    networkID = socNetwork.objectID;
                    ++allActionsCount;
                    
                    NSString *queueName = [NSString stringWithFormat:@"sn_%@_update", socNetwork.profile.userID];
                    dispatch_queue_t updateQueue = dispatch_queue_create(queueName.UTF8String, nil);
                    
                    dispatch_async(updateQueue, ^{
                        
                        SocialNetwork *network = (SocialNetwork *)[[WDDDataBase sharedDatabase].managedObjectContext objectWithID:networkID];
                        [network getPostsFrom:[getPostsInfo objectForKey:kLoadMorePostsFrom] to:[getPostsInfo objectForKey:kLoadMorePostsTo] isSelfPosts:YES];
                        
                        [[WDDDataBase sharedDatabase] save];
                        
                        if (!--allActionsCount)
                        {
                            [[UIApplication sharedApplication] endBackgroundTask:updateTask];
                            updateTask = UIBackgroundTaskInvalid;
                            
                            self.isLoadingMoreInProgress = NO;
                            complationBlock();
                        }
                    });
                }
            }
        };
        
        if ([[NSThread currentThread] isEqual:[NSThread mainThread]])
        {
            dispatch_queue_t postsUpdateQueue = dispatch_queue_create("post updating queue", NULL);
            dispatch_async(postsUpdateQueue, update);
        }
        else
        {
            update();
        }
        
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)cancelAllPostUpdates
{
    self.isUpdatePostsInProgress = NO;
    NSArray* socialNateworks = [[WDDDataBase sharedDatabase] getItemsWithEntityName:NSStringFromClass([SocialNetwork class]) andPredicate:nil];
    for(SocialNetwork* socNetwork in socialNateworks)
    {
        [[[socNetwork class] operationQueue] cancelAllOperations];
        DLog(@"%@", NSStringFromClass([socNetwork class]));
        [[[socNetwork class] operationQueue].operations enumerateObjectsUsingBlock:^(NSOperation *obj, NSUInteger idx, BOOL *stop) {
            DLog(@"IS canceld: %d",obj.isCancelled);
        }];
    }
}

- (void)searchPostWithText:(NSString *)searchText
{
    [self searchPostWithText:searchText completionBlock:nil];
}

- (void)searchPostWithText:(NSString *)searchText
  forSocialNetworkWithType:(SocialNetworkType)type
     ifInAvailableNetworks:(NSInteger)availableSocialNetworks
            comletionBlock:(void (^)(NSError *))completionBlock
{
    if (availableSocialNetworks & type)
    {
        SocialNetwork *sn = [[[WDDDataBase sharedDatabase] fetchSocialNetworksAscendingWithType:type] firstObject];
        if (sn)
        {
            [sn searchPostsWithText:searchText completionBlock:completionBlock];
        }
    }
}

- (void)searchPostWithText:(NSString *)searchText completionBlock:(void (^)(void))completionBlock
{
    if (!searchText.length)
    {
        return ;
    }
    
    searchCompletionBlock = completionBlock;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        ((WDDAppDelegate *)[UIApplication sharedApplication].delegate).networkActivityIndicatorCounter+= 1;
        
        self.numberOFSNsForSearchLeft = [[WDDDataBase sharedDatabase] countAvailableSocialNetworks];
        NSInteger availableSocialNetworks = [[WDDDataBase sharedDatabase] availableSocialNetworks];
        
        void(^searchCompletion)(NSError *) = ^(NSError *error)
        {
            --self.numberOFSNsForSearchLeft;
            if (!self.numberOFSNsForSearchLeft)
            {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (searchCompletionBlock)
                        {
                            ((WDDAppDelegate *)[UIApplication sharedApplication].delegate).networkActivityIndicatorCounter-= 1;
                            searchCompletionBlock();
                            searchCompletionBlock = nil;
                        }
                    });
            }
        };
        
        dispatch_queue_t searchOperationsQueue = dispatch_queue_create("search operations queue", DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(searchOperationsQueue, ^{
            [self searchPostWithText:searchText forSocialNetworkWithType:kSocialNetworkFacebook ifInAvailableNetworks:availableSocialNetworks comletionBlock:searchCompletion];
        });
        dispatch_async(searchOperationsQueue, ^{
            [self searchPostWithText:searchText forSocialNetworkWithType:kSocialNetworkTwitter ifInAvailableNetworks:availableSocialNetworks comletionBlock:searchCompletion];
        });
        dispatch_async(searchOperationsQueue, ^{
            [self searchPostWithText:searchText forSocialNetworkWithType:kSocialNetworkFoursquare ifInAvailableNetworks:availableSocialNetworks comletionBlock:searchCompletion];
        });
        dispatch_async(searchOperationsQueue, ^{
            [self searchPostWithText:searchText forSocialNetworkWithType:kSocialNetworkGooglePlus ifInAvailableNetworks:availableSocialNetworks comletionBlock:searchCompletion];
        });
        dispatch_async(searchOperationsQueue, ^{
            [self searchPostWithText:searchText forSocialNetworkWithType:kSocialNetworkLinkedIN ifInAvailableNetworks:availableSocialNetworks comletionBlock:searchCompletion];
        });
        dispatch_async(searchOperationsQueue, ^{
            [self searchPostWithText:searchText forSocialNetworkWithType:kSocialNetworkInstagram ifInAvailableNetworks:availableSocialNetworks comletionBlock:searchCompletion];
        });
    });
}

- (void) cancelSearchPosts
{
    if (searchCompletionBlock)
    {
        ((WDDAppDelegate *)[UIApplication sharedApplication].delegate).networkActivityIndicatorCounter -= 1;
        searchCompletionBlock();
        searchCompletionBlock = nil;
    }
}

@end