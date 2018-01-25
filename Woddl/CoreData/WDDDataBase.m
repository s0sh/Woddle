//
//  WDDDataBase.m
//  Woddl
//
//  Created by Sergii Gordiienko on 29.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Parse/Parse.h>

#import "WDDDataBase.h"
#import "FacebookSN.h"
#import "TwitterSN.h"
#import "GooglePlusSN.h"
#import "InstagramSN.h"
#import "FoursquareSN.h"
#import "LinkedinSN.h"
#import "FaceBookProfile.h"
#import "TwitterProfile.h"
#import "GooglePlusProfile.h"
#import "TwitterOthersProfile.h"
#import "InstagramProfile.h"
#import "FoursqaureProfile.h"
#import "LinkedinProfile.h"
#import "TwitterRequest.h"
#import "Group.h"
#import "GooglePlusPost.h"

#import "WDDCookiesManager.h"

static NSString * const kTypeKey = @"type";

static const char * mainContextQueueLabel = "main context queue";

@implementation WDDDataBase

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - singleton

static WDDDataBase *masterBackgroundInstance = nil;
static dispatch_queue_t masterContextQueue = nil;
static BOOL _isSearchProduced = NO;

+ (void)initializeWithCallBack:(ComplateBlockWithSuccess)complete
{
    @synchronized(self)
    {
        __block ComplateBlockWithSuccess complateBlock = [complete copy];
        
        if (!masterBackgroundInstance)
        {
            masterContextQueue = dispatch_queue_create(mainContextQueueLabel, DISPATCH_QUEUE_CONCURRENT);
            dispatch_async(masterContextQueue, ^{
                masterBackgroundInstance = [[WDDDataBase alloc] initMasterInstance];
                DLog(@"Main context initilized");
                [masterBackgroundInstance removeOldPosts];
                [masterBackgroundInstance save];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (complateBlock)
                    {
                        complateBlock(YES);
                        complateBlock = nil;
                    }
                });
            });
        }
        else
        {
            if (complateBlock)
            {
                complateBlock(YES);
                complateBlock = nil;
            }
        }
    }
}

+ (WDDDataBase *)sharedDatabase
{
    NSParameterAssert(masterBackgroundInstance);
    
    NSString *classDiscription= [[self class] description];
    NSMutableDictionary *threadDictionary= [[NSThread currentThread] threadDictionary];
    WDDDataBase *instance= [threadDictionary objectForKey:classDiscription];
    
    if( !instance )
    {
        instance= [self new];
        if( instance )
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deleteInstance) name:NSThreadWillExitNotification object:nil];
            [threadDictionary setValue:instance forKey:classDiscription];
        }
    }
    
    return instance;
}

+ (void)deleteInstance
{
    NSString *classDiscription= [[self class] description];
    NSMutableDictionary *threadDictionary= [[NSThread currentThread] threadDictionary];
    WDDDataBase *instance= [threadDictionary objectForKey:classDiscription];
    
    if( instance )
    {
        [[NSNotificationCenter defaultCenter] removeObserver:instance];
        [threadDictionary removeObjectForKey:classDiscription];
    }
}

+ (BOOL)isConnectedToDB
{
    return (masterBackgroundInstance != nil);
}

+ (NSManagedObjectContext *)masterObjectContext
{
    return masterBackgroundInstance.managedObjectContext;
}

- (NSManagedObjectModel *)createManagedObjectModel
{
    NSManagedObjectModel *managedObjectModel = nil;
    NSString *momName = @"WoddlModel";
    
    NSString *momPath = [[NSBundle mainBundle] pathForResource:momName ofType:@"mom"];
    if (momPath == nil)
    {
        // The model may be versioned or created with Xcode 4, try momd as an extension.
        momPath = [[NSBundle mainBundle] pathForResource:momName ofType:@"momd"];
    }
    
    if (momPath)
    {
        // If path is nil, then NSURL or NSManagedObjectModel will throw an exception
        
        NSURL *momUrl = [NSURL fileURLWithPath:momPath];
        
        managedObjectModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:momUrl] copy];
    }
    
    return managedObjectModel;
}

