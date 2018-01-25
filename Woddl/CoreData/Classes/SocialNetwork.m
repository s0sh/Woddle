//
//  SocialNetwork.m
//  Woddl
//
//  Created by Sergii Gordiienko on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "SocialNetwork.h"

#import <Parse/Parse.h>

#import "WDDDataBase.h"
#import "NetworkRequest.h"
#import "Post.h"
#import "Tag.h"
#import "Comment.h"
#import "Place.h"
#import "Link.h"
#import "FacebookPictures.h"

#import "NSManagedObject+setValuesFromDataDictionary.h"

static NSDictionary *static_syncResources;


@implementation SocialNetwork

@dynamic accessToken;
@dynamic activeState;
@dynamic displayName;
@dynamic type;
@dynamic profile;
@dynamic exspireTokenTime;
@dynamic groups;
@dynamic notifications;
@dynamic isEventsEnabled;
@dynamic isGroupsEnabled;
@dynamic isPagesEnabled;
@dynamic updatedAt;

#pragma mark - Class queue singletones and methods

- (void)willSave
{
    NSDate *now = [NSDate date];
    
    if (self.updatedAt == nil || [now timeIntervalSinceDate:self.updatedAt] > 1.0)
    {
        self.updatedAt = now;
    }
}

+ (dispatch_queue_t)networkQueue
{
    NSAssert([self class] != [SocialNetwork class], @"SocialNetwork class is abstract and have to be subclassed!");
    
    NSMutableDictionary *queueNames = [SocialNetwork queueNames];
    NSString *queueKey = [NSStringFromClass([self class]) stringByAppendingString:@".networkQueue"];
    
    if (!queueNames[queueKey])
    {
        queueNames[queueKey] = dispatch_queue_create([[queueKey stringByAppendingString:@".networkQueue"] UTF8String],
                                                     DISPATCH_QUEUE_CONCURRENT);
    }
    
    return queueNames[queueKey];
}

+ (NSOperationQueue *)operationQueue
{
    NSAssert([self class] != [SocialNetwork class], @"SocialNetwork class is abstract and have to be subclassed!");
    
    NSMutableDictionary *operationQueues = [SocialNetwork operationQueues];
    NSString *queueKey = [NSStringFromClass([self class]) stringByAppendingString:@".operationQueue"];
    
    if (!operationQueues[queueKey])
    {
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        operationQueue.maxConcurrentOperationCount = 2;
        operationQueues[queueKey] = operationQueue;
    }
    
    return operationQueues[queueKey];
}

+ (AFHTTPClient *)socialNetworkHTTPClient
{
    NSAssert([self class] != [SocialNetwork class], @"SocialNetwork class is abstract and have to be subclassed!");
    
    NSMutableDictionary *httpClients = [SocialNetwork httpClients];
    NSString *clientKey = [NSStringFromClass([self class]) stringByAppendingString:@".httpClient"];
    
    if (!httpClients[clientKey])
    {
        AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[[self class] baseURL]]];
        httpClients[clientKey] = httpClient;
    }
    
    return httpClients[clientKey];
}

+ (NSMutableDictionary *)queueNames
{
    static NSMutableDictionary *queueNames;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queueNames = [[NSMutableDictionary alloc] init];
    });
    return queueNames;
}

+ (NSMutableDictionary *)operationQueues
{
    static NSMutableDictionary *operationQueues;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        operationQueues = [[NSMutableDictionary alloc] init];
    });
    return operationQueues;
}

+ (NSMutableDictionary *)httpClients
{
    static NSMutableDictionary *httpClients;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        httpClients = [[NSMutableDictionary alloc] init];
    });
    return httpClients;
}

#pragma mark - Instance methods

- (NSDictionary *)syncResources
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        static_syncResources = @{
                                 @(kSocialNetworkFacebook) : [NSObject new],
                                 @(kSocialNetworkTwitter) : [NSObject new],
                                 @(kSocialNetworkLinkedIN) : [NSObject new],
                                 @(kSocialNetworkGooglePlus) : [NSObject new],
                                 @(kSocialNetworkInstagram) : [NSObject new],
                                 @(kSocialNetworkFoursquare) : [NSObject new]
                                };
    });
    
    return static_syncResources;
}

