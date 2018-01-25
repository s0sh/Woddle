//
//  WDDDataBase.h
//  Woddl
//
//  Created by Sergii Gordiienko on 29.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SocialNetwork.h"

typedef void (^ComplateBlockWithSuccess)(BOOL success);

@protocol SocialNetworkUpdatedDelegate <NSObject>

- (void)needUpdateAccessTokenForNetworkWithType:(SocialNetworkType)networkType
                                         userId:(NSString *)userId
                                    displayName:(NSString *)displayName
                                complitionBlock:(void(^)(SocialNetworkType socialNetwork, NSString *accessToken, NSDate *expirationDate))complitionBlock;

@end

@interface WDDDataBase : NSObject

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, assign) BOOL isSearchProduced;
@property (nonatomic, assign, getter = isUpdatingStatus) BOOL updatingStatus;

+ (void)initializeWithCallBack:(ComplateBlockWithSuccess)complete;
+ (WDDDataBase *)sharedDatabase;
+ (BOOL)isConnectedToDB;
- (void)disconnectDatabase;

+ (NSManagedObjectContext *)masterObjectContext;

//  General
- (NSArray *)fetchObjectsWithEntityName:(NSString *)entity withPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;
- (BOOL)saveChangesToContext:(NSError **)errorRef;

//  Social networks
- (NSArray *)fetchAllSocialNetworks;
- (NSArray *)fetchSocialNetworksWithAccessToken:(NSString *)token;
- (NSArray *)fetchSocialNetworksWithAccessTokenPrefix:(NSString *)token;
- (NSArray *)fetchSocialNetworksWithAccessProfileUserID:(NSString *)userID;
- (NSArray *)fetchSocialNetworksWithPredicate:(NSPredicate *)predicate;
- (NSArray *)fetchSocialNetworksAscendingWithType:(SocialNetworkType)type;
-(void)addNewSocialNetworkWithType:(SocialNetworkType)type
                         andUserID:(NSString*)userID
                          andToken:(NSString*)token
                    andDisplayName:(NSString*)displayName
                       andImageURL:(NSString*)photo
                         andExpire:(NSDate*)expire
                      andFollowers:(NSArray*)followers
                     andProfileURL:(NSString *)profileURLString andGroups:(NSArray*)groups;

//common methodth
- (NSArray*)getItemsWithEntityName:(NSString*)entityName andPredicate:(NSPredicate*) predicate;
- (id)addNewItemWithEntityName:(NSString*)entityName;
- (void)save;

//  AvailableSocialNetworks based on bit shifting for SocialNetworkTags
- (NSInteger)availableSocialNetworks;
- (NSInteger)countAvailableSocialNetworks;

// parse integration
- (void)updateSocialNetworkFromParse:(PFObject*)parseSocialNetwork withDelegate:(id<SocialNetworkUpdatedDelegate>)delegate;

- (BOOL)activeSocialNetworkOfType:(SocialNetworkType)networkType;
- (void)setSocialNetworkOfType:(SocialNetworkType)networkType active:(BOOL)active;

//remove
- (void)removeSearchedPosts;
- (void)removeOldPosts;
- (void)removeSocialNetwork:(SocialNetwork *)socialNetwork;

//  get friends
- (NSArray *)fetchAllFriends;
- (NSArray *)fetchFriendsForSocialNetwork:(SocialNetwork *)socialNetwork;

//  get Events
- (NSArray *)fetchEventsForSocialNetwork:(SocialNetwork *)socialNetwork;

@end