- (instancetype)initMasterInstance
{
    if (self = [super init])
    {
        NSAssert(PFUser.currentUser.objectId, @"nil currentUser in %s", __PRETTY_FUNCTION__);
        
        NSURL *storeUrl = [NSURL fileURLWithPath:[[self applicationDocumentsDirectory]
                                                  stringByAppendingPathComponent:[NSString stringWithFormat:@"WoddlModel_%@.sqlite",
                                                                                  PFUser.currentUser.objectId]]];
        NSError *error = nil;
        
        _managedObjectModel = [self createManagedObjectModel];
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                       initWithManagedObjectModel:self.managedObjectModel];
        @try
        {
            if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                           configuration:nil
                                                                     URL:storeUrl
                                                                 options:@{
                                                                           NSMigratePersistentStoresAutomaticallyOption : @YES,
                                                                           NSInferMappingModelAutomaticallyOption : @YES
                                                                           }
                                                                   error:&error])
            {
                @throw [NSException exceptionWithName:@"WDDDataBaseException"
                                               reason:@"Can't add persistent storage"
                                             userInfo:nil];
            }
        }
        @catch (NSException *exception)
        {
            [[NSFileManager defaultManager] removeItemAtURL:storeUrl error:nil];
            [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                      configuration:nil
                                                                URL:storeUrl
                                                            options:@{
                                                                      NSMigratePersistentStoresAutomaticallyOption : @YES,
                                                                      NSInferMappingModelAutomaticallyOption : @YES
                                                                      }
                                                              error:&error];
        }
        @finally
        {
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            _managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        }
    }
    
    return self;
}

- (instancetype)init
{
    if (self = [super init])
    {
        if (!masterBackgroundInstance.persistentStoreCoordinator)
        {
            return self;
        }
        
        _persistentStoreCoordinator = masterBackgroundInstance.persistentStoreCoordinator;
        _managedObjectModel = masterBackgroundInstance.managedObjectModel;
        
        if ([[NSThread mainThread] isEqual:[NSThread currentThread]])
        {
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            _managedObjectContext.parentContext = masterBackgroundInstance.managedObjectContext;
        }
        else
        {
            NSString *classDiscription= [[self class] description];
            NSMutableDictionary *threadDictionary= [[NSThread mainThread] threadDictionary];
            WDDDataBase *instance= [threadDictionary objectForKey:classDiscription];
            
            if (!instance)
            {
                [self performSelectorOnMainThread:@selector(initMainThreadInstance)
                                       withObject:nil
                                    waitUntilDone:YES];
                instance= [threadDictionary objectForKey:classDiscription];
            }
            
            _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            _managedObjectContext.parentContext = instance.managedObjectContext;
        }
    }
    
    return self;
}

- (void)initMainThreadInstance
{
    [WDDDataBase sharedDatabase];
}

- (void)disconnectDatabase
{
    _managedObjectContext       = nil;
    _managedObjectModel         = nil;
    _persistentStoreCoordinator = nil;
    
    masterBackgroundInstance = nil;
    
    NSString *classDiscription= [[self class] description];
    NSMutableDictionary *threadDictionary= [[NSThread mainThread] threadDictionary];
    WDDDataBase *instance= [threadDictionary objectForKey:classDiscription];
    if (instance)
    {
        [threadDictionary removeObjectForKey:classDiscription];
    }
}

#pragma mark - gettors

- (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark - General methods
//  General
- (NSArray *)fetchObjectsWithEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors
{
    NSArray *fetchedObjects;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:self.managedObjectContext];
    request.entity = entity;
    request.predicate = predicate;
    request.sortDescriptors = sortDescriptors;
    
    NSError *error;
    fetchedObjects = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error)
    {
        DLog(@"Fetched error: %@",[error localizedDescription]);
    }
    
    return fetchedObjects;
}