- (NSString *)socialNetworkIconName
{
    NSAssert(![self isKindOfClass:[Post class]], @"This is abstract class. Method should be overloaded by subclass");
    return nil;
}

- (void)setTypeWith:(SocialNetworkType)type
{
    self.type = @(type);
}

- (SocialNetworkType)socialNetworkType
{
    return self.type.integerValue;
}

- (void)setExspireTokenTimeWithExpireTimeInterval:(NSTimeInterval)timeInterval
{
    NSDate *expireDate = [NSDate dateWithTimeIntervalSinceNow:timeInterval];
    self.exspireTokenTime = expireDate;
}

- (void)getPosts
{
    NSAssert([self class] == [SocialNetwork class], @"SocialNetwork class is abstract and have to be subclassed!");
}
- (void)getPostsWithCompletionBlock:(ComplationGetPostBlock)completionBlock
{
    NSAssert([self class] == [SocialNetwork class], @"SocialNetwork class is abstract and have to be subclassed!");
}

- (void)getPostsFrom:(NSString*)from to:(NSString*)to isSelfPosts:(BOOL)isSelf
{
    NSAssert([self class] == [SocialNetwork class], @"SocialNetwork class is abstract and have to be subclassed!");
}

- (void)saveNotificationsToDataBase:(NSArray*)notifications
{
    if (!notifications.count) return;
    
    NSObject *syncObject = self.syncResources[self.type];
    
    @synchronized(syncObject)
    {
        NSManagedObjectContext * context = [WDDDataBase sharedDatabase].managedObjectContext;
        
        [notifications enumerateObjectsUsingBlock:^(NSDictionary *notificationDictionary, NSUInteger idx, BOOL *stop)
        {
            if (![notificationDictionary[@"title"] length] || !notificationDictionary[@"senderId"])
            {
                return;
            }
            
            NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Notification class])];
            fr.predicate = [NSPredicate predicateWithFormat:@"notificationId == %@ AND socialNetwork == %@",
                            notificationDictionary[@"notificationId"],
                            self];
            fr.fetchLimit = 1;
            
            Notification *note = [[context executeFetchRequest:fr error:nil] firstObject];
            
            if (![[note notificationId] isEqualToString:notificationDictionary[@"notificationId"]])
            {
                note = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Notification class])
                                                     inManagedObjectContext:context];
            }
            else
            {
                return;
            }
            
            [note setValuesForKeysWithDictionary:notificationDictionary];
            
            note.socialNetwork = self;

            NSString *objectType = note.externalObjectType;
            
            if ([objectType isEqualToString:@"group"] || [objectType isEqualToString:@"page"])
            {
                NSFetchRequest *groupsFr = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Group class])];
                groupsFr.predicate = [NSPredicate predicateWithFormat:@"groupID == %@", note.externalObjectId];
                groupsFr.fetchLimit = 1;
                note.group = [[context executeFetchRequest:groupsFr error:nil] firstObject];
            }
            if ([objectType isEqualToString:@"stream"])
            {
                NSFetchRequest *postsFr = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Post class])];
                postsFr.predicate = [NSPredicate predicateWithFormat:@"postID == %@", [[note.externalObjectId componentsSeparatedByString:@"_"] lastObject]];
                postsFr.fetchLimit = 1;
                note.post = [[context executeFetchRequest:postsFr error:nil] firstObject];
            }
            if ([objectType isEqualToString:@"photo"])
            {
                NSFetchRequest *mediaFr = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Media class])];
                mediaFr.predicate = [NSPredicate predicateWithFormat:@"mediaObjectId == %@", note.externalObjectId];
                mediaFr.fetchLimit = 1;
                note.media = [[context executeFetchRequest:mediaFr error:nil] firstObject];
            }
            
            NSFetchRequest *usersFr = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(self.profile.class)];
            usersFr.predicate = [NSPredicate predicateWithFormat:@"userID == %@", note.senderId, self.type];
            usersFr.fetchLimit = 1;
            note.sender = [[context executeFetchRequest:usersFr error:nil] firstObject];
        }];
        
        [[WDDDataBase sharedDatabase] save];
    }
}