- (BOOL)saveChangesToContext:(NSError **)errorRef
{
    @synchronized(self)
    {
        [self.managedObjectContext save:errorRef];
        if (*errorRef)
        {
            DLog(@"Can't save information to DB: \"%@\"", [*errorRef localizedDescription]);
        }
        
        {
            [self.managedObjectContext lock];
            
            @synchronized(self.managedObjectContext.parentContext)
            {
                [self.managedObjectContext.parentContext performBlock:^{
                    
                    [self.managedObjectContext.parentContext save:errorRef];
                    [self.managedObjectContext unlock];
                }];
            }
        }
    }
    
    return (*errorRef == nil);
}

#pragma mark - Social networks

//  Social networks
- (NSArray *)fetchAllSocialNetworks
{
    NSArray *fetchedSocilaNetworks;
    
    NSFetchRequest *request = [self.managedObjectModel fetchRequestTemplateForName:kCoredataFetchRequestAllSocialNetworks];
    NSError *error;
    fetchedSocilaNetworks = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error)
    {
        DLog(@"Fetched error: %@",[error localizedDescription]);
    }
    
    return fetchedSocilaNetworks;
}

- (NSArray *)fetchSocialNetworksWithAccessToken:(NSString *)token
{
    if (!token)
    {
        return nil;
    }
    
    NSArray *fetchedSocilaNetworks;
    
    NSFetchRequest *request = [self.managedObjectModel fetchRequestFromTemplateWithName:kCoredataFetchRequestSocialNetworksWithToken
                                                                  substitutionVariables:@{ kCoredataFetchRequestKeyAccessToken : token }];
    NSError *error;
    fetchedSocilaNetworks = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error)
    {
        DLog(@"Fetched error: %@",[error localizedDescription]);
    }
    
    return fetchedSocilaNetworks;
}

- (NSArray *)fetchSocialNetworksWithAccessTokenPrefix:(NSString *)tokenPrefix
{
    if (!tokenPrefix)
    {
        return nil;
    }
    
    NSArray *fetchedSocilaNetworks;
    
    NSFetchRequest *request = [self.managedObjectModel fetchRequestFromTemplateWithName:kCoredataFetchRequestSocialNetworksWithTokenPrefix
                                                                  substitutionVariables:@{ kCoredataFetchRequestKeyAccessToken : tokenPrefix }];
    NSError *error;
    fetchedSocilaNetworks = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error)
    {
        DLog(@"Fetched error: %@",[error localizedDescription]);
    }
    
    return fetchedSocilaNetworks;
}

- (NSArray *)fetchSocialNetworksWithAccessProfileUserID:(NSString *)userID
{
    if (!userID)
    {
        return nil;
    }
    
    NSArray *fetchedSocilaNetworks;
    
    NSFetchRequest *request = [self.managedObjectModel fetchRequestFromTemplateWithName:kCoredataFetchRequestKeyProfileUserID
                                                                  substitutionVariables:@{ kCoredataFetchRequestKeyProfileUserID : userID }];
    NSError *error;
    fetchedSocilaNetworks = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error)
    {
        DLog(@"Fetched error: %@",[error localizedDescription]);
    }
    
    return fetchedSocilaNetworks;
}

- (NSArray *)fetchSocialNetworksWithPredicate:(NSPredicate *)predicate
{
    NSArray *fetchedSocilaNetworks;
    
    [self fetchObjectsWithEntityName:NSStringFromClass([SocialNetwork class]) withPredicate:predicate sortDescriptors:nil];
    
    return fetchedSocilaNetworks;
}

- (NSArray *)fetchSocialNetworksAscendingWithType:(SocialNetworkType)type
{
    NSArray *fetchedSocilaNetworks;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.type == %@", @(type)];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES];
    NSSortDescriptor *secondSort = [NSSortDescriptor sortDescriptorWithKey:@"profile.userID" ascending:YES];
    fetchedSocilaNetworks =[self fetchObjectsWithEntityName:NSStringFromClass([SocialNetwork class])
                                              withPredicate:predicate
                                            sortDescriptors:@[sortDescriptor, secondSort]];
    
    return fetchedSocilaNetworks;
}

-(void)addNewSocialNetworkWithType:(SocialNetworkType)type
                         andUserID:(NSString *)userID
                          andToken:(NSString *)token
                    andDisplayName:(NSString *)displayName
                       andImageURL:(NSString *)photo
                         andExpire:(NSDate *)expire
                      andFollowers:(NSArray *)followers
                     andProfileURL:(NSString *)profileURLString andGroups:(NSArray*)groups
{
    NSString* entityName = nil;
    NSString* entityProfileName = NSStringFromClass([UserProfile class]);
    switch(type)
    {
        case kSocialNetworkFacebook:
            entityName = NSStringFromClass([FacebookSN class]);
            entityProfileName = NSStringFromClass([FaceBookProfile class]);
            break;
        case kSocialNetworkTwitter:
            entityName = NSStringFromClass([TwitterSN class]);
            entityProfileName = NSStringFromClass([TwitterProfile class]);
            break;
        case kSocialNetworkInstagram:
            entityName = NSStringFromClass([InstagramSN class]);
            entityProfileName = NSStringFromClass([InstagramProfile class]);
            break;
        case kSocialNetworkFoursquare:
            entityName = NSStringFromClass([FoursquareSN class]);
            entityProfileName = NSStringFromClass([FoursqaureProfile class]);
            break;
        case kSocialNetworkLinkedIN:
            entityName = NSStringFromClass([LinkedinSN class]);
            entityProfileName = NSStringFromClass([LinkedinProfile class]);
            break;
        case kSocialNetworkGooglePlus:
            entityName = NSStringFromClass([GooglePlusSN class]);
            entityProfileName = NSStringFromClass([GooglePlusProfile class]);
            break;
        case kSocialNetworkUnknown:
            entityName = nil;
            break;
    }
    if(entityName)
    {
        [WDDDataBase initializeWithCallBack:^(BOOL success) {
            
            SocialNetwork* network = nil;
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"profile.userID contains[cd] %@", userID];
            network = [[WDDDataBase sharedDatabase] getItemsWithEntityName:entityName andPredicate:predicate].firstObject;
            
            if(!network)
            {
                network = [self addNewItemWithEntityName:entityName];
                [network setTypeWith:type];
                network.accessToken = token;
                network.displayName = displayName;
                network.exspireTokenTime = expire;
                network.profile = [self addNewItemWithEntityName:entityProfileName];
                network.profile.userID = userID;
                network.profile.avatarRemoteURL = photo;
                network.profile.name = displayName;
                network.profile.profileURL = profileURLString;
                
                for (NSDictionary *followerDict in followers)
                {
                    TwitterOthersProfile *twFollower = [self addNewItemWithEntityName:NSStringFromClass([TwitterOthersProfile class])];
                    twFollower.name = [followerDict objectForKey:@"name"];
                    twFollower.userID = [[followerDict objectForKey:@"id"] stringValue];
                    twFollower.avatarRemoteURL = [followerDict objectForKey:@"profile_image_url"];
                    twFollower.profileURL = [TwitterRequest profileURLWithName:followerDict[@"screen_name"]];
                    //twFollower.userID
                    
                    TwitterProfile *twProfile = (TwitterProfile *) network.profile;
                    [twProfile addFollowingObject:twFollower];
                    [twFollower addFriendOfObject:twProfile];
                }
                [network updateSocialNetworkOnParse];
                
                for(NSDictionary* group in groups)
                {
                    //predicate = [NSPredicate predicateWithFormat:@"(mediaURLString like %@ OR previewURLString like %@) AND self.post.subscribedBy.userID like %@", url,[mediaDict objectForKey:kPostMediaPreviewDictKey],post.subscribedBy.userID];
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
                        
                        [network addGroupsObject:groupEntity];
                    }
                }
                
                [network getFriends];
                
                [self save];
            }
            
            if (network.type.integerValue != kSocialNetworkTwitter && network.type.integerValue != kSocialNetworkLinkedIN)
            {
                [[WDDCookiesManager sharedManager] registerCookieForSocialNetwork:network];
            }
        }];
    }
}