- (void)savePostsToDataBase:(NSArray *)posts
{
    NSObject *syncObject = self.syncResources[self.type];
    
    @synchronized(syncObject)

    {
        // Remove old events to don't show events that ended.
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Post class])];
        request.predicate = [NSPredicate predicateWithFormat:@"SELF.subscribedBy.userID LIKE[cd] %@ AND SELF.type == %@", self.profile.userID, @(kPostTypeEvent)];
        
        NSArray *events = [self.managedObjectContext executeFetchRequest:request error:nil];
        for (Post *post in events)
        {
            [self.managedObjectContext deleteObject:post];
        }
        
        for(NSDictionary* postDict in posts)
        {
            NSArray* postsWithID = [[NSArray alloc] init];
            Post *post = nil;
            NSString* postID = [postDict objectForKey:kPostIDDictKey];
    //        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"postID like %@ AND self.subscribedBy.userID like %@", postID,self.profile.userID];
            NSFetchRequest *request  = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([self postClass])];
            request.predicate = [NSPredicate predicateWithFormat:@"postID like %@ AND self.subscribedBy.socialNetwork.type == %@", postID, self.type];
            
            postsWithID = [self.managedObjectContext executeFetchRequest:request error:nil];
            if(postsWithID.count==0)
            {
                NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([self postClass]) inManagedObjectContext:self.managedObjectContext];
                post = (Post *)[[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
            }
            else
            {
                post = [postsWithID lastObject];
            }
            [post setValuesFromDataDictionary:postDict];
            post.updateTime = [NSDate date];
            
            //  Assing post with Group
            if(postDict[kPostGroupType])
            {
                NSString* groupID = postDict[kPostGroupID];
                NSNumber *type = (([postDict[kPostGroupType] integerValue] == kGroupTypeGroup) ? @(kGroupTypeGroup) : @(kGroupTypePage));
                NSPredicate *groupPredicate = [NSPredicate predicateWithFormat:@"SELF.groupID LIKE[cd] %@ AND SELF.type == %@", groupID, type];                
                NSSet *groups = [self.groups filteredSetUsingPredicate:groupPredicate];
                for (Group* group in groups)
                {
                    post.group = group;
                }
            }
            
            //  Get post's author information
            UserProfile *authorProfile = nil;
            if ([postDict objectForKey:kPostAuthorDictKey])
            {
                NSDictionary* authorDict = [postDict objectForKey:kPostAuthorDictKey];            
                NSString *authorId = [authorDict objectForKey:kPostAuthorIDDictKey];
                
                NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([UserProfile class])];
                request.predicate = [NSPredicate predicateWithFormat:@"userID == %@", authorId];
                authorProfile = [self.managedObjectContext executeFetchRequest:request error:nil].lastObject;
//                authorProfile = [[WDDDataBase sharedDatabase] fetchObjectsWithEntityName:NSStringFromClass([UserProfile class])
//                                                                           withPredicate:[NSPredicate predicateWithFormat:@"userID == %@", authorId]
//                                                                         sortDescriptors:nil].lastObject;
                if (!authorProfile)
                {
                    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([UserProfile class]) inManagedObjectContext:self.managedObjectContext];
                    authorProfile = (UserProfile *)[[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
//                    authorProfile = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([UserProfile class])];
                    authorProfile.userID = authorId;
                }
                
                [authorProfile setValuesFromDataDictionary:authorDict];
            }
            post.author = authorProfile;
            post.subscribedBy = self.profile;
            
            [self setMediaFromPostInfo:postDict toPost:post]; //I comment
            [self setCommentsFromPostInfo:postDict toPost:post];
            [self setTagsFromPostInfo:postDict toPost:post];
            [self setPlacesFromPostInfo:postDict toPost:post];
            [self updateLinksForPost:post];
        }
      
        NSError *error = nil;
        DLog(@"Will save posts for %@ %@", NSStringFromClass([self class]), self.profile.name);
        [self.managedObjectContext save:&error];
        
        if (error)
        {
            DLog(@"Can't save posts for %@ %@ because of: %@", NSStringFromClass([self class]), self.profile.name, error);
        }
        else
        {
            DLog(@"Posts for %@ %@ saved", NSStringFromClass([self class]), self.profile.name);
        }
    }
//    [[WDDDataBase sharedDatabase] save];
}

/*
#define POST_MEDIA_NEVER_GET_UPDATED
    This define assumes that post media never get updated - so if post already has some media
    we never update it or add some to post.
    The logic would be:
    1) check media count in post info and compare it with actual post media count
    2) if media count differs from actual post media count then replace
    post media with media from post info
    3) otherwise do nothing
 
    To return to old logic comment #define POST_MEDIA_NEVER_GET_UPDATED out
*/

#define POST_MEDIA_NEVER_GET_UPDATED

- (void)setMediaFromPostInfo:(NSDictionary *)postInfo toPost:(Post *)post
{
    NSArray *mediaList = postInfo[kPostMediaSetDictKey];

#warning Used new logic that assumes post never udpates their media. Read explanation above
    
#ifdef POST_MEDIA_NEVER_GET_UPDATED
    if (mediaList.count == post.media.count) return;
    [post removeMedia:post.media];
#endif
    
    [mediaList enumerateObjectsUsingBlock:^(NSDictionary *mediaDict, NSUInteger idx, BOOL *stop)
    {
        NSString* url = nil;
        
        if([mediaDict objectForKey:kPostMediaURLDictKey])
        {
            url = [mediaDict objectForKey:kPostMediaURLDictKey];
        }
        else
        {
            url = [mediaDict objectForKey:kPostMediaPreviewDictKey];
        }
        NSString* typeStr = [mediaDict objectForKey:kPostMediaTypeDictKey];
        NSNumber* type = [NSNumber numberWithInt:kMediaUnknown];
        Media* media = nil;
        
#ifndef POST_MEDIA_NEVER_GET_UPDATED
        NSPredicate *predicate;
        if (mediaDict[kPostMediaPreviewDictKey] && mediaDict[kPostMediaURLDictKey])
        {
            predicate = [NSPredicate predicateWithFormat:@"mediaURLString like %@ OR previewURLString like %@", mediaDict[kPostMediaURLDictKey], mediaDict[kPostMediaPreviewDictKey]];
        }
        else if (mediaDict[kPostMediaURLDictKey])
        {
            predicate = [NSPredicate predicateWithFormat:@"mediaURLString like %@", mediaDict[kPostMediaURLDictKey]];
        }
        else if (mediaDict[kPostMediaPreviewDictKey])
        {
            predicate = [NSPredicate predicateWithFormat:@"previewURLString like %@", mediaDict[@"previewURLString"]];
        }
        
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Media class])];
        request.predicate = predicate;
        NSArray *mediaEntityArray = [post.managedObjectContext executeFetchRequest:request error:nil];
        media = [mediaEntityArray lastObject];
        if(mediaEntityArray.count==0)
        {
#endif
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([Media class]) inManagedObjectContext:post.managedObjectContext];
            media = (Media *)[[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:post.managedObjectContext];
            if([typeStr isEqualToString:@"image"])
            {
                type = [NSNumber numberWithInt:kMediaPhoto];
            }
            else if([typeStr isEqualToString:@"video"])
            {
                type = [NSNumber numberWithInt:kMediaVideo];
            }

            media.type = type;
#ifndef POST_MEDIA_NEVER_GET_UPDATED
        }
#endif
        
        media.mediaURLString = mediaDict[kPostMediaURLDictKey];
        media.previewURLString = mediaDict[kPostMediaPreviewDictKey];        
        
        [post addMediaObject:media];
    }];
}

- (void)setTagsFromPostInfo:(NSDictionary *)postInfo toPost:(Post *)post
{
    for (NSString *tagString in [postInfo objectForKey:kPostTagsListKey])
    {
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"tag == %@", tagString];
  
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Tag class])];
        request.predicate = [NSPredicate predicateWithFormat:@"tag == %@", tagString];
        NSArray *tags = [post.managedObjectContext executeFetchRequest:request error:nil];
//        NSArray *tags = [[WDDDataBase sharedDatabase] getItemsWithEntityName:NSStringFromClass([Tag class]) andPredicate:predicate];
        Tag *tag = nil;
        if (!tags.count)
        {
//            tag = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([Tag class])];
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([Tag class]) inManagedObjectContext:post.managedObjectContext];
            tag = (Tag *)[[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:post.managedObjectContext];
            tag.tag = tagString;
        }
        else
        {
            tag = tags.lastObject;
        }
        
        if ([post respondsToSelector:@selector(addTagsObject:)])
        {
            [post addTagsObject:tag];
        }
    }
}