#pragma mark - Common Methods

- (NSArray*)getItemsWithEntityName:(NSString*)entityName andPredicate:(NSPredicate*)predicate
{
    return [self getItemsWithEntityName:entityName andPredicate:predicate limit:0];
}

- (NSArray*)getItemsWithEntityName:(NSString*)entityName andPredicate:(NSPredicate*)predicate limit:(NSInteger)limit
{
    if (![PFUser currentUser])
    {
        return nil;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[WDDDataBase sharedDatabase].managedObjectContext];
    [fetchRequest setEntity:entity];
    
    if (limit) [fetchRequest setFetchLimit:limit];
    
    [fetchRequest setFetchBatchSize:20];
    
    [fetchRequest setSortDescriptors:nil];
    
    fetchRequest.predicate = predicate;
    
    NSError *error;
    NSArray* arrayData = [[WDDDataBase sharedDatabase].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if(arrayData.count==0)
    {
        return nil;
    }
    return arrayData;
}

- (id)addNewItemWithEntityName:(NSString *)entityName
{
    NSManagedObjectContext *context = [WDDDataBase sharedDatabase].managedObjectContext;
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    NSManagedObject *entity= [[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
    
    return entity;
}

- (BOOL)findItemWithEntityName:(NSString*)entityName andPredicate:(NSPredicate*) predicate
{
    NSArray* arrayData = [[WDDDataBase sharedDatabase] getItemsWithEntityName:entityName andPredicate:predicate];
    if(arrayData.count==0)
    {
        return NO;
    }
    return YES;
}

-(void)save
{
    NSError *saveError = nil;
    [self saveChangesToContext:&saveError];
    
    if (saveError)
    {
        DLog(@"Can't save context in thread %@ error: %@", [NSThread currentThread], saveError);
    }
}

- (NSInteger)availableSocialNetworks
{
    NSInteger availableSocialNetworks = 0;
    
    NSArray *fetchedNetworkTypes = [self groupFetchSocialNetworkTypes];
    for (NSDictionary *typeInfo in fetchedNetworkTypes)
    {
        NSNumber *typeNumber = typeInfo[kTypeKey];
        availableSocialNetworks = availableSocialNetworks | [typeNumber integerValue];
    }
    return availableSocialNetworks;
}

- (NSInteger)countAvailableSocialNetworks
{
    NSInteger resultNumberOfSNs = 0;
    
    NSInteger availableSocialNetworks = [[WDDDataBase sharedDatabase] availableSocialNetworks];
    if (availableSocialNetworks & kSocialNetworkFacebook)
    {
        ++resultNumberOfSNs;
    }
    if (availableSocialNetworks & kSocialNetworkFoursquare)
    {
        ++resultNumberOfSNs;
    }
    if (availableSocialNetworks & kSocialNetworkTwitter)
    {
        ++resultNumberOfSNs;
    }
    if (availableSocialNetworks & kSocialNetworkInstagram)
    {
        ++resultNumberOfSNs;
    }
    if (availableSocialNetworks & kSocialNetworkLinkedIN)
    {
        ++resultNumberOfSNs;
    }
    if (availableSocialNetworks & kSocialNetworkGooglePlus)
    {
        ++resultNumberOfSNs;
    }
    
    return resultNumberOfSNs;
}

- (NSArray *)groupFetchSocialNetworkTypes
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest* fetch = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([SocialNetwork class])];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accessToken != nil"];
    fetch.predicate = predicate;
    
    NSEntityDescription* entity = [NSEntityDescription entityForName:NSStringFromClass([SocialNetwork class]) inManagedObjectContext:context];
   
    NSAttributeDescription* typeDescription = [entity.attributesByName objectForKey:kTypeKey];
    
    NSExpressionDescription *countDescription = [[NSExpressionDescription alloc] init];
    [countDescription setName:kTypeKey];
    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:kTypeKey];
    [countDescription setExpression: keyPathExpression];
    [countDescription setExpressionResultType: NSObjectIDAttributeType];
    
    [fetch setPropertiesToFetch:@[typeDescription]];
    [fetch setPropertiesToGroupBy:@[typeDescription]];
    
    [fetch setResultType:NSDictionaryResultType];
    
    NSError* error = nil;
    NSArray *results = [context executeFetchRequest:fetch error:&error];
    
    return results;
}