- (void)setPlacesFromPostInfo:(NSDictionary *)postInfo toPost:(Post *)post
{
    for (NSDictionary *placeInfo in [postInfo objectForKey:kPostPlacesListKey])
    {
        NSString *placeId = [placeInfo objectForKey:kPlaceIdDictKey];
//        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"placeId == %@ && networkType == %@", placeId, self.type];
//        
//        NSArray *places = [[WDDDataBase sharedDatabase] getItemsWithEntityName:NSStringFromClass([Place class]) andPredicate:predicate];
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Place class])];
        request.predicate = [NSPredicate predicateWithFormat:@"placeId == %@ && networkType == %@", placeId, self.type];
        NSArray *places = [post.managedObjectContext executeFetchRequest:request error:nil];
        Place *place = places.lastObject;
        if (!place)
        {
//            place = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([Place class])];
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([Place class]) inManagedObjectContext:post.managedObjectContext];
            place = (Place *)[[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:post.managedObjectContext];
            place.placeId = placeId;
            place.networkType = self.type;
        }
        
        [place setValuesFromDataDictionary:placeInfo];
        
        [post addPlacesObject:place];
    }
}

- (void)setCommentsFromPostInfo:(NSDictionary *)postInfo toPost:(Post *)post
{
    for(NSDictionary* commentDict in [postInfo objectForKey:kPostCommentsDictKey])
    {
        NSString* commentID = [commentDict objectForKey:kPostCommentIDDictKey];
        NSArray * commentsArray = nil;
        Comment* comment;
        
        if (!commentID)
        {
            DLog(@"Got null comment ID in comment: %@", commentDict);
            continue;
        }

        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Comment class])];
        request.predicate = [NSPredicate predicateWithFormat:@"commentID contains[cd] %@", commentID];
        commentsArray = [post.managedObjectContext executeFetchRequest:request error:nil];
        if(commentsArray.count==0)
        {
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([Comment class]) inManagedObjectContext:post.managedObjectContext];
            comment = (Comment *)[[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:post.managedObjectContext];
        }
        else
        {
            comment = [commentsArray lastObject];
        }
        
        comment.date = [commentDict objectForKey:kPostCommentDateDictKey];
        comment.text = [commentDict objectForKey:kPostCommentTextDictKey];
        comment.commentID = commentID;
        
        
        [self setTagsFromPostInfo:commentDict toPost:comment];
        
        if ([commentDict objectForKey:kPostCommentLikesCountDictKey])
            comment.likesCount = [commentDict objectForKey:kPostCommentLikesCountDictKey];
        
        UserProfile *authorPostProfile = nil;
        NSDictionary* authorCommentDict = [commentDict objectForKey:kPostCommentAuthorDictKey];
        NSString *authorId = [authorCommentDict objectForKey:kPostCommentAuthorIDDictKey];
        if (authorId)
        {
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([UserProfile class])];
            request.predicate = [NSPredicate predicateWithFormat:@"userID == %@", authorId];
            authorPostProfile = [post.managedObjectContext executeFetchRequest:request error:nil].lastObject;
            
            if (!authorPostProfile)
            {
                NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([UserProfile class]) inManagedObjectContext:post.managedObjectContext];
                authorPostProfile = (UserProfile *)[[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:post.managedObjectContext];
                authorPostProfile.userID = authorId;
            }
            
            authorPostProfile.name = [authorCommentDict objectForKey:kPostCommentAuthorNameDictKey];
            authorPostProfile.userID = [authorCommentDict objectForKey:kPostCommentAuthorIDDictKey];
            authorPostProfile.profileURL = authorCommentDict[kPostAuthorProfileURLDictKey];
            authorPostProfile.avatarRemoteURL = [authorCommentDict objectForKey:kPostCommentAuthorAvaURLDictKey];
        }
        comment.author = authorPostProfile;
        
        if(commentsArray.count==0)
        {
            [post addCommentsObject:comment];
        }
    }
}