#pragma mark - parse integration

#define NillForNSNull(__value__) ( ((__value__) && [(__value__) isKindOfClass:[NSNull class]]) ? nil : (__value__) )

- (void)updateSocialNetworkFromParse:(PFObject*)parseSocialNetwork withDelegate:(id<SocialNetworkUpdatedDelegate>)delegate
{
    if ([PFUser currentUser])
    {
        BOOL tokenValid = YES;
        
        if ([parseSocialNetwork[@"tokenInvalidated"] boolValue] && [parseSocialNetwork[@"activeState"] boolValue])
        {
            if (delegate)
            {
                dispatch_semaphore_t tokenUpdateSemaphore = dispatch_semaphore_create(0);
                __block NSString *newAccessToken = nil;
                __block NSDate *newExpirationTime = nil;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [delegate needUpdateAccessTokenForNetworkWithType:[parseSocialNetwork[@"type"] integerValue]
                                                               userId:parseSocialNetwork[@"networkUserId"]
                                                          displayName:parseSocialNetwork[@"displayName"]
                                                      complitionBlock:^(SocialNetworkType socialNetwork, NSString *accessToken, NSDate *expirationDate) {
                                                          
                                                          newAccessToken = accessToken;
                                                          newExpirationTime = expirationDate;
                                                          dispatch_semaphore_signal(tokenUpdateSemaphore);
                                                      }];
                });
                
                dispatch_semaphore_wait(tokenUpdateSemaphore, DISPATCH_TIME_FOREVER);
                
                if (newAccessToken)
                {
                    parseSocialNetwork[@"accessToken"] = newAccessToken;
                    parseSocialNetwork[@"expireTokenTime"] = newExpirationTime;
                    parseSocialNetwork[@"tokenInvalidated"] = @NO;
                    
                    [parseSocialNetwork saveEventually];
                }
                else
                {
                    tokenValid = NO;
                }
            }
            else
            {
                tokenValid = NO;
            }
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"profile.userID == %@ && type == %@",
                                  parseSocialNetwork[@"networkUserId"],
                                  parseSocialNetwork[@"type"]];
        
        NSArray *result = [self getItemsWithEntityName:NSStringFromClass([SocialNetwork class]) andPredicate:predicate limit:1];
        
        SocialNetwork *socialNetwork;
        
        if (result.count)
        {
            socialNetwork = result[0];
            
            DLog(@"Found SN to update %@", socialNetwork);
            
            if ([socialNetwork.updatedAt compare:parseSocialNetwork.updatedAt] == NSOrderedDescending &&
                tokenValid)
            {
                DLog(@"SN shouldn't be updated.");
                
                [socialNetwork getFriends];
                [socialNetwork updateProfileInfo];

                NSError *error = nil;
                [_managedObjectContext save:&error];
                NSAssert(!error, @"%@", error);
                
                return;
            }
            
            DLog(@"SN should be updated.");
        }
        else
        {
            NSString *entityName;
            NSString *entityProfileName;
            
            switch([parseSocialNetwork[@"type"] integerValue])
            {
                case kSocialNetworkFacebook:
                    entityName = NSStringFromClass([FacebookSN class]);
                    entityProfileName = NSStringFromClass([FaceBookProfile class]);
                    break;
                case kSocialNetworkTwitter:
                    entityName = NSStringFromClass([TwitterSN class]);
                    entityProfileName = NSStringFromClass([TwitterProfile class]);
                    break;
                case kSocialNetworkInstagram:
                    entityName = NSStringFromClass([InstagramSN class]);
                    entityProfileName = NSStringFromClass([InstagramProfile class]);
                    break;
                case kSocialNetworkFoursquare:
                    entityName = NSStringFromClass([FoursquareSN class]);
                    entityProfileName = NSStringFromClass([FoursqaureProfile class]);
                    break;
                case kSocialNetworkLinkedIN:
                    entityName = NSStringFromClass([LinkedinSN class]);
                    entityProfileName = NSStringFromClass([LinkedinProfile class]);
                    break;
                case kSocialNetworkGooglePlus:
                    entityName = NSStringFromClass([GooglePlusSN class]);
                    entityProfileName = NSStringFromClass([GooglePlusProfile class]);
                    break;
                case kSocialNetworkUnknown:
                    entityName = nil;
                    break;
            }
            
            socialNetwork = [self addNewItemWithEntityName:entityName];
            socialNetwork.profile = [self addNewItemWithEntityName:entityProfileName];
        }
        
        socialNetwork.accessToken               = (tokenValid ? NillForNSNull(parseSocialNetwork[@"accessToken"]) : nil);
        socialNetwork.type                      = NillForNSNull(parseSocialNetwork[@"type"]);
        //socialNetwork.activeState             = parseSocialNetwork[@"activeState"];
        socialNetwork.exspireTokenTime          = (tokenValid ? NillForNSNull(parseSocialNetwork[@"expireTokenTime"]) : nil);
        socialNetwork.profile.userID            = NillForNSNull(parseSocialNetwork[@"networkUserId"]);
        socialNetwork.profile.avatarRemoteURL   = NillForNSNull(parseSocialNetwork[@"avatarRemoteURL"]);
        socialNetwork.profile.name              = NillForNSNull(parseSocialNetwork[@"displayName"]);
        socialNetwork.profile.profileURL        = NillForNSNull(parseSocialNetwork[@"profileURL"]);
        socialNetwork.displayName               = socialNetwork.profile.name;
        
        if (!tokenValid)
        {
            socialNetwork.activeState = @NO;
        }
        else
        {
//          [socialNetwork refreshGroups];
            [socialNetwork getFriends];
            [socialNetwork updateProfileInfo];
        }
        
        NSError *error = nil;
        [_managedObjectContext save:&error];
        
        //[self updateSocialNetworkOnParse];
        
        NSAssert(!error, @"%@", error);
    }
}

- (BOOL)activeSocialNetworkOfType:(SocialNetworkType)networkType
{
    NSString *stateKey = [NSString stringWithFormat:@"SocialNetworkForType_%d_AvailabilityStatus", networkType];
    NSNumber *key = [[NSUserDefaults standardUserDefaults] valueForKey:stateKey];
    
    return key ? key.boolValue : YES;
}

- (void)setSocialNetworkOfType:(SocialNetworkType)networkType active:(BOOL)active
{
    NSString *stateKey = [NSString stringWithFormat:@"SocialNetworkForType_%d_AvailabilityStatus", networkType];
    
    [[NSUserDefaults standardUserDefaults] setBool:active forKey:stateKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - remove

-(void)removeSearchedPosts
{
    if(self.isSearchProduced)
    {
        NSArray *fetchedObjects;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isSearchedPost == 1"];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post" inManagedObjectContext:self.managedObjectContext];
        request.entity = entity;
        request.predicate = predicate;
        
        NSError *error;
        fetchedObjects = [self.managedObjectContext executeFetchRequest:request error:&error];
        if (error)
        {
            DLog(@"Fetched error: %@",[error localizedDescription]);
        }
        
        for( NSManagedObject *object in fetchedObjects )
        {
            [_managedObjectContext deleteObject:object];
        }
        [self save];
        self.isSearchProduced = NO;
    }
}

-(void)removeOldPosts
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Post class])];
    request.predicate = [NSPredicate predicateWithFormat:@"time < %@", [[NSDate date] dateByAddingTimeInterval:-1*3600*24*3]];
    request.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES] ];
    NSError *requestError = nil;
    NSArray *posts = [self.managedObjectContext executeFetchRequest:request error:&requestError];
    if (requestError)
    {
        DLog(@"Can't get list of old posts because of %@", requestError.localizedDescription);
        return;
    }
    
    for (Post *post in posts)
    {
        if (post.subscribedBy.posts.count < 2 || post.group.posts.count < 2 || post.type.integerValue == kPostTypeEvent ||
            ([post isKindOfClass:[GooglePlusPost class]] && post.author.posts.count < 2))
        {
            continue;
        }
        
        [self.managedObjectContext deleteObject:post];
    }
}