- (void)updateLinksForPost:(Post *)post
{
    NSArray *links = [self linksForText:post.text];
    if (post.links.count)
    {
        [post removeLinks:post.links];
    }
    
    for (NSString *link in links)
    {
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([Link class]) inManagedObjectContext:post.managedObjectContext];
        Link *linkObj = (Link *)[[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:post.managedObjectContext];
        
//        Link *linkObj = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([Link class])];
        linkObj.url = link;
        linkObj.post = post;
    }
}

- (void)result:(NSDictionary *)postInfo toPost:(Post *)post
{
    for(NSDictionary* mediaDict in [postInfo objectForKey:kPostMediaSetDictKey])
    {
        NSString* url = nil;
        if([mediaDict objectForKey:kPostMediaURLDictKey])
        {
            url = [mediaDict objectForKey:kPostMediaURLDictKey];
        }
        else
        {
            url = [mediaDict objectForKey:kPostMediaPreviewDictKey];
        }
        NSString* typeStr = [mediaDict objectForKey:kPostMediaTypeDictKey];
        NSNumber* type = [NSNumber numberWithInt:kMediaUnknown];
        Media* media = nil;
        
        NSPredicate *predicate;
        if(!url)
        {
            continue;
        }
        if([mediaDict objectForKey:kPostMediaPreviewDictKey])
        {
            predicate = [NSPredicate predicateWithFormat:@"(mediaURLString like %@ OR previewURLString like %@) AND self.post.subscribedBy.userID CONTAINS %@", url,[mediaDict objectForKey:kPostMediaPreviewDictKey],post.subscribedBy.userID];
        }
        else
        {
            predicate = [NSPredicate predicateWithFormat:@"mediaURLString like %@", url];
        }
        NSArray *mediaEntityArray = [[WDDDataBase sharedDatabase] getItemsWithEntityName:NSStringFromClass([Media class]) andPredicate:predicate];
        media = [mediaEntityArray lastObject];
        if(mediaEntityArray.count==0)
        {
            media = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([Media class])];
            media.mediaURLString = url;
            media.previewURLString = mediaDict[kPostMediaPreviewDictKey];
            if([typeStr isEqualToString:@"image"])
            {
                type = [NSNumber numberWithInt:kMediaPhoto];
            }
            else if([typeStr isEqualToString:@"video"])
            {
                type = [NSNumber numberWithInt:kMediaVideo];
            }
            media.type = type;
            
        }
        
        [post addMediaObject:media];
        [media addPostObject:post];
    }
}

- (void)postToWallWithMessage:(NSString *)message andPost:(Post *)post withCompletionBlock:(ComplationPostBlock)completionBlock
{
    [self postToWallWithMessage:message post:post toGroup:nil withCompletionBlock:completionBlock];
}

- (void)postToWallWithMessage:(NSString *)message
                         post:(Post *)post
                      toGroup:(Group *)group
          withCompletionBlock:(ComplationPostBlock)completionBlock
{
    NSAssert([self isKindOfClass:[SocialNetwork class] ], @"SocialNetwork class is abstract and have to be subclassed!");
}

- (void)addStatusWithMessage:(NSString *)message andImages:(NSArray *)images andLocation:(WDDLocation *)location withCompletionBlock:(completionAddStatusBlock)completionBlock
{
    NSAssert([self class] == [SocialNetwork class], @"SocialNetwork class is abstract and have to be subclassed!");
}

- (void)addStatusWithMessage:(NSString *)message andImages:(NSArray *)images andLocation:(WDDLocation *)location toGroup:(Group *)group withCompletionBlock:(completionAddStatusBlock)completionBlock;
{
    NSAssert([self class] == [SocialNetwork class], @"SocialNetwork class is abstract and have to be subclassed!");
}

#pragma mark - SocialNetwork protocol methods
+ (NSString *)baseURL
{
    NSAssert([self class] == [SocialNetwork class], @"SocialNetwork class is abstract and have to be subclassed!");
    return nil;
}

#pragma mark - parse integration

#define NSNullForNil(__value__) ( ((__value__) == nil) ? [NSNull null] : (__value__) )