- (void)removeSocialNetwork:(SocialNetwork *)socialNetwork
{
    [self removePostsSubscibedBySocialNetwork:socialNetwork];
    [self.managedObjectContext deleteObject:socialNetwork];
    [self save];
}

- (void)removePostsSubscibedBySocialNetwork:(SocialNetwork *)socialNetwork
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.subscribedBy.userID like[cd] %@", socialNetwork.profile.userID];
    NSString *postEntityName = NSStringFromClass([Post class]);
    
    NSArray *posts = [self fetchObjectsWithEntityName:postEntityName withPredicate:predicate sortDescriptors:nil];
    
    for (Post *post in posts)
    {
        [self.managedObjectContext deleteObject:post];
    }
    
    [self save];
}

- (NSArray *)fetchAllFriends
{
    NSMutableArray *allFriends = [[NSMutableArray alloc] init];
    for (SocialNetwork *sn in [self fetchAllSocialNetworks])
    {
        NSArray *friends = [self fetchFriendsForSocialNetwork:sn];
        if (friends)
        {
            [allFriends addObjectsFromArray:friends];
        }
    }
    return [allFriends copy];
}

- (NSArray *)fetchFriendsForSocialNetwork:(SocialNetwork *)socialNetwork
{
    NSArray *friends;
    
    if ([socialNetwork isKindOfClass:[FacebookSN class]])
    {
        FaceBookProfile *profile = (FaceBookProfile *)socialNetwork.profile;
        friends = [profile.friends allObjects];
    }
    else if ([socialNetwork isKindOfClass:[GooglePlusSN class]])
    {
        GooglePlusProfile *profile = (GooglePlusProfile *)socialNetwork.profile;
        friends = [profile.friends allObjects];
    }
    else if ([socialNetwork isKindOfClass:[LinkedinSN class]])
    {
        LinkedinProfile *profile = (LinkedinProfile *)socialNetwork.profile;
        friends = [profile.friends allObjects];
    }
    else if ([socialNetwork isKindOfClass:[FoursquareSN class]])
    {
        FoursqaureProfile *profile = (FoursqaureProfile *)socialNetwork.profile;
        friends = [profile.friends allObjects];
    }
    else if ([socialNetwork isKindOfClass:[InstagramSN class]])
    {
        InstagramProfile *profile = (InstagramProfile *)socialNetwork.profile;
        friends = [profile.friends allObjects];
    }
    else if ([socialNetwork isKindOfClass:[TwitterSN class]])
    {
        TwitterProfile *profile = (TwitterProfile *)socialNetwork.profile;
        friends = [profile.following allObjects];
    }
    
    return friends;
}

#pragma mark - Get events

- (NSArray *)fetchEventsForSocialNetwork:(SocialNetwork *)socialNetwork
{
    NSArray *events;
    
    NSString *eventsEntityName = NSStringFromClass([Post class]);
    NSPredicate *eventsPredicate = [NSPredicate predicateWithFormat:@"SELF.subscribedBy.userID LIKE[cd] %@ AND SELF.type == %@", socialNetwork.profile.userID, @(kPostTypeEvent)];
    NSSortDescriptor *sortByDateDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"time" ascending:NO];
    
    events = [self fetchObjectsWithEntityName:eventsEntityName
                                withPredicate:eventsPredicate
                              sortDescriptors:@[sortByDateDescriptor]];
    return events;
}

#pragma mark - Static fields

- (BOOL)isSearchProduced
{
    return _isSearchProduced;
}

- (void)setIsSearchProduced:(BOOL)isSearchProduced
{
    _isSearchProduced = isSearchProduced;
}

@end