- (void)updateSocialNetworkOnParseNow:(BOOL)now
{
    PFQuery  *query = [PFQuery queryWithClassName:NSStringFromClass([SocialNetwork class])];
    query.limit = 1;
    [query whereKey:@"userOwner" equalTo:[PFUser currentUser]];
    [query whereKey:@"networkUserId" equalTo:self.profile.userID];
    
    NSString *accessToken   = self.accessToken;
    NSNumber *type          = self.type;
    NSNumber *activeState   = self.activeState;
    NSString *networkUserId = self.profile.userID;
    NSDate   *tokenExpire   = self.exspireTokenTime;
    NSString *avatarURL     = self.profile.avatarRemoteURL;
    NSString *displayName   = self.profile.name;
    NSString *profileURL    = self.profile.profileURL;
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error)
         {
             PFObject *socialNetworkOnParse = nil;
             if (objects.count)
             {
                 NSAssert(objects.count == 1, @"Accidentaly there are more than one social network with same userId for same user. How could that happen?");
                 socialNetworkOnParse = objects[0];
             }
             else
             {
                 socialNetworkOnParse = [PFObject objectWithClassName:NSStringFromClass([SocialNetwork class])];
             }
             
             socialNetworkOnParse[@"accessToken"]        = NSNullForNil(accessToken);
             socialNetworkOnParse[@"type"]               = NSNullForNil(type);
             socialNetworkOnParse[@"activeState"]        = NSNullForNil(activeState);
             socialNetworkOnParse[@"networkUserId"]      = NSNullForNil(networkUserId);
             socialNetworkOnParse[@"userOwner"]          = [PFUser currentUser];
             socialNetworkOnParse[@"displayName"]        = NSNullForNil(displayName);
             socialNetworkOnParse[@"profileURL"]         = NSNullForNil(profileURL);
             socialNetworkOnParse[@"creatorVersion"]     = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
             
             if (activeState.boolValue)
             {
                 socialNetworkOnParse[@"tokenInvalidated"] = @NO;
             }
             
             if(tokenExpire)
             {
                 socialNetworkOnParse[@"expireTokenTime"]    = NSNullForNil(tokenExpire);
             }
             if(avatarURL)
             {
                 socialNetworkOnParse[@"avatarRemoteURL"]    = NSNullForNil(avatarURL);
             }
             
             if (!now)
             {
                 [socialNetworkOnParse saveEventually];
             }
             else
             {
                 NSError *error = nil;
                 [socialNetworkOnParse save:&error];
                 
                 if (error)
                 {
                     DLog(@"Can't save social network info: %@", error.localizedDescription);
                 }
             }
         }
     }];
}

- (void)updateSocialNetworkOnParse
{
    [self updateSocialNetworkOnParseNow:NO];
}

- (void)refreshGroups
{
    
}

- (void)updateProfileInfo
{    
}

- (void)getFriends
{
    
}

- (void)loadMoreGroupsPostsWithGroupID:(NSString *)groupID from:(NSString *)from to:(NSString *)to
{
    DLog(@"method loadMoreGroupsPostsWithGroupID:from:to: of class %@ should be implemented in subclass", [self class]);
    abort();
}

- (NSArray *)getSavedEvents
{
    return [[WDDDataBase sharedDatabase] fetchEventsForSocialNetwork:self];
}

- (NSArray *)linksForText:(NSString *)text
{
    NSMutableArray *links = nil;
    
    if (text && text.length)
    {
        NSDataDetector *dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink
                                                                       error:nil];
        links = [NSMutableArray new];
        
        [dataDetector enumerateMatchesInString:text
                                       options:NSMatchingReportCompletion
                                         range:NSMakeRange(0, text.length)
                                    usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                        
                                        if (result.resultType == NSTextCheckingTypeLink)
                                        {
                                            [links addObject:[text substringWithRange:result.range]];
                                        }
                                    }];
    }
    
    return links;
}

#pragma mark - Search posts
- (void)searchPostsWithText:(NSString *)searchText
{
    NSAssert([self class] == [SocialNetwork class], @"SocialNetwork class is abstract and have to be subclassed!");
}

- (void)searchPostsWithText:(NSString *)searchText completionBlock:(completionSearchPostsBlock)comletionBlock
{
    NSAssert([self class] == [SocialNetwork class], @"SocialNetwork class is abstract and have to be subclassed!");
}

- (Class)postClass
{
    return [Post class];
}

@end