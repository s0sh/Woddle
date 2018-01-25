//
//  FacebookRequest.m
//  Woddl
//
//  Created by Александр Бородулин on 05.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookRequest.h"
#import "FacebookRequestGetPostOperation.h"
#import "FacebookRequestGetTopStoryPostOperation.h"
#import "LBYouTubeExtractor.h"
#import "Semaphor.h"
#import "Group.h"
#import "FaceBookPost.h"

#import "SocialNetwork.h"
#import "WDDDataBase.h"
#import "FaceBookProfile.h"
#import "FaceBookOthersProfile.h"
#import "FacebookGroupsInfo.h"

#import "WDDAppDelegate.h"

#import <YTVimeoExtractor/YTVimeoExtractor.h>
#import <uidevice-extension/UIDevice-Hardware.h>




static NSString * const kHighResolutionPhoto = @"source";
static NSString * const kLowResolutionPhoto = @"picture";
static NSString * const kFacebookHTTPSBaseURL = @"https://www.facebook.com";

static NSString * const kFeedFields = @"post_id,created_time,message,description,attachment,place,actor_id,comment_info,like_info,source_id,target_id";

@interface FacebookRequest ()
{
    NSDateFormatter* df;
}

@end

@implementation FacebookRequest

static NSString* const kSemaphoreKey = @"mySemaphore";
static CGFloat const kInternetIntervalTimeout = 30.0;
static NSInteger const kMaxCountOfCommentsrefresh = 10;
static NSInteger const kMaxCountOfPostsInUpdate = 50;

//static NSMutableArray * usersInfoArray = nil;

- (id)init
{
    self = [super init];
    if (self)
    {
        df = [[NSDateFormatter alloc] init];
        [df setTimeStyle:NSDateFormatterFullStyle];
        [df setFormatterBehavior:NSDateFormatterBehavior10_4];
        [df setDateFormat:@"yyyy-L-d HH:mm:ss Z"];
    }
    return self;
}

- (NSArray *)removeDuplicatedPostsFromArray:(NSArray *)array
{
    return nil;
}

- (BOOL)getPostsWithToken:(NSString*)token
                andUserID:(NSString*)userID
                 andCount:(NSUInteger)count
                andGroups:(NSArray*)groups
               startsFrom:(NSDate *)date
      withComplationBlock:(void (^)(NSArray *resultArray))completionBlock
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
#if FB_EVENTS_SUPPORT == ON
    NSString * const kEventFields = @"eid,name,pic_small,pic_big,description,start_time,end_time,location,creator,update_time,venue";
#endif
    
    if (!date)
    {
        date = [NSDate dateWithTimeIntervalSinceNow:-86400];
    }
    
#if FB_EVENTS_SUPPORT == ON
    // Events
    NSString *eventsRequestString = [NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT %@ FROM event WHERE eid IN (SELECT eid FROM event_member WHERE uid == me()) AND (end_time > now() OR end_time == 'null')&access_token=%@", kEventFields, token];
    eventsRequestString = [eventsRequestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURLRequest *eventsRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:eventsRequestString]];
    
    NSError *eventsError = nil; NSURLResponse *eventsResponse = nil;
    NSData *eventsData = [NSURLConnection sendSynchronousRequest:eventsRequest returningResponse:&eventsResponse error:&eventsError];
    if(eventsData)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:eventsData
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return NO;
            }
            
            NSMutableArray *events = [[NSMutableArray alloc] initWithCapacity:[json[@"data"] count]];
            
            for (NSDictionary *eventData in json[@"data"])
            {
                [events addObject:[self getEventWithDictionary:eventData]];
            }
            
            NSArray *processedEvents = [self addCreatorInfoToEvents:events
                                                           fromData:json[@"data"]
                                                        accessToken:token];
            [resultArray addObjectsFromArray:processedEvents];
        }
    }
#endif
    
#if FB_GROUPS_SUPPORT == ON
    NSMutableDictionary *gruopsTable = [[NSMutableDictionary alloc] initWithCapacity:groups.count];
    for (NSDictionary *groupInfo in groups)
    {
        [gruopsTable setObject:groupInfo forKey:groupInfo[@"groupId"]];
    }

    BOOL useOneByOneLoading = [(WDDAppDelegate *)[UIApplication sharedApplication].delegate loadFBGroupsOneByOne];
    
    // Groups
    NSDate *groupDate = date;
    if (gruopsTable.count)
    {
        NSArray *socialNetworks = [[WDDDataBase sharedDatabase] fetchObjectsWithEntityName:NSStringFromClass([SocialNetwork class])
                                                                             withPredicate:[NSPredicate predicateWithFormat:@"accessToken == %@", token]
                                                                           sortDescriptors:nil];
        if (socialNetworks.count)
        {
            SocialNetwork *socialNetwork = socialNetworks.firstObject;
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([FaceBookPost class])];
            request.predicate = [NSPredicate predicateWithFormat:@"group != nil AND subscribedBy.socialNetwork == %@", socialNetwork];
            request.fetchLimit = 1;
            NSArray *groupPosts = [[WDDDataBase sharedDatabase].managedObjectContext executeFetchRequest:request error:nil];
            
            if (!groupPosts.count)
            {
                groupDate = [NSDate dateWithTimeIntervalSinceNow:(useOneByOneLoading ? -21600 : -86400)];
            }
        }   // Hack to load actual gruops posts on second update.

        if (!useOneByOneLoading)
        {
            NSString *requestString = [NSString stringWithFormat: @"https://graph.facebook.com/fql?q=SELECT %@ FROM stream WHERE (source_id IN (SELECT gid FROM group_member WHERE uid = me()) OR source_id IN (SELECT page_id FROM page_fan WHERE uid = me())) AND created_time>%@&access_token=%@", kFeedFields, @((int)groupDate.timeIntervalSince1970), token];
            requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
            NSError *error = nil; NSURLResponse *response = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            if(data)
            {
                NSError* error = nil;
                NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:kNilOptions
                                                                       error:&error];
                if(!error)
                {
                    if (json[@"error"])
                    {
                        NSDictionary *errorDescription = json[@"error"];
                        DLog(@"Facebook response with error : %@", errorDescription);
                        
                        if ([errorDescription[@"code"] integerValue] == 190)
                        {
                            [self invalidateSocialNetworkWithToken:token];
                        }
                        
                        return NO;
                    }
                    
                    NSArray* postsData = [json objectForKey:@"data"];
                    for (NSDictionary *postData in postsData)
                    {
                        NSDictionary *groupInfo = [gruopsTable objectForKey:[NSString stringWithFormat:@"%@", postData[@"source_id"]]];
                        NSDictionary *processedData = [self getTopStoryPostWithDictionary:postData
                                                                         forGroupWithInfo:groupInfo
                                                                                 andToken:token];
                        if (processedData)
                        {
                            [resultArray addObject:processedData];
                        }
                    }
                }
            }
        }
        else
        {
//            dispatch_queue_t groupsQueue = dispatch_queue_create("FB groups loading", DISPATCH_QUEUE_CONCURRENT);
            NSOperationQueue *groupsQueue = [NSOperationQueue new];
            groupsQueue.maxConcurrentOperationCount = [[UIDevice currentDevice] cpuCount] * 3;
            dispatch_semaphore_t groupsLoadingSemaphore = dispatch_semaphore_create(0);
            
            __block NSInteger groupsToProcessCount = 0;
            
            
            [gruopsTable.allKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                NSBlockOperation *groupOperation = [NSBlockOperation blockOperationWithBlock:^{
                
//                dispatch_async(groupsQueue, ^{
                
                    ++groupsToProcessCount;
                    

                    NSString *requestString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/feed?since=%@&access_token=%@", obj, @((int)groupDate.timeIntervalSince1970), token];
                    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    
                    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
                    NSError *error = nil; NSURLResponse *response = nil;
                    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                    if(data)
                    {
                        NSError* error = nil;
                        NSDictionary* json = [NSJSONSerialization
                                              JSONObjectWithData:data
                                              options:kNilOptions
                                              error:&error];
                        if(!error)
                        {
                            if (json[@"error"])
                            {
                                NSDictionary *errorDescription = json[@"error"];
                                DLog(@"Facebook response with error : %@", errorDescription);
                                
                                if ([errorDescription[@"code"] integerValue] == 190)
                                {
                                    [self invalidateSocialNetworkWithToken:token];
                                }
                                
                                return;
                            }
                            
                            NSArray* postsData = [json objectForKey:@"data"];
                            NSMutableArray *groupPosts = [[NSMutableArray alloc] initWithCapacity:postsData.count];
                            for (NSDictionary *postData in postsData)
                            {
                                NSMutableDictionary *postInfo = [[self getPostWithDictionary:postData andToken:token] mutableCopy];
                                NSDictionary *groupInfo = [gruopsTable objectForKey:obj];
                                if (groupInfo)
                                {
                                    [postInfo s_setObject:groupInfo[@"groupId"] forKey:kPostGroupID];
                                    [postInfo s_setObject:groupInfo[@"name"] forKey:kPostGroupName];
                                    [postInfo s_setObject:groupInfo[@"type"] forKey:kPostGroupType];
                                }
                                if (postInfo)
                                {
                                    [groupPosts addObject:postInfo];
                                }
                            }
                            
                            if (groupPosts.count)
                            {
                                [resultArray addObjectsFromArray:groupPosts];
                            }
                        }
                    }
                    
                    if (!--groupsToProcessCount)
                    {
                        dispatch_semaphore_signal(groupsLoadingSemaphore);
                    }
//                });
                }];
                
                [groupsQueue addOperation:groupOperation];
                
            }];
            
            dispatch_semaphore_wait(groupsLoadingSemaphore, DISPATCH_TIME_FOREVER);
        }
    }
    
#endif
    
    // Facebook posts
    NSArray *postsData = [self loadPostFromDate:@((int)date.timeIntervalSince1970) withToken:token];
    
//    DLog(@"Got FB response:\n %@", postsData);
    
    for (NSDictionary *postData in postsData)
    {
        NSDictionary *processedData = [self getTopStoryPostWithDictionary:postData
                                                         forGroupWithInfo:nil
                                                                 andToken:token];
        if (processedData)
        {
            [resultArray addObject:processedData];
        }
    }
    
    if(resultArray.count > 0)
    {
        completionBlock(resultArray);
        
        return YES;
    }
    
    return NO;
}

- (void)getNotificationsWithToken:(NSString*)accessToken
                           userId:(NSString*)userId
                  completionBlock:(void (^)(NSDictionary *resultDictionary))completionBlock
                  completionQueue:(dispatch_queue_t)completionQueue
{
    void (^completionBlk)(NSDictionary *resultDictionary) = [completionBlock copy];
    
    NSString *notificationAttributes =    @"app_id,body_text,created_time,href,icon_url,is_hidden,is_unread,notification_id,object_id,object_type,recipient_id,sender_id,title_html,title_text";
    NSString *applicationAttributes = @"app_id";
    NSString *photoAttributes       = @"object_id, images";
    NSString *streamAttributes      = @"post_id,created_time,message,description,attachment,place,actor_id,comment_info,like_info,source_id,target_id";
    NSString *groupAttributes       = @"description,icon68,gid,name,pic,pic_big,pic_cover,website";
    NSString *pageAttributes        = @"page_id,name,page_url,pic,pic_big,pic_cover";
    NSString *eventAttributes       = @"eid";
    
    
    NSMutableDictionary *queries = [NSMutableDictionary new];
    queries[@"notifications_query"] = [NSString stringWithFormat:@"SELECT %@ FROM notification WHERE recipient_id = %@", notificationAttributes, userId];
    
    queries[@"applications_query"] = [NSString stringWithFormat:@"SELECT %@ FROM application WHERE app_id IN (SELECT object_id FROM #notifications_query WHERE object_type = \"fb_web_app\")", applicationAttributes];
    
    queries[@"photos_query"] = [NSString stringWithFormat:@"SELECT %@ FROM photo WHERE object_id IN (SELECT object_id FROM #notifications_query WHERE object_type = \"photo\")", photoAttributes];
    
    queries[@"streams_query"] = [NSString stringWithFormat:@"SELECT %@ FROM stream WHERE post_id IN (SELECT object_id FROM #notifications_query WHERE object_type = \"stream\")", streamAttributes];
    
    queries[@"groups_query"] = [NSString stringWithFormat:@"SELECT %@ FROM group WHERE gid IN (SELECT object_id FROM #notifications_query WHERE object_type = \"group\")", groupAttributes];
    
    queries[@"pages_query"] = [NSString stringWithFormat:@"SELECT %@ FROM page WHERE page_id IN (SELECT object_id FROM #notifications_query WHERE object_type = \"page\")", pageAttributes];
    
    queries[@"events_query"] = [NSString stringWithFormat:@"SELECT %@ FROM event WHERE eid IN (SELECT object_id FROM #notifications_query WHERE object_type = \"event\")", eventAttributes];

    NSString *queryString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:queries options:0 error:nil] encoding:NSUTF8StringEncoding];
    
    NSString *urlString = [NSString stringWithFormat: @"https://graph.facebook.com/fql?q=%@&access_token=%@", queryString, accessToken];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    APP_DELEGATE.networkActivityIndicatorCounter++;
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *request,
                                                                                                  NSHTTPURLResponse *response,
                                                                                                  id JSON)
    {
        if (completionQueue && completionBlk)
        {
            dispatch_async(completionQueue, ^()
            {
                NSMutableArray *result = [NSMutableArray new];
                NSMutableArray *groups = [NSMutableArray new];
                NSMutableArray *posts  = [NSMutableArray new];
                NSMutableArray *photos = [NSMutableArray new];
                NSMutableArray *users  = [NSMutableArray new];
                
                NSArray * __block notificationsResultSet;
                
                [JSON[@"data"] enumerateObjectsUsingBlock:^(NSDictionary *queryResult, NSUInteger idx, BOOL *stop)
                {
                    if ([queryResult[@"name"] isEqualToString:@"notifications_query"])
                    {
                        notificationsResultSet = queryResult[@"fql_result_set"];
                        [queryResult[@"fql_result_set"] enumerateObjectsUsingBlock:^(NSDictionary *notification, NSUInteger idx, BOOL *stop)
                        {
                            NSMutableDictionary *notificationObjectDict = [NSMutableDictionary new];
                        
                            notificationObjectDict[@"notificationId"]       = notification[@"notification_id"];
                            notificationObjectDict[@"title"]                = notification[@"title_text"];
                            notificationObjectDict[@"body"]                 = notification[@"body_text"];
                            notificationObjectDict[@"date"]                 = [NSDate dateWithTimeIntervalSince1970:[notification[@"created_time"] longLongValue]];
                            notificationObjectDict[@"iconURL"]              = notification[@"icon_url"];
                            notificationObjectDict[@"externalURL"]          = notification[@"href"];
                            notificationObjectDict[@"isUnread"]             = notification[@"is_unread"];
                            notificationObjectDict[@"externalObjectId"]     = notification[@"object_id"];
                            notificationObjectDict[@"externalObjectType"]   = notification[@"object_type"];
                            notificationObjectDict[@"senderId"]             = [NSString stringWithFormat:@"%@", notification[@"sender_id"]];
                            
                            [result addObject:notificationObjectDict];
                        }];
                    }
                    if ([queryResult[@"name"] isEqualToString:@"groups_query"])
                    {
                        FacebookGroupsInfo *info = [[FacebookGroupsInfo alloc] init];
                        [groups addObjectsFromArray:[info parseGroups:queryResult[@"fql_result_set"]]];
                    }
                    if ([queryResult[@"name"] isEqualToString:@"pages_query"])
                    {
                        FacebookGroupsInfo *info = [[FacebookGroupsInfo alloc] init];
                        [groups addObjectsFromArray:[info parsePages:queryResult[@"fql_result_set"]]];
                    }
                    if ([queryResult[@"name"] isEqualToString:@"streams_query"])
                    {
                        [queryResult[@"fql_result_set"] enumerateObjectsUsingBlock:^(NSDictionary *postData, NSUInteger idx, BOOL *stop)
                        {
                            NSDictionary *processedData = [self getTopStoryPostWithDictionary:postData
                                                                             forGroupWithInfo:nil
                                                                                     andToken:accessToken];
                            if (processedData)
                            {
                                [posts addObject:processedData];
                            }
                        }];
                    }
                    if ([queryResult[@"name"] isEqualToString:@"photos_query"])
                    {
                        [queryResult[@"fql_result_set"] enumerateObjectsUsingBlock:^(NSDictionary *photoData, NSUInteger idx, BOOL *stop)
                        {
                            NSMutableDictionary *processedPhoto = [NSMutableDictionary new];
                            NSArray *imageInfo =
                            [photoData[@"images"] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"height" ascending:YES]]];
                            
                            [processedPhoto setObject:imageInfo.firstObject[@"source"] forKey:@"previewURLString"];
                            [processedPhoto setObject:imageInfo.lastObject[@"source"] forKey:@"mediaURLString"];
                            [processedPhoto setObject:@(kMediaPhoto) forKey:@"type"];
                            
                            NSString *stringId = photoData[@"object_id"];
                            if ([stringId isKindOfClass:[NSNumber class]])
                            {
                                stringId = [(NSNumber*)stringId stringValue];
                            }
                            
                            [processedPhoto setObject:stringId forKey:@"mediaObjectId"];

                            [photos addObject:processedPhoto];
                        }];
                    }
                }];
                
                [[notificationsResultSet valueForKey:@"sender_id"] enumerateObjectsUsingBlock:^(NSString *userId, NSUInteger idx, BOOL *stop)
                {
                    NSDictionary *user = [[self class] getUserInfoWithID:userId
                                                                andToken:accessToken];
                    
                    NSMutableDictionary *userObjectDict = [NSMutableDictionary new];
                    
                    userObjectDict[@"userID"]           = [NSString stringWithFormat:@"%@", user[@"id"]];
                    userObjectDict[@"name"]             = user[@"name"]?user[@"name"]:@"";
                    userObjectDict[@"avatarRemoteURL"]  = user[@"picture"][@"data"][@"url"]?user[@"picture"][@"data"][@"url"]:@"";
                    userObjectDict[@"profileURL"]       = user[@"profileURL"]?:[NSString stringWithFormat:@"https://www.facebook.com/%@",
                                                                                user[@"id"]];
                    if (user) [users addObject:userObjectDict];
                }];
                
                completionBlk(@{@"notifications":result,
                                @"groups":groups,
                                @"posts":posts,
                                @"photos":photos,
                                @"users":users
                                });
            });
        }
        APP_DELEGATE.networkActivityIndicatorCounter--;
    }
                                                                                        failure:^(NSURLRequest *request,
                                                                                                  NSHTTPURLResponse *response,
                                                                                                  NSError *error,
                                                                                                  id JSON)
    {
        if (completionQueue && completionBlk)
        {
            if ([JSON[@"error"][@"code"] integerValue] == 190)
            {
                [self invalidateSocialNetworkWithToken:accessToken];
            }
            
            dispatch_async(completionQueue, ^()
            {
                completionBlk(nil);
            });
        }
        APP_DELEGATE.networkActivityIndicatorCounter--;
    }];
    
    [operation start];
}

- (void)markNotificationAsRead:(NSString *)notificationId
                    withUserId:(NSString *)userId
                     withToken:(NSString *)accessToken
                    completion:(void(^)(NSError *error))completionBlock
{
    void (^completionBlk)(NSError *error) = [completionBlock copy];
    
    NSString *urlString = [NSString stringWithFormat:@"https://graph.facebook.com/Notif_%@_%@?access_token=%@&unread=0", userId, notificationId, accessToken];
    NSURL *url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        completionBlk(nil);
    }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        completionBlk(error);
    }];
    [operation start];
}

- (NSArray *)loadPostFromDate:(NSNumber *)fromDateUNIX withToken:(NSString *)token;
{
    NSArray *resultPosts = [[NSArray alloc] init];
    
    NSString *requestString = [NSString stringWithFormat: @"https://graph.facebook.com/fql?q=SELECT %@ FROM stream WHERE created_time>%@ AND filter_key = \"others\" AND NOT (source_id IN (SELECT gid FROM group_member WHERE uid = me())) AND NOT (target_id IN (SELECT gid FROM group_member WHERE uid = me())) AND NOT (source_id IN (SELECT page_id FROM page_fan WHERE uid = me())) ORDER BY created_time ASC LIMIT %d &access_token=%@", kFeedFields, fromDateUNIX, kMaxCountOfPostsInUpdate, token];
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return NO;
            }
            
            NSArray* postsData = [json objectForKey:@"data"];
            if (postsData.count)
            {
                NSDictionary *latestPost = [postsData lastObject];
                
                NSNumber *fromDate = latestPost[@"created_time"];
                
                return [[self loadPostFromDate:fromDate withToken:token] arrayByAddingObjectsFromArray:postsData];
            }
        }
    }
    
    return resultPosts;
}

- (NSArray *)searchPostsWithSearchText:(NSString *)searchText
                            token:(NSString*)token
                            limit:(NSUInteger)limit
{
    NSString *linkUTF = [searchText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *requestString = [NSString stringWithFormat: @"https://graph.facebook.com/search?q=%@&type=post&access_token=%@&limit=%ld",linkUTF,token, (unsigned long)limit];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
                                                             options:kNilOptions
                                                               error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            NSMutableArray* commonPostsArray = [[NSMutableArray alloc] init];
            NSMutableArray* resultArray = [[NSMutableArray alloc] init];
            NSArray* dataArray = [json objectForKey:@"data"];
            [commonPostsArray addObjectsFromArray:dataArray];
            NSArray *sortedPostsArray = [commonPostsArray sortedArrayUsingFunction:dateSortFunction context:nil];
            if(sortedPostsArray.count>limit)
            {
                sortedPostsArray = [[commonPostsArray sortedArrayUsingFunction:dateSortFunction context:nil] subarrayWithRange:NSMakeRange(0, limit)];
            }

            for(NSDictionary* dataDict in sortedPostsArray)
            {
                NSMutableDictionary *postInfo = [[self getPostWithDictionary:dataDict andToken:token] mutableCopy];
                [postInfo setObject:@YES forKey:kPostIsSearched];
                [resultArray addObject:postInfo];
            }
            
            return resultArray;
        }
    }

    return nil;
}

-(NSArray*)getPostsFromGroup:(NSString*)groupID withName:(NSString *)groupName andGroupType:(NSInteger)groupType withToken:(NSString*)token limit:(NSInteger)limit
{
    if (!limit)
    {
        limit = 1;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/%@/feed?access_token=%@&limit=%ld",groupID, token, (long)limit]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            if([json objectForKey:@"data"])
            {
                NSArray* dataArray = [NSArray arrayWithArray:[json objectForKey:@"data"]];
                NSMutableArray* resultArray = [[NSMutableArray alloc] init];
                for(NSDictionary* dataItem in dataArray)
                {
                    NSMutableDictionary* resultDict = [dataItem mutableCopy];
                    [resultDict setObject:groupID forKey:kPostGroupID];
                    [resultDict setObject:groupName forKey:kPostGroupName];
                    [resultDict setObject:@(groupType) forKey:kPostGroupType];
                    [resultArray addObject:resultDict];
                }
                return resultArray;
            }
        }
    }
    return nil;
};

-(NSArray*)loadMorePostsWithTokenFromGroup:(NSString*)groupID untilTime:(NSString*)untilTime count:(NSInteger)count andGroupType:(NSInteger)groupType andToken:(NSString*)token
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];

    NSMutableString *predicateString = [[NSMutableString alloc] init];
    [predicateString appendString:[NSString stringWithFormat:@"source_id==%@", groupID]];
    if (untilTime.integerValue)
    {
        [predicateString appendString:[NSString stringWithFormat:@"+created_time<%lli", untilTime.longLongValue - 1]];
    }
    
    NSString *requestString = [NSString stringWithFormat: @"https://graph.facebook.com/fql?q=SELECT+%@+FROM+stream+WHERE+%@+ORDER+BY+created_time+DESC+LIMIT+%ld&access_token=%@", kFeedFields, predicateString, (long)count, token];
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            NSDictionary *groupInfo = @{@"groupId" : groupID,
                                        @"name" : @"",
                                        @"type" : @(groupType)};
            
            NSArray* postsData = [json objectForKey:@"data"];
            for (NSDictionary *postData in postsData)
            {
                NSDictionary *processedData = [self getTopStoryPostWithDictionary:postData
                                                                 forGroupWithInfo:groupInfo
                                                                         andToken:token];
                if (processedData)
                {
                    [resultArray addObject:processedData];
                }
            }
        }
    }
    
    return resultArray;
}

- (NSArray *)loadMorePostsWithToken:(NSString *)token from:(NSInteger)from count:(NSInteger)count
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
    NSString *requestString = [NSString stringWithFormat: @"https://graph.facebook.com/fql?q=SELECT+%@+FROM+stream+WHERE+created_time<%@+AND+filter_key='others' AND NOT (source_id IN (SELECT gid FROM group_member WHERE uid = me())) AND NOT (target_id IN (SELECT gid FROM group_member WHERE uid = me())) AND NOT (source_id IN (SELECT page_id FROM page_fan WHERE uid = me())) ORDER+BY+created_time+DESC+LIMIT+%ld&access_token=%@", kFeedFields, @(from), (long)count, token];
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            NSArray* postsData = [json objectForKey:@"data"];
            for(NSDictionary* post in postsData)
            {
                NSDictionary* postDict = [self getTopStoryPostWithDictionary:post
                                                            forGroupWithInfo:nil
                                                                    andToken:token];
                if(postDict)
                {
                    [resultArray addObject:postDict];
                }
            }
        }
    }
    return resultArray;
}

- (NSString *)getUserPhotoWithID:(NSString *)userID andToken:(NSString *)token
{
    NSString *imageURL = nil;
    
    NSDictionary* userInfo = [[self class] getUserInfoWithID:userID andToken:token];
    if(userInfo)
    {
        if([userInfo objectForKey:@"picture"])
        {
            NSDictionary* picture = [userInfo objectForKey:@"picture"];
            NSDictionary* data = [picture objectForKey:@"data"];
            if(data)
            {
                imageURL = [data objectForKey:@"url"];
            }
        }
    }
    
    return imageURL;
}

+ (NSDictionary *)getUserInfoWithID:(NSString *)userID andToken:(NSString *)token

{
    if (![userID isKindOfClass:[NSString class]])
    {
        userID = [NSString stringWithFormat:@"%@", userID];
    }
    
    //First, try to download actual user info
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/%@?fields=picture,name,id&access_token=%@",userID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    
    NSError *error = nil; NSURLResponse *response = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if(data)
        
    {
        
        NSError* error = nil;
        
        NSDictionary* json = [NSJSONSerialization
                              
                              JSONObjectWithData:data
                              
                              options:kNilOptions
                              
                              error:&error];
        
        if(!error)
            
        {
            
            if (json[@"error"])
                
            {
                
                NSDictionary *errorDescription = json[@"error"];
                
                DLog(@"Facebook response with error : %@", errorDescription);
                
                
                
                if ([errorDescription[@"code"] integerValue] == 190)
                    
                {
                    
                    [[self new] invalidateSocialNetworkWithToken:token];
                    
                }
                
            }else
                
            {
                
                return json;
                
            }
            
        }
        
    }
    
    
    
    //If
    
    NSArray *socialNetworks = [[WDDDataBase sharedDatabase] fetchObjectsWithEntityName:NSStringFromClass([SocialNetwork class])
                               
                                                                         withPredicate:[NSPredicate predicateWithFormat:@"accessToken == %@", token]
                               
                                                                       sortDescriptors:nil];
    
    if (socialNetworks.count)
        
    {
        
        NSArray *users = [[WDDDataBase sharedDatabase] fetchObjectsWithEntityName:NSStringFromClass([FaceBookProfile class])
                          
                                                                    withPredicate:[NSPredicate predicateWithFormat:@"userID = %@", userID]
                          
                                                                  sortDescriptors:nil];
        
        if (users.count)
            
        {
            
            NSDictionary *info = @{@"id" : userID,
                                   
                                   @"picture" : @{@"data" : @{@"url" : [users.firstObject avatarRemoteURL]} },
                                   
                                   @"name" : [users.firstObject name],
                                   
                                   @"profileURL" : [users.firstObject profileURL]};
            
            return info;
            
        }
        
        
        
    }
    
    
    
    return nil;
    
}

- (BOOL)setLikeOnObjectID:(NSString *)objectID withToken:(NSString *)token
{
    if (![self likeOnObjectID:objectID withToken:token])
    {
        NSArray *components = [objectID componentsSeparatedByString:@"_"];
        
        return [self likeOnObjectID:[components lastObject] withToken:token];
    }
    
    return YES;
}

- (BOOL)setUnlikeOnObjectID:(NSString *)objectID withToken:(NSString *)token
{
    if (![self unlikeOnObjectID:objectID withToken:token])
    {
        NSArray *components = [objectID componentsSeparatedByString:@"_"];
        
        return [self unlikeOnObjectID:[components lastObject] withToken:token];
    }
    
    return YES;
}


- (BOOL)isPostLikedMe:(NSString *)postID withToken:(NSString *)token andMyID:(NSString *)myID
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/%@/likes?access_token=%@",postID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return NO;
            }
            
            if ([json objectForKey:@"data"])
            {
                NSArray* likesArray = [json objectForKey:@"data"];
                for(NSDictionary* like in likesArray)
                {
                    NSString* likeID = [like objectForKey:@"id"];
                    if([likeID isEqualToString:myID])
                    {
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

- (NSNumber *)countOfLikesWithObjectID:(NSString *)objectID andToken:(NSString *)token
{
    NSNumber* numberOfCounts = [NSNumber numberWithInt:0];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/%@/likes?summary=1&access_token=%@",objectID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            if ([json objectForKey:@"summary"])
            {
                NSDictionary* summary = [json objectForKey:@"summary"];
                numberOfCounts = [summary objectForKey:@"total_count"];
                return numberOfCounts;
            }
        }
    }
    return numberOfCounts;
}


- (BOOL)addPostToWallWithToken:(NSString*)token
                    andMessage:(NSString*)message
                       andLink:(NSString*)link
                       andName:(NSString*)name
               withDescription:(NSString*)description
                   andImageURL:(NSString*)imageURL
                 toGroupWithID:(NSString *)groupID
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSString *groupToken = nil;
    
    if (groupID)
    {
        NSString *requestString = [[NSString stringWithFormat:@"https://graph.facebook.com/me/accounts?limit=5000&offset=0&access_token=%@", token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
        
        NSError *error = nil;
        NSURLResponse *response = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                     returningResponse:&response
                                                                 error:&error];
        if(responseData)
        {
            NSError* parserError = nil;
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData
                                                                 options:kNilOptions
                                                                   error:&parserError];
            if(!parserError)
            {
                if (json[@"error"])
                {
                    NSDictionary *errorDescription = json[@"error"];
                    DLog(@"Facebook response with error : %@", errorDescription);
                    
                    if ([errorDescription[@"code"] integerValue] == 190)
                    {
                        [self invalidateSocialNetworkWithToken:token];
                    }
                    
                    return NO;
                }
                
                NSArray *pages = json[@"data"];
                if (pages && [pages isKindOfClass:[NSArray class]])
                {
                    for (NSDictionary *pageInfo in pages)
                    {
                        id pageId = pageInfo[@"id"];
                        if ([pageId isKindOfClass:[NSNumber class]])
                        {
                            pageId = [pageId stringValue];
                        }
                        else if(![pageId isKindOfClass:[NSString class]])
                        {
                            continue;
                        }
                        
                        if ([pageId isEqualToString:groupID])
                        {
                            groupToken = pageInfo[@"access_token"];
                        }
                    }
                }
            }
        }
    }
    
    if (groupID && groupToken)
    {
        [params s_setObject:groupToken forKey:@"access_token"];
    }
    else
    {
        [params s_setObject:token forKey:@"access_token"];
    }
    
    if(message)
    {
        [params s_setObject:message forKey:@"message"];
    }
    if(description)
    {
        [params s_setObject:description forKey:@"description"];
    }
    if(link)
    {
        if([link rangeOfString:@"www.facebook.com"].location != NSNotFound)
        {
            NSString* linkStr = @"";
            if(description)
            {
                linkStr = [NSString stringWithFormat:@"%@ %@",description,link];
            }
            else
            {
                linkStr = link;
            }
            [params s_setObject:linkStr forKey:@"message"];
        }
        else
        {
            [params s_setObject:link forKey:@"link"];
        }
        if (name)
        {
            [params s_setObject:name forKey:@"name"];
        }
    }
    if(imageURL)
    {
        if([imageURL rangeOfString:@"https://fbcdn-profile-a.akamaihd.net/"].location == NSNotFound)
        {
            [params s_setObject:imageURL forKey:@"picture"];
            
            if (!params[@"link"])
            {
                [params s_setObject:@"www.woddl.com" forKey:@"link"];
            }
        }
    }

    
    
    NSMutableArray* pairs = [NSMutableArray array];
    for (NSString* key in params.keyEnumerator)
    {
        NSString* value = [params objectForKey:key];
        NSString* escaped_value = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                      NULL,
                                                                                      (CFStringRef)value,
                                                                                      NULL,
                                                                                      (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                      kCFStringEncodingUTF8));
        
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
    }
    
    NSString* query = [pairs componentsJoinedByString:@"&"];
    
    NSString *requestString = [[NSString stringWithFormat: @"https://graph.facebook.com/%@/feed", groupID ? : @"me"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[query dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString* status = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if([status rangeOfString:@"id"].location != NSNotFound)
    {
        return YES;
    }
    return NO;
}

- (NSString *)buildQueryFromDictionary:(NSDictionary *)params
{
    NSMutableArray* pairs = [NSMutableArray array];

    for (NSString* key in params.keyEnumerator)
    {
        NSString* value = [params objectForKey:key];
        NSString* escaped_value = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                                        NULL,
                                                                                                        (CFStringRef)value,
                                                                                                        NULL,
                                                                                                        (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                                        kCFStringEncodingUTF8));
        
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", key, escaped_value]];
    }
    
    return [pairs componentsJoinedByString:@"&"];
}

- (BOOL)addStatusWithToken:(NSString *)token
                andMessage:(NSString *)message
                  location:(WDDLocation *)location
               andImageURL:(NSString *)imageURL
{
    NSString *lon = @(location.longitude).stringValue;
    NSString *lat = @(location.latidude).stringValue;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params s_setObject:token forKey:@"access_token"];
    
    NSString* locationID = [self getLocationIDFromLocation:location withToken:token];
    if(message)
    {
        [params s_setObject:message forKey:@"message"];
    }
    if(imageURL)
    {
        [params s_setObject:imageURL forKey:@"picture"];
        //[params s_setObject:@"http://www.woddl.com" forKey:@"link"];
        //[params s_setObject:@"posted via Woddl" forKey:@"name"];
    }
    if(locationID)
    {
        [params s_setObject:locationID forKey:@"place"];
    }
    if(![lon isEqualToString:@"0"]&&![lat isEqualToString:@"0"])
    {
        NSString* coordinates=[NSString stringWithFormat:@"{\"latitude\": %@, \"longitude\": %@}",lat,lon];
        [params s_setObject:coordinates forKey:@"coordinates"];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/me/feed"]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[self buildQueryFromDictionary:params] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSError *error = nil; NSURLResponse *response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString* status = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if([status rangeOfString:@"id"].location != NSNotFound)
    {
        return YES;
    }
    return NO;
}

- (BOOL)addStatusWithToken:(NSString *)token
                andMessage:(NSString *)message
                  location:(WDDLocation *)location
                  andImage:(UIImage *)image
{
    NSString *lon = [NSNumber numberWithDouble:location.longitude].stringValue;
    NSString *lat = [NSNumber numberWithDouble:location.latidude].stringValue;
    
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params s_setObject:token forKey:@"access_token"];
    
    NSString* locationID;
    if (location.facebookID)
    {
        locationID = location.facebookID;
    }
    else
    {
        locationID = [self getLocationIDFromLocation:location withToken:token];
    }
    
    if(message)
    {
        [params s_setObject:message forKey:@"message"];
    }
    
    if (locationID)
    {
        [params s_setObject:locationID forKey:@"place"];
    }
    if (![lon isEqualToString:@"0"] && ![lat isEqualToString:@"0"])
    {
        NSString* coordinates=[NSString stringWithFormat:@"{\"latitude\": %@, \"longitude\": %@}",lat,lon];
        [params s_setObject:coordinates forKey:@"coordinates"];
    }
    
    // add image to album
    if (image)
    {
        static NSString * const boundary = @"9m6dnw5z3dxxyhgfc2zc";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        
        NSMutableData *body = [NSMutableData data];
        
        NSMutableURLRequest *photoUploadRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:@"https://graph.facebook.com/me/photos"]];
        photoUploadRequest.HTTPMethod = @"POST";
        [photoUploadRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"access_token\"\r\n\r\n%@", token] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name = \"media\";\r\nfilename=\"media.jpg\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:UIImageJPEGRepresentation(image, 0.75)];
        
        for (NSString *key in params.allKeys)
        {
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@", key, params[key]] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];

        
        photoUploadRequest.HTTPBody = body;
        [photoUploadRequest addValue:@(body.length).stringValue forHTTPHeaderField: @"Content-Length"];
        
        NSHTTPURLResponse *photoRequestResponse = nil;
        NSError *photoRequestError = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:photoUploadRequest
                                             returningResponse:&photoRequestResponse
                                                         error:&photoRequestError];
        
        NSError *serializationError = nil;
        id response = [NSJSONSerialization JSONObjectWithData:data
                                                      options:kNilOptions
                                                        error:&serializationError];
        
        if (serializationError)
        {
            NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            DLog(@"Can't serialize FB response: %@", response);
        }
        
        return (nil != response[@"id"] && nil != response[@"post_id"]);
    }
    else
    {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/me/feed"]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[[self buildQueryFromDictionary:params] dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSError *error = nil; NSURLResponse *response = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        NSString* status = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if([status rangeOfString:@"id"].location != NSNotFound)
        {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)addStatusWithToken:(NSString *)token
                andMessage:(NSString *)message
                  location:(WDDLocation *)location
                  andImage:(UIImage *)image
                   toGroup:(NSString *)groupId
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    
    NSString *groupToken = nil;
    
    if (groupId)
    {
        NSString *requestString = [[NSString stringWithFormat:@"https://graph.facebook.com/me/accounts?limit=5000&offset=0&access_token=%@", token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
        
        NSError *error = nil;
        NSURLResponse *response = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                     returningResponse:&response
                                                                 error:&error];
        if(responseData)
        {
            NSError* parserError = nil;
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:responseData
                                                                 options:kNilOptions
                                                                   error:&parserError];
            if(!parserError)
            {
                if (json[@"error"])
                {
                    NSDictionary *errorDescription = json[@"error"];
                    DLog(@"Facebook response with error : %@", errorDescription);
                    
                    if ([errorDescription[@"code"] integerValue] == 190)
                    {
                        [self invalidateSocialNetworkWithToken:token];
                    }
                    
                    return NO;
                }
                
                NSArray *pages = json[@"data"];
                if (pages && [pages isKindOfClass:[NSArray class]])
                {
                    for (NSDictionary *pageInfo in pages)
                    {
                        id pageId = pageInfo[@"id"];
                        if ([pageId isKindOfClass:[NSNumber class]])
                        {
                            pageId = [pageId stringValue];
                        }
                        else if(![pageId isKindOfClass:[NSString class]])
                        {
                            continue;
                        }
                        
                        if ([pageId isEqualToString:groupId])
                        {
                            groupToken = pageInfo[@"access_token"];
                        }
                    }
                }
            }
        }
    }
    
    if (groupId && groupToken)
    {
        [params s_setObject:groupToken forKey:@"access_token"];
    }
    else
    {
        [params s_setObject:token forKey:@"access_token"];
    }

    NSString *lon = [NSNumber numberWithDouble:location.longitude].stringValue;
    NSString *lat = [NSNumber numberWithDouble:location.latidude].stringValue;
   
    NSString* locationID = [self getLocationIDFromLocation:location withToken:token];
    if(message)
    {
        [params s_setObject:message forKey:@"message"];
    }
    
    if (locationID)
    {
        [params s_setObject:locationID forKey:@"place"];
    }
    if (![lon isEqualToString:@"0"] && ![lat isEqualToString:@"0"])
    {
        NSString* coordinates=[NSString stringWithFormat:@"{\"latitude\": %@, \"longitude\": %@}",lat,lon];
        [params s_setObject:coordinates forKey:@"coordinates"];
    }
    
    // add image to album
    if (image)
    {
        static NSString * const boundary = @"9m6dnw5z3dxxyhgfc2zc";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        
        NSMutableData *body = [NSMutableData data];
        
        NSString *urlString = [[NSString stringWithFormat:@"https://graph.facebook.com/%@/photos", groupId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSMutableURLRequest *photoUploadRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
        photoUploadRequest.HTTPMethod = @"POST";
        [photoUploadRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"access_token\"\r\n\r\n%@", token] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name = \"media\";\r\nfilename=\"media.jpg\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:UIImageJPEGRepresentation(image, 0.75)];
        
        for (NSString *key in params.allKeys)
        {
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@", key, params[key]] dataUsingEncoding:NSUTF8StringEncoding]];
        }
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        photoUploadRequest.HTTPBody = body;
        [photoUploadRequest addValue:@(body.length).stringValue forHTTPHeaderField: @"Content-Length"];
        
        NSHTTPURLResponse *photoRequestResponse = nil;
        NSError *photoRequestError = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:photoUploadRequest
                                             returningResponse:&photoRequestResponse
                                                         error:&photoRequestError];
        
        NSError *serializationError = nil;
        id response = [NSJSONSerialization JSONObjectWithData:data
                                                      options:kNilOptions
                                                        error:&serializationError];
        
        if (serializationError)
        {
            NSString *response = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            DLog(@"Can't serialize FB response: %@", response);
        }
        
        return (nil != response[@"id"] && nil != response[@"post_id"]);
    }
    else
    {
        NSString *urlString = [[NSString stringWithFormat:@"https://graph.facebook.com/%@/feed", groupId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[[self buildQueryFromDictionary:params] dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSError *error = nil; NSURLResponse *response = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        NSString* status = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if([status rangeOfString:@"id"].location != NSNotFound)
        {
            return YES;
        }
    }
    
    return NO;
}

-(NSString*)getLocationIDFromLocation:(WDDLocation *)location withToken:(NSString*)token
{
    NSString *lon = @(location.longitude).stringValue;
    NSString *lat = @(location.latidude).stringValue;
    
    NSString* locationID = nil;
    NSString* query = [NSString stringWithFormat:@"https://graph.facebook.com/search?type=place&center=%@,%@&distance=1000&access_token=%@",lat,lon,token];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:query] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    
    NSError *error = nil; NSURLResponse *response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            if([json objectForKey:@"data"])
            {
                NSArray* places = [json objectForKey:@"data"];
                
                if (location.name)
                {
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name LIKE[cd] %@", location.name];
                    NSArray *matchArray = [places filteredArrayUsingPredicate:predicate];
                    
                    NSDictionary *venue = [matchArray firstObject];
                    if (venue)
                    {
                        return venue[@"id"];
                    }
                }
               
                CGFloat minDistance = 1000;
                NSDictionary* resultDictionary = nil;
                for(NSDictionary* place in places)
                {
                    NSDictionary* location = [place objectForKey:@"location"];
                    NSString* latitudeStr = [location objectForKey:@"latitude"];
                    NSString* longitudeStr = [location objectForKey:@"longitude"];
                    CGFloat latitude = [latitudeStr floatValue];
                    CGFloat longitude = [longitudeStr floatValue];
                    CGFloat distance = sqrtf((lat.floatValue-latitude)*(lat.floatValue-latitude)-(lon.floatValue-longitude)*(lon.floatValue-longitude));
                    if(distance<minDistance)
                    {
                        minDistance = distance;
                        resultDictionary = place;
                    }
                }
                if(resultDictionary)
                {
                    locationID = [resultDictionary objectForKey:@"id"];
                }
            }
        }
    }
    return locationID;
}

-(BOOL)sharePostWithToken:(NSString*)token andMessage:(NSString*)message withLink:(NSString*)link
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/me/feed"]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"access_token=%@&message=%@&link=%@",token,message,link] dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString* status = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if([status rangeOfString:@"id"].location != NSNotFound)
    {
        return YES;
    }
    return NO;
}

-(NSDictionary*)fetchInboxWithToken:(NSString*)token
{
    NSMutableURLRequest *request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/me/inbox?access_token=%@", token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    
    NSError *error = nil;
    NSURLResponse *response = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            return json;
        }
    }
    
    return nil;
}

- (NSDictionary *)getPostWithDictionary:(NSDictionary *)dataDict andToken:(NSString *)token
{
    NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
    NSString* postID = [dataDict objectForKey:@"id"];
    NSString* datePostStr = [dataDict objectForKey:@"created_time"];
    NSDate* datePost = [[self class] convertFacebookDateToNSDate:datePostStr];
    NSArray* actions = [dataDict objectForKey:@"actions"];
    
    __block NSString* text = nil;
    
    if ([dataDict objectForKey:@"message"])
    {
        NSString *message = [dataDict objectForKey:@"message"];
        text = message;
        
        if ([dataDict[@"status_type"] isEqualToString:@"shared_story"])
        {
            if (dataDict[@"link"] && [text rangeOfString:dataDict[@"link"]].location == NSNotFound)
            {
                if(![self isLinkExcept:dataDict[@"link"]])
                {
                    NSString* textWithLink = [NSString stringWithFormat:@"%@ %@",text,dataDict[@"link"]];
                    text = textWithLink;
                }
            }
        }
    }
    else if ([dataDict objectForKey:@"story"])
    {
        text = [dataDict objectForKey:@"story"];
        if (dataDict[@"link"])
        {
            if(![self isLinkExcept:dataDict[@"link"]])
            {
                text = [dataDict objectForKey:@"story"];//[NSString stringWithFormat:@"%@ %@", [dataDict objectForKey:@"story"], dataDict[@"link"]];
            }
            if([dataDict[@"link"] rangeOfString:@"events"].location != NSNotFound)
            {
                [resultDictionary s_setObject:[NSNumber numberWithInt:kPostTypeEvent] forKey:kPostType];
            }
        }
        else
        {
            NSString *postLink = [self getPostLink:postID andToken:token];
            if(postLink)
            {
                if(![self isLinkExcept:postLink])
                {
                    NSString* textWithLink = [NSString stringWithFormat:@"%@ %@",text,postLink];
                    text = textWithLink;
                }
            }
            else
            {
                return nil;
            }
        }
    }
    else if ([dataDict objectForKey:@"description"])
    {
        text = [dataDict objectForKey:@"description"];
    }
    else
    {
        NSDictionary* action = [actions lastObject];
        if ([action objectForKey:@"link"])
        {
            NSString* link = [action objectForKey:@"link"];
            if(![self isLinkExcept:link])
            {
                text = link;
            }
            else
            {
                text = @"";
            }
        }
        else
        {
            text = @"";
        }
    }
    
    if([dataDict objectForKey:@"place"])
    {
        NSDictionary* place = [dataDict objectForKey:@"place"];
        
        if([place objectForKey:@"name"])
        {
            NSString* placeName = [place objectForKey:@"name"];
            text = [NSString stringWithFormat:@"%@\n%@", text, placeName];
        }
        
        NSDictionary* location = [place objectForKey:@"location"];
        
        NSMutableDictionary *placeDict = [[NSMutableDictionary alloc] initWithCapacity:8];
        [placeDict s_setObject:place[@"id"] forKey:kPlaceIdDictKey];
        [placeDict s_setObject:[place objectForKey:@"name"] forKey:kPlaceNameDictKey];
        [placeDict s_setObject:@([location[@"latitude"] doubleValue]) forKey:kPlaceLatitudeDictKey];
        [placeDict s_setObject:@([location[@"longitude"] doubleValue]) forKey:kPlaceLongitudeDictKey];
        if ([place objectForKey:@"name"])
        {
            [placeDict s_setObject:[place objectForKey:@"name"] forKey:kPlaceAddressDictKey];
        }
        [resultDictionary setObject:@[placeDict] forKey:kPostPlacesListKey];
    }
    
    if([dataDict objectForKey:kPostGroupID])
    {
        [resultDictionary s_setObject:[dataDict objectForKey:kPostGroupID] forKey:kPostGroupID];
        [resultDictionary s_setObject:[dataDict objectForKey:kPostGroupType] forKey:kPostGroupType];
    }
    
    NSArray *idComponents = [postID componentsSeparatedByString:@"_"];
    NSString *identifier = idComponents.lastObject ?: postID;
    [resultDictionary s_setObject:identifier forKey:kPostIDDictKey];
    [resultDictionary s_setObject:datePost forKey:kPostDateDictKey];
    
    //Author
    NSDictionary* authorDict = [dataDict objectForKey:@"from"];
    NSString* authorID = [authorDict objectForKey:@"id"];
    NSString* authorName = [authorDict objectForKey:@"name"];
    NSString* userPicture = [self getUserPhotoWithID:authorID andToken:token];
    NSString *userProfileURLString = [FacebookRequest profileURLWithID:authorID];
    
    NSMutableDictionary* personPosted = [[NSMutableDictionary alloc] init];
    
    [personPosted setValue:authorName forKey:kPostAuthorNameDictKey];
    if(userPicture)
    {
        [personPosted setValue:userPicture forKey:kPostAuthorAvaURLDictKey];
    }
    [personPosted setValue:authorID forKey:kPostAuthorIDDictKey];
    [personPosted setValue:userProfileURLString forKey:kPostAuthorProfileURLDictKey];
    
    [resultDictionary s_setObject:personPosted forKey:kPostAuthorDictKey];
    
    //comments
    NSNumber* countOfComments = [self countOfCommentsWithObjectID:postID andToken:token];
    NSArray* comments = [self getCommentsOnPostID:postID offset:countOfComments.intValue-kMaxCountOfCommentsrefresh withLimit:kMaxCountOfCommentsrefresh withToken:token];
    
    [resultDictionary s_setObject:comments forKey:kPostCommentsDictKey];
    [resultDictionary s_setObject:countOfComments forKey:kPostCommentsCountDictKey];
    
    //likes
    
    NSNumber* countOfLikes = [self countOfLikesWithObjectID:postID andToken:token];
    
    [resultDictionary s_setObject:countOfLikes forKey:kPostLikesCountDictKey];
    
    //media
    if([dataDict objectForKey:@"picture"])
    {
        NSMutableArray* photos = [self getObjectPhotos:postID andToken:token];
        NSMutableArray* mediaResultArray = [[NSMutableArray alloc] init];
        
        
        if([[dataDict objectForKey:@"type"] isEqualToString:@"video"])
        {
            NSMutableDictionary* mediaResultDict = [[NSMutableDictionary alloc] init];
            
            NSString* sourceVideoURL = [dataDict objectForKey:@"source"];
            
            if([sourceVideoURL rangeOfString:@"youtube.com"].location != NSNotFound)
            {
                [mediaResultDict s_setObject:[self linkForYoutubeVideo:sourceVideoURL] forKey:kPostMediaURLDictKey];
            }
            else if ([sourceVideoURL rangeOfString:@"vimeo.com"].location != NSNotFound)
            {
                [mediaResultDict s_setObject:[self linkForVimeoVideo:sourceVideoURL] forKey:kPostMediaURLDictKey];
            }
            else
            {
                
                [mediaResultDict s_setObject:sourceVideoURL forKey:kPostMediaURLDictKey];
            }
            
            [mediaResultDict s_setObject:[dataDict objectForKey:@"picture"] forKey:kPostMediaPreviewDictKey];
            [mediaResultDict s_setObject:@"video" forKey:kPostMediaTypeDictKey];
            [mediaResultArray addObject:mediaResultDict];
            
            [resultDictionary s_setObject:mediaResultArray forKey:kPostMediaSetDictKey];
        }
        else
        {
            if(photos.count==0)
            {
//                [photos addObject:[dataDict objectForKey:@"picture"]];
                [photos addObject:@{ kPostMediaPreviewDictKey : dataDict[@"picture"],
                                     kPostMediaURLDictKey : dataDict[@"picture"],
                                     kPostMediaTypeDictKey : @"image"}];
            }
//            for(NSString* photoURL in photos)
//            {
//                if([photoURL rangeOfString:@"_n.jpg"].location==NSNotFound)
//                {
//                    NSMutableDictionary* mediaResultDict = [[NSMutableDictionary alloc] init];
//                    
//                    if([photoURL rangeOfString:@"_s.jpg"].location!=NSNotFound||[photoURL rangeOfString:@"_q.jpg"].location!=NSNotFound)
//                    {
//                        NSString* highQualityImage = [NSString stringWithFormat:@"%@%@", [photoURL substringToIndex:[photoURL length] - 6],@"_n.jpg"];
//                        [mediaResultDict s_setObject:highQualityImage forKey:kPostMediaURLDictKey];
//                    }
//                    else
//                    {
//                        [mediaResultDict s_setObject:photoURL forKey:kPostMediaURLDictKey];
//                    }
//                    
//                    [mediaResultDict s_setObject:photoURL forKey:kPostMediaPreviewDictKey];
//                    [mediaResultDict s_setObject:@"image" forKey:kPostMediaTypeDictKey];
//                    [mediaResultArray addObject:mediaResultDict];
//                }
//            }
            
            [resultDictionary s_setObject:photos forKey:kPostMediaSetDictKey];
        }
        
//        [resultDictionary s_setObject:mediaResultArray forKey:kPostMediaSetDictKey];
    }
    else if ([dataDict[@"source"] length])
    {
        text = [text stringByAppendingString:dataDict[@"source"]];
    }
    
    //link
    if([dataDict objectForKey:@"link"])
    {
        resultDictionary[kPostLinkOnWebKey] = dataDict[@"link"];
    }
    else
    {
        if(authorDict[@"category_list"])
        {
            NSArray* categoryList = authorDict[@"category_list"];
            NSDictionary* category = [categoryList objectAtIndex:0];
            NSString* categoryID = category[@"id"];
            NSString* cutID = [self stringBetweenString:@"_" andString:@"" innerString:postID];
            resultDictionary[kPostLinkOnWebKey] = [NSString stringWithFormat:@"https://www.facebook.com/%@/posts/%@",categoryID,cutID];
        }
        else
        {
            NSDictionary* action = [actions firstObject];
            if(action[@"link"])
            {
                resultDictionary[kPostLinkOnWebKey] = action[@"link"];
            }
        }
    }
    
    //hash tags
    NSArray* hashTags = [self getHashTags:text];
    NSArray *userTags = [self getUserTags:dataDict[@"message_tags"]];
    
    NSArray *postIdComponents = [postID componentsSeparatedByString:@"_"];
    if (postIdComponents.count > 1)
    {
        NSString *postSelfLink = [NSString stringWithFormat:@"https://www.facebook.com/%@/posts/%@", postIdComponents[0], postIdComponents[1]];
        text = [[text stringByReplacingOccurrencesOfString:postSelfLink withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    [resultDictionary s_setObject:text forKey:kPostTextDictKey];
    
    [resultDictionary s_setObject:[hashTags arrayByAddingObjectsFromArray:userTags] forKey:kPostTagsListKey];
    
    return resultDictionary;
}

- (NSMutableArray *)getObjectPhotos:(NSString *)objectID andToken:(NSString *)token
{
    NSMutableArray* photosResult = [[NSMutableArray alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/fql?q=SELECT+attachment+FROM+stream+WHERE+post_id='%@'&access_token=%@&count=10",objectID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            NSArray* photosData = [json objectForKey:@"data"];
//            NSMutableSet *foundPhotos = [[NSMutableSet alloc] initWithCapacity:photosData.count];
            for(NSDictionary* photo in photosData)
            {
                if([photo objectForKey:@"attachment"])
                {
                    photosResult = [[self getObjectPhotosFromDictionary:[photo objectForKey:@"attachment"]
                                                               andToken:token] mutableCopy];
                    
//                    NSDictionary* attachment = [photo objectForKey:@"attachment"];
//                    if([attachment objectForKey:@"media"])
//                    {
//                        NSArray* media = [attachment objectForKey:@"media"];
//                        for (NSDictionary* mediaDict in media)
//                        {
//                            if([mediaDict objectForKey:@"photo"])
//                            {
//                                NSDictionary* photoDict = [mediaDict objectForKey:@"photo"];
//                                NSArray* images = [photoDict objectForKey:@"images"];
//                                if(!images || images.count == 1)
//                                {
//                                    NSString* photoURL = [mediaDict objectForKey:@"src"];
//                                    NSString* resultPhotoURL = [photoURL stringByReplacingOccurrencesOfString:@"_s.png" withString:@"_n.png"];
//                                    
//                                    if (![foundPhotos containsObject:resultPhotoURL])
//                                    {
//                                        [photosResult addObject:resultPhotoURL];
//                                        [foundPhotos addObject:resultPhotoURL];
//                                    }
//                                }
//                                for(NSDictionary* photoItem in images)
//                                {
//                                    NSString* photoURL = [photoItem objectForKey:@"src"];
//                                    NSString* resultPhotoURL = [photoURL stringByReplacingOccurrencesOfString:@"_s.png" withString:@"_n.png"];
//                                    
//                                    if (![foundPhotos containsObject:resultPhotoURL])
//                                    {
//                                        [photosResult addObject:resultPhotoURL];
//                                        [foundPhotos addObject:resultPhotoURL];
//                                    }
//                                }
//                            }
//                        }
//                    }
                }
            }
        }
    }
    return photosResult;
}

- (NSMutableArray *)getObjectVideo:(NSString *)objectID andToken:(NSString *)token
{
    
    NSMutableArray* photosResult = [[NSMutableArray alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/fql?q=SELECT+attachment+FROM+stream+WHERE+post_id='%@'&access_token=%@&count=10",objectID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            NSArray* photosData = [json objectForKey:@"data"];
            for(NSDictionary* photo in photosData)
            {
                if([photo objectForKey:@"attachment"])
                {
                    NSDictionary* attachment = [photo objectForKey:@"attachment"];
                    if([attachment objectForKey:@"media"])
                    {
                        NSArray* media = [attachment objectForKey:@"media"];
                        for (NSDictionary* mediaDict in media)
                        {
                            if([mediaDict objectForKey:@"type"])
                            {
                                if([[mediaDict objectForKey:@"type"] isEqualToString:@"video"])
                                {
                                    NSDictionary * video = [mediaDict objectForKey:@"video"];
                                    if(video)
                                    {
                                        NSMutableDictionary * resultDict = [[NSMutableDictionary alloc] init];
                                        NSString* videoURL = [video objectForKey:@"source_url"];
                                        if(videoURL)
                                        {
                                            [resultDict s_setObject:videoURL forKey:@"videoURL"];
                                            [resultDict s_setObject:[mediaDict objectForKey:@"src"] forKey:@"videoPreview"];
                                            [photosResult addObject:resultDict];
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return photosResult;
}


- (NSString *)getPostLink:(NSString *)objectID andToken:(NSString *)token
{
    NSString* resultURL = nil;
    
    NSString* postID = [self stringBetweenString:@"_" andString:@"" innerString:objectID];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/%@?access_token=%@",postID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            if([json objectForKey:@"link"])
            {
                return [json objectForKey:@"link"];
            }
        }
    }
    return resultURL;
}

- (NSDictionary *)getPhotoWithFID:(NSNumber *)fid withToken:(NSString *)token
{
    NSDictionary *resultPhotoDict;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/%@?accesstoken=%@",fid,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];
    if (!error)
    {
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if (!error && !json[@"error"])
        {
            resultPhotoDict = @{ kHighResolutionPhoto : json[kHighResolutionPhoto],
                                 kLowResolutionPhoto  : json[kLowResolutionPhoto] };
        }
        else if (json[@"error"])
        {
            NSDictionary *errorDescription = json[@"error"];
            DLog(@"Facebook response with error : %@", errorDescription);
            
            if ([errorDescription[@"code"] integerValue] == 190)
            {
                [self invalidateSocialNetworkWithToken:token];
            }
            
            return nil;
        }
    }
    return resultPhotoDict;
}

+ (NSDate *)convertFacebookDateToNSDate:(NSString *)created_at
{
    static NSString * const fullDateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    static NSString * const dateOnlyFormat = @"yyyy-MM-dd";
    
    // need check before 12:00
    static NSDateFormatter *dateFormatter = nil;
    
    if (!dateFormatter)
    {
        dateFormatter = [NSDateFormatter new];
        dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"En_us"];
        dateFormatter.dateFormat = fullDateFormat;
    }
    
    NSDate *date = [dateFormatter dateFromString:created_at];
    
    if (!date)
    {
        dateFormatter.dateFormat = dateOnlyFormat;
        date = [dateFormatter dateFromString:created_at];
        dateFormatter.dateFormat = fullDateFormat;
    }
    
    return date;
}

#pragma mark - Comments

-(NSArray*)getCommentsOnPostID:(NSString*)postID withToken:(NSString*)token
{
    NSMutableArray* allComments = nil;
    allComments = [self getCommentsFrom:0 to:kMaxCountOfCommentsrefresh postID:postID withAccessToken:token];
    return allComments;
}

-(NSArray*)getCommentsOnPostID:(NSString*)postID offset:(NSUInteger)offset withToken:(NSString*)token
{
    NSMutableArray* allComments = nil;
    allComments = [self getCommentsFrom:offset to:kMaxCountOfCommentsrefresh postID:postID withAccessToken:token];
    return allComments;
}

-(NSArray*)getCommentsOnPostID:(NSString*)postID offset:(int)offset withLimit:(NSUInteger)limit withToken:(NSString*)token
{
    NSMutableArray* allComments = nil;
    allComments = [self getCommentsFrom:0 to:kMaxCountOfCommentsrefresh postID:postID withAccessToken:token];
    
    return allComments;
}
/////////////////////////////////////////////////////////////////////////////


-(NSMutableArray*)getCommentsFrom:(NSInteger)from to:(NSInteger)to postID:(NSString*)postID withAccessToken:(NSString*)token
{
    NSMutableArray* allComments = [[NSMutableArray alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/fql?q=SELECT+text,fromid,id,time+FROM+comment+WHERE+post_id='%@'+ORDER+BY+time+DESC+LIMIT+%ld,%ld&access_token=%@",postID,(long)from,(long)to,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            NSArray* dataComments = [json objectForKey:@"data"];
            for(NSDictionary* comment in dataComments)
            {
                NSMutableDictionary* commentResult = [[NSMutableDictionary alloc] init];
                [commentResult s_setObject:[comment objectForKey:@"id"] forKey:kPostCommentIDDictKey];
                if ([comment objectForKey:@"text"])
                {
                    [commentResult s_setObject:[comment objectForKey:@"text"] forKey:kPostCommentTextDictKey];
                }
                NSNumber* time = [comment objectForKey:@"time"];
                NSDate* dateAddingComment = [NSDate dateWithTimeIntervalSince1970:[time longLongValue]];
                [commentResult s_setObject:dateAddingComment forKey:kPostCommentDateDictKey];
                
                //user info
                NSMutableDictionary* userResultDict = [[NSMutableDictionary alloc] init];
                NSDictionary* userInfo = [[self class] getUserInfoWithID:[NSString stringWithFormat:@"%@", comment[@"fromid"]] andToken:token];
                if(userInfo)
                {
                    if([userInfo objectForKey:@"id"])
                    {
                        [userResultDict s_setObject:[userInfo objectForKey:@"id"] forKey:kPostCommentAuthorIDDictKey];
                        [userResultDict s_setObject:[userInfo objectForKey:@"name"] forKey:kPostCommentAuthorNameDictKey];
                    
                        NSDictionary* picture = [userInfo objectForKey:@"picture"];
                        if(picture)
                        {
                            NSDictionary* pictureData = [picture objectForKey:@"data"];
                            if(pictureData)
                            {
                                [userResultDict s_setObject:[pictureData objectForKey:@"url"] forKey:kPostCommentAuthorAvaURLDictKey];
                            }
                        }
                        [userResultDict s_setObject:[FacebookRequest profileURLWithID:[userInfo objectForKey:@"id"]] forKey:kPostAuthorProfileURLDictKey];
                    }
                    [commentResult s_setObject:userResultDict forKey:kPostCommentAuthorDictKey];
                
                    [allComments addObject:commentResult];
                }
            }
        }
    }
    return allComments;
}

-(NSMutableArray*)getCommentsWithData:(NSData*)data andToken:(NSString*)token
{
    NSMutableArray* allComments = [[NSMutableArray alloc] init];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            if ([json objectForKey:@"data"])
            {
                NSArray* commentsArray = [json objectForKey:@"data"];
                for(NSDictionary* comment in commentsArray)
                {
                    NSMutableDictionary* commentResult = [[NSMutableDictionary alloc] init];
                    [commentResult s_setObject:[comment objectForKey:@"id"] forKey:kPostCommentIDDictKey];
                    if ([comment objectForKey:@"message"])
                        [commentResult s_setObject:[comment objectForKey:@"message"] forKey:kPostCommentTextDictKey];
                    NSString* createdAt = [comment objectForKey:@"created_time"];
                    NSDate* dateCreateComment = [[self class] convertFacebookDateToNSDate:createdAt];
                    [commentResult s_setObject:dateCreateComment forKey:kPostCommentDateDictKey];
                    
                    //author
                    NSMutableDictionary* userResultDict = [[NSMutableDictionary alloc] init];
                    NSDictionary* userInfo = [comment objectForKey:@"from"];
                    
                    NSString* commentAuthImage = [self getUserPhotoWithID:[userInfo objectForKey:@"id"] andToken:token];
                    if(commentAuthImage)
                    {
                        [userResultDict s_setObject:commentAuthImage forKey:kPostCommentAuthorAvaURLDictKey];
                    }
                    [userResultDict s_setObject:[userInfo objectForKey:@"name"] forKey:kPostCommentAuthorNameDictKey];
                    [userResultDict s_setObject:[userInfo objectForKey:@"id"] forKey:kPostCommentAuthorIDDictKey];
                    [userResultDict s_setObject:[FacebookRequest profileURLWithID:[userInfo objectForKey:@"id"]]
                                       forKey:kPostAuthorProfileURLDictKey];
                    
                    [commentResult s_setObject:userResultDict forKey:kPostCommentAuthorDictKey];
                    
                    //likes
                    NSNumber* likesCount = [NSNumber numberWithInt:0];
                    if ([comment objectForKey:@"like_count"])
                    {
                        likesCount = [comment objectForKey:@"like_count"];
                    }
                    
                    [commentResult s_setObject:likesCount forKey:kPostCommentLikesCountDictKey];
                    
                    [allComments addObject:commentResult];
                }
            }
        }
    }
    return allComments;
}

-(NSNumber*)countOfCommentsWithObjectID:(NSString*)objectID andToken:(NSString*)token
{
    NSNumber* numberOfCounts = [NSNumber numberWithInt:0];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/%@/comments?summary=1&access_token=%@",objectID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            if ([json objectForKey:@"summary"])
            {
                NSDictionary* summary = [json objectForKey:@"summary"];
                numberOfCounts = [summary objectForKey:@"total_count"];
                return numberOfCounts;
            }
        }
    }
    return numberOfCounts;
}

-(NSDictionary*)addCommentOnObjectID:(NSString*)objectID withUserID:(NSString*)userID withToken:(NSString*)token andMessage:(NSString*)message
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/%@/comments?access_token=%@",objectID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"message=%@",message] dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                if ([errorDescription[@"code"] integerValue] != 2)  // unexpected during comments wokrs fine - go on
                {
                    return nil;
                }
            }
            
            if ([json objectForKey:@"id"])
            {
                //An unexpected error has occurred. Please retry your request later. code = 2;
                NSMutableDictionary* info = [[NSMutableDictionary alloc] init];
                [info s_setObject:[NSDate date] forKey:kPostCommentDateDictKey];
                [info s_setObject:[json objectForKey:@"id"] forKey:kPostCommentIDDictKey];
                [info s_setObject:message forKey:kPostCommentTextDictKey];
                [info s_setObject:[NSNumber numberWithInt:0] forKey:kPostCommentLikesCountDictKey];
                return info;
            }
            else
            {
                NSArray* updatedComments = [self getCommentsOnPostID:objectID withToken:token];
                for(NSDictionary* comment in updatedComments)
                {
                    if([[comment objectForKey:kPostCommentTextDictKey] isEqualToString:message]&&[[[comment objectForKey:kPostCommentAuthorDictKey] objectForKey:kPostCommentAuthorIDDictKey] isEqualToString:userID])
                    {
                        NSMutableDictionary* info = [[NSMutableDictionary alloc] init];
                        [info s_setObject:[comment objectForKey:kPostCommentDateDictKey] forKey:kPostCommentDateDictKey];
                        [info s_setObject:[comment objectForKey:kPostCommentIDDictKey] forKey:kPostCommentIDDictKey];
                        [info s_setObject:message forKey:kPostCommentTextDictKey];
                        [info s_setObject:[NSNumber numberWithInt:0] forKey:kPostCommentLikesCountDictKey];
                        return info;
                    }
                }
            }
        }
    }
    return nil;
}

#pragma mark - Friends

-(NSArray*)getFriendsWithToken:(NSString*)token
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/me/friends?fields=link,name,id,picture&access_token=%@",token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];

LOAD_PAGE:
    {
        NSError *error = nil; NSURLResponse *response = nil;
        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if(data)
        {
            NSError* error = nil;
            NSDictionary* json = [NSJSONSerialization
                                  JSONObjectWithData:data
                                  options:kNilOptions
                                  error:&error];
            if(!error)
            {
                if (json[@"error"])
                {
                    NSDictionary *errorDescription = json[@"error"];
                    DLog(@"Facebook response with error : %@", errorDescription);
                    
                    if ([errorDescription[@"code"] integerValue] == 190)
                    {
                        [self invalidateSocialNetworkWithToken:token];
                    }
                    
                    return nil;
                }
                
                NSArray* dataArray = [json objectForKey:@"data"];
                for(NSDictionary* friend in dataArray)
                {
                    NSMutableDictionary* resultDictionary = [[NSMutableDictionary alloc] init];
                    [resultDictionary s_setObject:[friend objectForKey:@"id"] forKey:kFriendID];
                    [resultDictionary s_setObject:[friend objectForKey:@"link"] forKey:kFriendLink];
                    [resultDictionary s_setObject:[friend objectForKey:@"name"] forKey:kFriendName];
                    
                    NSDictionary* picture = [friend objectForKey:@"picture"];
                    if(picture)
                    {
                        NSDictionary* pictureData = [picture objectForKey:@"data"];
                        if(pictureData)
                        {
                            [resultDictionary s_setObject:[pictureData objectForKey:@"url"] forKey:kFriendPicture];
                        }
                    }
                    [resultArray addObject:resultDictionary];
                }
                
                if ([json[@"data"] count] && json[@"paging"][@"next"] &&
                    [json[@"paging"][@"next"] isKindOfClass:[NSString class]])
                {
                    NSString *nextPage = [json[@"paging"][@"next"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    NSURL *nextPageURL = [NSURL URLWithString:nextPage];
                    
                    if (nextPageURL)
                    {
                        request = [NSMutableURLRequest requestWithURL:nextPageURL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
                        goto LOAD_PAGE;
                    }
                }
            }
        }
    }
    
    return resultArray;
}

#pragma mark - Instruments

NSComparisonResult dateSortFunction(NSDictionary *s1, NSDictionary *s2, void *context)
{
    NSDate* date2 = [FacebookRequest convertFacebookDateToNSDate:[s1 objectForKey:@"created_time"]];
    NSDate* date1 = [FacebookRequest convertFacebookDateToNSDate:[s2 objectForKey:@"created_time"]];
    return [date1 compare:date2];
}

-(NSString*)stringBetweenString:(NSString*)start andString:(NSString*)end innerString:(NSString*)str
{
    NSScanner* scanner = [NSScanner scannerWithString:str];
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanUpToString:start intoString:NULL];
    if([scanner scanString:start intoString:NULL])
    {
        NSString* result = nil;
        if([scanner scanUpToString:end intoString:&result])
        {
            return result;
        }
    }
    return nil;
}

-(NSArray*)getHashTags:(NSString*)text
{
    NSMutableArray* hashTags = [[NSMutableArray alloc] init];
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:&error];
    NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
    for (NSTextCheckingResult *match in matches) {
        NSRange wordRange = [match rangeAtIndex:1];
        NSString* word = [NSString stringWithFormat:@"#%@",[text substringWithRange:wordRange] ];
        [hashTags addObject:word];
    }
    
    return hashTags;
}

- (NSArray *)getUserTags:(NSDictionary *)messageTagsDict
{
    NSMutableArray *userTags = [[NSMutableArray alloc] init];
    for (NSString *key in messageTagsDict.allKeys)
    {
        for (NSDictionary *tagDict in messageTagsDict[key])
        {
            [userTags addObject:tagDict[@"name"]];
        }
    }
    
    return userTags;
}

- (NSString *)fbidForSinglePhotoWithAttachment:(NSDictionary *)attachment
{
    NSArray *medias = attachment[@"media"];
    
    if (medias.count == 1)
    {
        id fbid = [medias firstObject][@"photo"][@"fbid"];
        
        if ([fbid isKindOfClass:[NSString class]])
        {
            return fbid;
        }
        else if ([fbid isKindOfClass:[NSNumber class]])
        {
            return [fbid stringValue];
        }
    }
    
    return  nil;
}

#pragma mark - Operation Queue

+ (NSOperationQueue *)operationQueue
{
    NSMutableDictionary *operationQueues = [FacebookRequest operationQueues];
    NSString *queueKey = [NSStringFromClass([self class]) stringByAppendingString:@".operationQueue"];
    
    if (!operationQueues[queueKey])
    {
        NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
        operationQueue.maxConcurrentOperationCount = 4;
        operationQueues[queueKey] = operationQueue;
    }
    
    return operationQueues[queueKey];
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

#pragma mark - Help methods
+ (NSString *)profileURLWithID:(NSString *)profileID
{
    if (![profileID isKindOfClass:[NSString class]])
    {
        profileID = [NSString stringWithFormat:@"%@", profileID];
    }
    
    return [kFacebookHTTPSBaseURL stringByAppendingPathComponent:profileID];
}

+ (NSString *)eventURLWithID:(NSString *)eventID
{
    return [kFacebookHTTPSBaseURL stringByAppendingPathComponent:[NSString stringWithFormat:@"events/%@", eventID]];
}

#pragma mark - Load Top story posts methods

- (NSDictionary *)getEventWithDictionary:(NSDictionary *)dataDict
{
    NSString *postId = [NSString stringWithFormat:@"%@", dataDict[@"eid"]];
    NSNumber* datePostTimestamp = [dataDict objectForKey:@"update_time"];
    NSDate* datePost = [NSDate dateWithTimeIntervalSince1970:[datePostTimestamp longLongValue]];
    
    NSMutableDictionary *eventInfo = [NSMutableDictionary new];
    
    NSMutableString *text = [NSMutableString new];
    if (dataDict[@"name"])
    {
        [text appendString:dataDict[@"name"]];
    }
    if (dataDict[@"description"])
    {
        if (text.length)
        {
            [text appendString:@"\n"];
        }
        
        [text appendString:dataDict[@"description"]];
    }
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.locale = [NSLocale currentLocale];
    
    BOOL isStartTime = dataDict[@"start_time"] && ![dataDict[@"start_time"] isKindOfClass:[NSNull class]];
    BOOL isEndTime = dataDict[@"end_time"] && ![dataDict[@"end_time"] isKindOfClass:[NSNull class]];
    
    if (isStartTime && isEndTime)
    {
        NSDate *startTime = [[self class] convertFacebookDateToNSDate:dataDict[@"start_time"]];
        NSDate *endTime = [[self class] convertFacebookDateToNSDate:dataDict[@"end_time"]];
        
        if (text.length)
        {
            [text appendString:@"\n"];
        }
        
        [text appendString:[NSString stringWithFormat:@"%@ %@ %@ %@",
                            NSLocalizedString(@"lskEventFrom", @"from"),
                            NSLocalizedString(@"lskEventTo", @"to"),
                            [formatter stringFromDate:startTime],
                            [formatter stringFromDate:endTime]]];
    }
    else if (isStartTime)
    {
        NSDate *startTime = [[self class] convertFacebookDateToNSDate:dataDict[@"start_time"]];
        
        if (text.length)
        {
            [text appendString:@"\n"];
        }
        
        [text appendString:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"lskEventStart", @"Begin at"), [formatter stringFromDate:startTime]]];
    }
    
    
    NSMutableDictionary *placeDictionary = nil;
    BOOL isVenue = dataDict[@"venue"] && [dataDict[@"venue"] isKindOfClass:[NSDictionary class]];
    if (isVenue)
    {
        NSDictionary *venue = dataDict[@"venue"];
        NSString *name = venue[@"name"];
        id oLatitude = venue[@"latitude"];
        id oLongitude = venue[@"longitude"];
        
        if (oLongitude && ![oLongitude isKindOfClass:[NSNull class]] &&
            oLatitude && ![oLatitude isKindOfClass:[NSNull class]])
        {
            if (name.length || ([dataDict[@"location"] isKindOfClass:[NSString class]] && [dataDict[@"location"] length]))
            {
                placeDictionary = [NSMutableDictionary new];
                
                if (!name.length)
                {
                    name = dataDict[@"location"];
                }
            }
            
            [placeDictionary s_setObject:@([oLatitude doubleValue]) forKey:kPlaceLatitudeDictKey];
            [placeDictionary s_setObject:@([oLongitude doubleValue]) forKey:kPlaceLongitudeDictKey];
        }
        
        [placeDictionary s_setObject:[NSString stringWithFormat:@"%@", venue[@"id"]] forKey:kPlaceIdDictKey];
        [placeDictionary s_setObject:name forKey:kPlaceNameDictKey];
        
        NSMutableString *address = [NSMutableString new];

        if ([venue[@"street"] isKindOfClass:[NSString class]] && [venue[@"street"] length])
        {
            [address appendString:venue[@"street"]];
        }
        if ([venue[@"city"] isKindOfClass:[NSString class]] && [venue[@"city"] length])
        {
            if (address.length)
            {
                [address appendString:@" "];
            }
            
            [address appendString:venue[@"city"]];
        }
        if ([venue[@"state"] isKindOfClass:[NSString class]] && [venue[@"state"] length])
        {
            if (address.length)
            {
                [address appendString:@" "];
            }
            
            [address appendString:venue[@"state"]];
        }
        if ([venue[@"country"] isKindOfClass:[NSString class]] && [venue[@"country"] length])
        {
            if (address.length)
            {
                [address appendString:@" "];
            }
            
            [address appendString:venue[@"country"]];
        }
        
        if (address.length)
        {
            [placeDictionary s_setObject:address forKey:kPlaceAddressDictKey];
        }
        
        if (placeDictionary)
        {
            [eventInfo setObject:@[placeDictionary] forKey:kPostPlacesListKey];
            
            if (!isStartTime)
            {
                [text appendString:@"\n"];
            }
            else
            {
                [text appendString:[NSString stringWithFormat:@"%@%@ %@", (isStartTime ? @" " : @""), NSLocalizedString(@"lskEventInPlace", @"in"), name]];
            }
        }
    }
    else if (dataDict[@"location"] && [dataDict[@"location"] isKindOfClass:[NSString class]])
    {
        if (!isStartTime)
        {
            [text appendString:@"\n"];
        }
        else
        {
            [text appendString:[NSString stringWithFormat:@"%@%@ %@", (isStartTime ? @" " : @""), NSLocalizedString(@"lskEventInPlace", @"in"), dataDict[@"location"]]];
        }
    }
    
    [eventInfo s_setObject:text forKey:kPostTextDictKey];
    [eventInfo s_setObject:datePost forKey:kPostDateDictKey];
    [eventInfo s_setObject:postId forKey:kPostIDDictKey];
    [eventInfo s_setObject:[NSString stringWithFormat:@"%@", dataDict[@"creator"]] forKey:@"creator"];
    [eventInfo s_setObject:@(kPostTypeEvent) forKey:kPostType];
    [eventInfo s_setObject:[[self class] eventURLWithID:postId] forKey:kPostLinkOnWebKey];
    
    if ((dataDict[@"pic_small"] && [dataDict[@"pic_small"] isKindOfClass:[NSString class]]) ||
        (dataDict[@"pic_big"] && [dataDict[@"pic_big"] isKindOfClass:[NSString class]]))
    {
        NSString *previewURL = dataDict[@"pic_small"];
        if (![previewURL isKindOfClass:[NSString class]])
        {
            previewURL = nil;
        }
        
        NSString *imageURL = dataDict[@"pic_big"];
        if (![imageURL isKindOfClass:[NSString class]])
        {
            imageURL = nil;
        }
        
        if (!previewURL)
        {
            previewURL = imageURL;
        }
        else if (!imageURL)
        {
            imageURL = previewURL;
        }
        
        if (imageURL && previewURL)
        {
            [eventInfo s_setObject:@[@{
                                        kPostMediaPreviewDictKey : previewURL,
                                        kPostMediaURLDictKey : imageURL,
                                        kPostMediaTypeDictKey : @"image"
                                    }]
                            forKey:kPostMediaSetDictKey];
        }
    }
    
    return eventInfo;
}

- (NSString *)stringFromSet:(NSSet *)set
{
    NSMutableString *string = [NSMutableString new];
    for (id item in set)
    {
        if (string.length)
        {
            [string appendString:@", "];
        }
        [string appendString:[NSString stringWithFormat:@"%@", item]];
    }
    
    return string;
}

- (NSArray *)addCreatorInfoToEvents:(NSArray *)events
                           fromData:(NSArray *)eventsData
                        accessToken:(NSString *)token
{
    if (!events.count)
    {
        return events;
    }
    
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:events.count];
    
    NSMutableSet *creatorIdsToProcess = [[NSMutableSet alloc] initWithCapacity:events.count];
    
    for (NSDictionary *eventInfo in eventsData)
    {
        NSString *creatorId = eventInfo[@"creator"];
        if (![creatorIdsToProcess containsObject:creatorId])
        {
            [creatorIdsToProcess addObject:creatorId];
        }
    }
    NSMutableDictionary *creatorsInfo = [[NSMutableDictionary alloc] initWithCapacity:creatorIdsToProcess.count];
    
    NSString *requestString = [NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT pic_square, name, uid FROM user WHERE uid IN (%@)&access_token=%@", [self stringFromSet:creatorIdsToProcess], token];
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            for (NSDictionary *creatorInfo in json[@"data"])
            {
                NSMutableDictionary *author = [[NSMutableDictionary alloc] initWithCapacity:creatorInfo.allKeys.count];
                
                NSString *uid = [NSString stringWithFormat:@"%@", creatorInfo[@"uid"]];
                NSString *name = ([creatorInfo[@"name"] isKindOfClass:[NSString class]] ? creatorInfo[@"name"] : nil);
                NSString *pictureURL = ([creatorInfo[@"pic_square"] isKindOfClass:[NSString class]] ? creatorInfo[@"pic_square"] : nil);
                NSString *profileURL = [FacebookRequest profileURLWithID:uid];
                
                [author s_setObject:uid forKey:kPostAuthorIDDictKey];
                [author s_setObject:name forKey:kPostAuthorNameDictKey];
                [author s_setObject:pictureURL forKey:kPostAuthorAvaURLDictKey];
                [author s_setObject:profileURL forKey:kPostAuthorProfileURLDictKey];
                
                if (uid)
                {
                    [creatorsInfo setObject:@{kPostAuthorDictKey : author} forKey:uid];
                    [creatorIdsToProcess removeObject:uid];
                }
            }
        }
    }
    
    NSMutableSet *groupsAndPagesCreatorsIds = [NSMutableSet new];
    
    if (creatorIdsToProcess.count)
    {
//        NSString *requestString = [NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT pic_square, name, gid, creator, website FROM group WHERE gid IN (%@)&access_token=%@", creatorIdsToProcess, token];
        NSString *requestString = [NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT name, gid, creator FROM group WHERE gid IN (%@)&access_token=%@", [self stringFromSet:creatorIdsToProcess], token];
        
        requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
        
        NSError *error = nil; NSURLResponse *response = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if(data)
        {
            NSError* error = nil;
            NSDictionary* json = [NSJSONSerialization
                                  JSONObjectWithData:data
                                  options:kNilOptions
                                  error:&error];
            if(!error)
            {
                if (json[@"error"])
                {
                    NSDictionary *errorDescription = json[@"error"];
                    DLog(@"Facebook response with error : %@", errorDescription);
                    
                    if ([errorDescription[@"code"] integerValue] == 190)
                    {
                        [self invalidateSocialNetworkWithToken:token];
                    }
                    
                    return nil;
                }
                
                for (NSDictionary *groupInfo in json[@"data"])
                {
                    NSString *gid = [NSString stringWithFormat:@"%@", groupInfo[@"gid"]];
                    NSString *creator = ([groupInfo[@"creator"] isKindOfClass:[NSString class]] ? groupInfo[@"creator"] : nil);
                    NSString *name = ([groupInfo[@"name"] isKindOfClass:[NSString class]] ? groupInfo[@"name"] : nil);
//                    NSString *pictureURL = ([groupInfo[@"pic_square"] isKindOfClass:[NSString class]] ? groupInfo[@"pic_square"] : nil);
//                    NSString *profileURL = ([groupInfo[@"website"] isKindOfClass:[NSString class]] ? groupInfo[@"website"] : nil);
                    
                    NSMutableDictionary *group = [[NSMutableDictionary alloc] initWithCapacity:groupInfo.allKeys.count];
                    
                    [group s_setObject:gid forKey:kPostGroupID];
                    [group s_setObject:name forKey:kPostGroupName];
                    [group s_setObject:@(kGroupTypeGroup) forKey:kPostGroupType];
                    [group s_setObject:creator forKey:@"creator"];
                    
                    [groupsAndPagesCreatorsIds addObject:creator];
                    [creatorsInfo setObject:@{@"groupInfo": group} forKey:gid];
                    
                    [creatorIdsToProcess removeObject:gid];
                }
                
                NSString *requestString = [NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT pic_square, name, uid FROM user WHERE uid IN (%@)&access_token=%@", [self stringFromSet:groupsAndPagesCreatorsIds], token];
                requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
                
                NSError *error = nil; NSURLResponse *response = nil;
                NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                if(data)
                {
                    NSError* error = nil;
                    NSDictionary* json = [NSJSONSerialization
                                          JSONObjectWithData:data
                                          options:kNilOptions
                                          error:&error];
                    if(!error)
                    {
                        if (json[@"error"])
                        {
                            NSDictionary *errorDescription = json[@"error"];
                            DLog(@"Facebook response with error : %@", errorDescription);
                            
                            if ([errorDescription[@"code"] integerValue] == 190)
                            {
                                [self invalidateSocialNetworkWithToken:token];
                            }
                            
                            return nil;
                        }
                        
                        for (NSDictionary *creatorInfo in json[@"data"])
                        {
                            NSMutableDictionary *author = [[NSMutableDictionary alloc] initWithCapacity:creatorInfo.allKeys.count];
                            
                            NSString *uid = [NSString stringWithFormat:@"%@", creatorInfo[@"uid"]];
                            NSString *name = ([creatorInfo[@"name"] isKindOfClass:[NSString class]] ? creatorInfo[@"name"] : nil);
                            NSString *pictureURL = ([creatorInfo[@"pic_square"] isKindOfClass:[NSString class]] ? creatorInfo[@"pic_square"] : nil);
                            NSString *profileURL = [FacebookRequest profileURLWithID:uid];
                            
                            [author s_setObject:uid forKey:kPostAuthorIDDictKey];
                            [author s_setObject:name forKey:kPostAuthorNameDictKey];
                            [author s_setObject:pictureURL forKey:kPostAuthorAvaURLDictKey];
                            [author s_setObject:profileURL forKey:kPostAuthorProfileURLDictKey];
                            
                            if (uid)
                            {
                                NSMutableDictionary *sourceInfo = nil;
                                
                                for (NSDictionary *creatorInfo in creatorsInfo)
                                {
                                    NSDictionary *groupInfo = creatorInfo[@"groupInfo"];
                                    if ([groupInfo[@"creator"] isEqualToString:uid])
                                    {
                                        sourceInfo = [creatorsInfo mutableCopy];
                                    }
                                }
                                
                                [sourceInfo setObject:author forKey:kPostAuthorDictKey];
                                NSString *key = sourceInfo[@"groupInfo"][@"kPostGroupID"];
                                
                                if (key)
                                {
                                    [creatorsInfo setObject:sourceInfo forKey:key];
                                }

                                [groupsAndPagesCreatorsIds removeObject:uid];
                            }
                        }
                    }
                }

            }
        }
    }
    
    if (creatorIdsToProcess.count)
    {
        NSString *requestString = [NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT name, page_id FROM page WHERE page_id IN (%@)&access_token=%@", [self stringFromSet:creatorIdsToProcess], token];
        
        requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
        
        NSError *error = nil; NSURLResponse *response = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        if(data)
        {
            NSError* error = nil;
            NSDictionary* json = [NSJSONSerialization
                                  JSONObjectWithData:data
                                  options:kNilOptions
                                  error:&error];
            if(!error)
            {
                if (json[@"error"])
                {
                    NSDictionary *errorDescription = json[@"error"];
                    DLog(@"Facebook response with error : %@", errorDescription);
                    
                    if ([errorDescription[@"code"] integerValue] == 190)
                    {
                        [self invalidateSocialNetworkWithToken:token];
                    }
                    
                    return nil;
                }
                
                for (NSDictionary *groupInfo in json[@"data"])
                {
                    NSString *gid = [NSString stringWithFormat:@"%@", groupInfo[@"page_id"]];
                    NSString *name = ([groupInfo[@"name"] isKindOfClass:[NSString class]] ? groupInfo[@"name"] : nil);
                    //                    NSString *pictureURL = ([groupInfo[@"pic_square"] isKindOfClass:[NSString class]] ? groupInfo[@"pic_square"] : nil);
                    //                    NSString *profileURL = ([groupInfo[@"website"] isKindOfClass:[NSString class]] ? groupInfo[@"website"] : nil);
                    
                    NSMutableDictionary *group = [[NSMutableDictionary alloc] initWithCapacity:groupInfo.allKeys.count];
                    
                    [group s_setObject:gid forKey:kPostGroupID];
                    [group s_setObject:name forKey:kPostGroupName];
                    [group s_setObject:@(kGroupTypePage) forKey:kPostGroupType];
                    
                    [creatorsInfo setObject:@{@"groupInfo": group} forKey:gid];
                    [creatorIdsToProcess removeObject:gid];
                }
            }
        }

    }
    
    for (NSDictionary *event in events)
    {
        NSString *creatorId = event[@"creator"];
        NSDictionary *creatorData = creatorsInfo[creatorId];
        
        if (creatorData)
        {
            NSMutableDictionary *mEvent = [event mutableCopy];
            [mEvent s_setObject:creatorData[kPostAuthorDictKey] forKey:kPostAuthorDictKey];
            NSDictionary *groupInfo = creatorData[@"groupInfo"];
            
            for (NSString *gKey in groupInfo.allKeys)
            {
                [mEvent s_setObject:groupInfo[gKey] forKey:gKey];
            }
            
            [results addObject:mEvent];
        }
        else
        {
            [results addObject:event];
        }
    }
    
    return results;
}

- (NSDictionary *)getTopStoryPostWithDictionary:(NSDictionary *)dataDict
                               forGroupWithInfo:(NSDictionary *)groupInfo
                                       andToken:(NSString *)token
{
    if([self isHiddenPost:dataDict])
    {
        return nil;
    }
    
    NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
    NSString* postID = [dataDict objectForKey:@"post_id"];
    NSNumber* datePostTimestamp = [dataDict objectForKey:@"created_time"];
    NSDate* datePost = [NSDate dateWithTimeIntervalSince1970:[datePostTimestamp longLongValue]];
    
    NSDictionary* attachment = [dataDict objectForKey:@"attachment"];
    
    __block NSString* text = nil;
    
    NSString* message = [dataDict objectForKey:@"message"];
    NSString* description = [dataDict objectForKey:@"description"];
    
    if([description isKindOfClass:[NSNull class]])
    {
        description = @"";
    }
    
    if (message.length)
    {
        text = message;
        
        NSArray* links = [self getLinksFromAttachment:attachment];
        
        for (NSString* link in links)
        {
            if([text rangeOfString:link].location == NSNotFound)
            {
                NSString* textWithLink = [NSString stringWithFormat:@"%@ %@",text,link];
                text = textWithLink;
            }
            break;
        }
    }
    else
    {
        
        NSArray* allLinks = [self getAttachmentHrefs:attachment];
        
        if(allLinks.count == 0)
        {
            return nil;
        }
        
        text = description;
        
        NSArray* links = [self getLinksFromAttachment:attachment];
        
        for (NSString* link in links)
        {
            if([text rangeOfString:link].location == NSNotFound)
            {
                NSString* textWithLink = [NSString stringWithFormat:@"%@ %@",text,link];
                text = textWithLink;
            }
            break;
        }
    }
    if([[dataDict objectForKey:@"place"] isKindOfClass:[NSNumber class]])
    {
        NSDictionary* placeInfo = [self getPlaceInfoWithID:[dataDict objectForKey:@"place"] andToken:token];
        
        if([placeInfo objectForKey:@"name"])
        {
            NSString* placeName = [placeInfo objectForKey:@"name"];
            text = [NSString stringWithFormat:@"%@\n%@", text, placeName];
        }
        
        NSMutableDictionary *placeDict = [[NSMutableDictionary alloc] initWithCapacity:8];
        [placeDict s_setObject:[[dataDict objectForKey:@"place"] stringValue] forKey:kPlaceIdDictKey];
        [placeDict s_setObject:[placeInfo objectForKey:@"name"] forKey:kPlaceNameDictKey];
        [placeDict s_setObject:@([placeInfo[@"latitude"] doubleValue]) forKey:kPlaceLatitudeDictKey];
        [placeDict s_setObject:@([placeInfo[@"longitude"] doubleValue]) forKey:kPlaceLongitudeDictKey];
        if ([placeInfo objectForKey:@"name"])
        {
            [placeDict s_setObject:[placeInfo objectForKey:@"name"] forKey:kPlaceAddressDictKey];
        }
        [resultDictionary setObject:@[placeDict] forKey:kPostPlacesListKey];
    }
    
    NSArray *idComponents = [postID componentsSeparatedByString:@"_"];
    NSString *identifier = idComponents.lastObject ?: postID;
    
    NSString *fbid = [self fbidForSinglePhotoWithAttachment:attachment];
    if (fbid)
    {
        identifier = fbid;
    }
    
    [resultDictionary s_setObject:identifier forKey:kPostIDDictKey];
    [resultDictionary s_setObject:datePost forKey:kPostDateDictKey];
    
    if (groupInfo)
    {
        [resultDictionary s_setObject:groupInfo[@"groupId"] forKey:kPostGroupID];
        [resultDictionary s_setObject:groupInfo[@"name"] forKey:kPostGroupName];
        [resultDictionary s_setObject:groupInfo[@"type"] forKey:kPostGroupType];
    }

    //Author
    NSString* authorID = [NSString stringWithFormat:@"%@", dataDict[@"actor_id"]];
    NSDictionary * authorInfo = [[self class] getUserInfoWithID:authorID andToken:token];
    
    if(!authorInfo)
    {
        return nil;
    }
    
    NSString* authorName = [authorInfo objectForKey:@"name"];
    NSString* userPicture = nil;
    if([authorInfo objectForKey:@"picture"])
    {
        NSDictionary* picture = [authorInfo objectForKey:@"picture"];
        if ([picture objectForKey:@"data"])
        {
            NSDictionary * pictureData = [picture objectForKey:@"data"];
            if (pictureData)
            {
                userPicture = [pictureData objectForKey:@"url"];
            }
        }
    }
    
    NSString *userProfileURLString = authorInfo[@"profileURL"];
    if (!userProfileURLString)
    {
        userProfileURLString = [FacebookRequest profileURLWithID:authorID];
    }
    
    NSMutableDictionary* personPosted = [[NSMutableDictionary alloc] init];
    
    [personPosted s_setObject:authorName forKey:kPostAuthorNameDictKey];
    
    if(userPicture)
    {
        [personPosted s_setObject:userPicture forKey:kPostAuthorAvaURLDictKey];
    }
    
    [personPosted s_setObject:authorID forKey:kPostAuthorIDDictKey];
    [personPosted s_setObject:userProfileURLString forKey:kPostAuthorProfileURLDictKey];
    
    [resultDictionary s_setObject:personPosted forKey:kPostAuthorDictKey];
    
    //comments
    NSNumber* countOfComments = [[dataDict objectForKey:@"comment_info"] objectForKey:@"comment_count"];
    NSArray* comments = [self getCommentsOnPostID:postID offset:countOfComments.intValue-kMaxCountOfCommentsrefresh withLimit:kMaxCountOfCommentsrefresh withToken:token];
    
    [resultDictionary s_setObject:comments forKey:kPostCommentsDictKey];
    [resultDictionary s_setObject:countOfComments forKey:kPostCommentsCountDictKey];
    
    //likes
    
    NSNumber* countOfLikes = [[dataDict objectForKey:@"like_info"] objectForKey:@"like_count"];
    
    [resultDictionary s_setObject:countOfLikes forKey:kPostLikesCountDictKey];
    
    //media
    NSArray * photos = [self getObjectPhotosFromDictionary:attachment andToken:token];
    NSMutableArray* mediaResultArray = [[NSMutableArray alloc] init];
    
    NSArray * videos = [self getObjectVideosFromDictionary:attachment andToken:token];
    
    for(NSDictionary* videoInfo in videos)
    {
        NSMutableDictionary* mediaResultDict = [[NSMutableDictionary alloc] init];
        
        NSString* sourceVideoURL = [videoInfo objectForKey:@"videoURL"];
        
        if([sourceVideoURL rangeOfString:@"youtube.com"].location != NSNotFound)
        {
            [mediaResultDict s_setObject:[self linkForYoutubeVideo:sourceVideoURL] forKey:kPostMediaURLDictKey];
        }
        else if ([sourceVideoURL rangeOfString:@"vimeo.com"].location != NSNotFound)
        {
            [mediaResultDict s_setObject:[self linkForVimeoVideo:sourceVideoURL] forKey:kPostMediaURLDictKey];
        }
        else
        {
            [mediaResultDict s_setObject:sourceVideoURL forKey:kPostMediaURLDictKey];
        }
        
        NSString* previewPhotoURL = [videoInfo objectForKey:@"videoPreview"];
        if(previewPhotoURL)
        {
            [mediaResultDict s_setObject:previewPhotoURL forKey:kPostMediaPreviewDictKey];
        }
        [mediaResultDict s_setObject:@"video" forKey:kPostMediaTypeDictKey];
        [mediaResultArray addObject:mediaResultDict];
    }
#warning CHECK_THIS
    
    if (mediaResultArray.count==0)
    {
//        for(NSString* photoURL in photos)
        for(NSDictionary* photoInfo in photos)
        {
//            if([photoURL rangeOfString:@"_n.jpg"].location==NSNotFound)
//            {
//                NSMutableDictionary* mediaResultDict = [[NSMutableDictionary alloc] init];
//            
//                if([photoURL rangeOfString:@"_s.jpg"].location!=NSNotFound||[photoURL rangeOfString:@"_q.jpg"].location!=NSNotFound)
//                {
//                    NSString* highQualityImage = [NSString stringWithFormat:@"%@%@", [photoURL substringToIndex:[photoURL length] - 6],@"_n.jpg"];
//                    [mediaResultDict s_setObject:highQualityImage forKey:kPostMediaURLDictKey];
//                }
//                else
//                {
//                    [mediaResultDict s_setObject:photoURL forKey:kPostMediaURLDictKey];
//                }
//            
//                [mediaResultDict s_setObject:photoURL forKey:kPostMediaPreviewDictKey];
//                [mediaResultDict s_setObject:@"image" forKey:kPostMediaTypeDictKey];
//                [mediaResultArray addObject:mediaResultDict];
//            }
            
            
            [mediaResultArray addObject:photoInfo];
        }
    }
    
    if(mediaResultArray.count > 0)
    {
        [resultDictionary s_setObject:mediaResultArray forKey:kPostMediaSetDictKey];
    }
    
    //link
    
    NSArray* links = [self getAttachmentHrefs:attachment];
    
    NSString* link = nil;
    
    if(links)
    {
        link = [links firstObject];
    }
    
    if(link)
    {
        resultDictionary[kPostLinkOnWebKey] = link;
    }
    
    //hash tags
    NSArray* hashTags = [self getHashTags:text];
    NSArray *userTags = [self getUserTags:dataDict[@"message_tags"]];
    
    NSArray *postIdComponents = [postID componentsSeparatedByString:@"_"];
    if (postIdComponents.count > 1)
    {
        NSString *postSelfLink = [NSString stringWithFormat:@"https://www.facebook.com/%@/posts/%@", postIdComponents[0], postIdComponents[1]];
        text = [[text stringByReplacingOccurrencesOfString:postSelfLink withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    
    if (dataDict[@"target_id"] && !groupInfo && ![dataDict[@"target_id"] isKindOfClass:[NSNull class]])
    {
        NSDictionary *userInfo = [[self class] getUserInfoWithID:[dataDict[@"target_id"] stringValue] andToken:token];
        if (userInfo[@"name"])
        {
            text = [[NSString stringWithFormat:@"%@ %@\n\n", NSLocalizedString(@"lskPostToPerson", @"Facebook post 'to' person"), userInfo[@"name"]] stringByAppendingString:text];
        }
    }
    
    [resultDictionary s_setObject:text forKey:kPostTextDictKey];
    
    [resultDictionary s_setObject:[hashTags arrayByAddingObjectsFromArray:userTags] forKey:kPostTagsListKey];
    
    return resultDictionary;
}

- (NSString *)linkForYoutubeVideo:(NSString *)sourceURL
{
    Semaphor* semaphor = [[Semaphor alloc] init];
    
    __block NSString *resutlURL = nil;
    NSString *videoID = [self stringBetweenString:@"/v/" andString:@"?" innerString:sourceURL];
    NSString *videoLink = [NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@",videoID];
    
    LBYouTubeExtractor* youtubeExtractor = [[LBYouTubeExtractor alloc] initWithURL:[NSURL URLWithString:videoLink] quality:1];
    [youtubeExtractor extractVideoURLWithCompletionBlock:^(NSURL *videoURL, NSError *error) {

        if (videoURL)
        {
            resutlURL = videoURL.absoluteString;
        }
        else
        {
            resutlURL = videoLink;
        }

        [semaphor lift:kSemaphoreKey];
    }];
    [semaphor waitForKey:kSemaphoreKey];
    
    return resutlURL;
}

- (NSString *)linkForVimeoVideo:(NSString *)sourceURL
{
    __block NSString *resutl = sourceURL;
    dispatch_semaphore_t videoExtractSemaphore = dispatch_semaphore_create(0);
    
    NSString *vimdeoID = [self vimdeoIDFromSourceURL:sourceURL];
    

    dispatch_async(dispatch_get_main_queue(), ^{
        
        [YTVimeoExtractor fetchVideoURLFromID:vimdeoID
                                      quality:YTVimeoVideoQualityMedium
                            completionHandler:^(NSURL *videoURL, NSError *error, YTVimeoVideoQuality quality) {
                                if (error || !videoURL)
                                {
                                    DLog(@"Can't extract vimeo video: %@ becaouse of: %@", sourceURL, error.localizedDescription);
                                }
                                else
                                {
                                    resutl = videoURL.absoluteString;
                                }
                                
                                dispatch_semaphore_signal(videoExtractSemaphore);
                            }];
        
    });
    dispatch_semaphore_wait(videoExtractSemaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*30));
    
    return resutl;
}

- (NSString *)vimdeoIDFromSourceURL:(NSString *)sourceURL
{
    NSString *vimeoID;
    
    NSString *regexString = [NSString stringWithFormat:@"clip_id=[0-9]+&"];
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:nil];
    NSArray *matches = [regex matchesInString:sourceURL options:0 range:NSMakeRange(0, [sourceURL length])];
    
    if (matches.count)
    {
        NSTextCheckingResult *match = [matches lastObject];
        NSRange matchRange = [match range];
        NSString *matchString = [sourceURL substringWithRange:matchRange];
        
        vimeoID = [matchString stringByReplacingOccurrencesOfString:@"clip_id=" withString:@""];
        vimeoID = [vimeoID stringByReplacingOccurrencesOfString:@"&" withString:@""];
    }
    
    return vimeoID;
}

- (NSArray *)getAttachmentHrefs:(NSDictionary *)attachments
{
    NSMutableArray * resultArray = [[NSMutableArray alloc] init];
    
    NSArray * media = [attachments objectForKey:@"media"];
    
    if([attachments objectForKey:@"href"])
    {
        [resultArray addObject:[attachments objectForKey:@"href"]];
    }
    
    for(NSDictionary* mediaItem in media)
    {
        if([mediaItem objectForKey:@"href"])
        {
            [resultArray addObject:[mediaItem objectForKey:@"href"]];
        }
    }
    
    return resultArray;
}

- (NSDictionary* )getPlaceInfoWithID:(NSNumber *) placeID andToken:(NSString *) token
{
    NSMutableDictionary *resultDict = [[NSMutableDictionary alloc] init];
    
    NSString* const kFeedFields = @"name,latitude,longitude";
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/fql?q=SELECT+%@+FROM+place+WHERE+page_id='%lld'&access_token=%@&count=10", kFeedFields, [placeID longLongValue], token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:token];
                }
                
                return nil;
            }
            
            NSArray * data = [json objectForKey:@"data"];
            for(NSDictionary* place in data)
            {
                [resultDict setObject:[place objectForKey:@"name"] forKey:@"name"];
                [resultDict setObject:[place objectForKey:@"latitude"] forKey:@"latitude"];
                [resultDict setObject:[place objectForKey:@"longitude"] forKey:@"longitude"];
            }
        }
    }
    
    return resultDict;
}

- (NSMutableArray*)getObjectPhotosFromDictionary:(NSDictionary *)attachment andToken:(NSString*)token
{
    NSMutableArray* photosResult = [[NSMutableArray alloc] init];

    __block NSInteger imagesToProcessCount = 0;
    dispatch_semaphore_t imagesProcessed = dispatch_semaphore_create(0);
    
    if([attachment objectForKey:@"media"])
    {
        NSArray* media = [attachment objectForKey:@"media"];
        for (NSDictionary* mediaDict in media)
        {
            if([mediaDict objectForKey:@"type"] && [[mediaDict objectForKey:@"type"] isEqualToString:@"link"])
            {
                NSString* photoURL = [mediaDict objectForKey:@"src"];
                if(photoURL.length > 0)
                {
                    NSRange urlRange = [photoURL rangeOfString:@"url="];
                    if (urlRange.location == NSNotFound)
                    {
                        urlRange = [photoURL rangeOfString:@"src="];
                    }
                    
                    if ([photoURL rangeOfString:@"_s.png"].location != NSNotFound)
                    {
                        NSString *previewURL = photoURL;
                        NSString* resultPhotoURL = [previewURL stringByReplacingOccurrencesOfString:@"_s.png" withString:@"_n.png"];
                        
                        [photosResult addObject:@{ kPostMediaTypeDictKey : @"image", kPostMediaPreviewDictKey : previewURL, kPostMediaURLDictKey : resultPhotoURL }];
                    }
                    else if (urlRange.location != NSNotFound &&
                            (urlRange.location + urlRange.length) < photoURL.length)
                    {
                        NSString *mediaURL = [photoURL substringFromIndex:(urlRange.location + urlRange.length)];
                        mediaURL = [mediaURL stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        if ([NSURL URLWithString:mediaURL])
                        {
                            [photosResult addObject:@{ kPostMediaTypeDictKey : @"image", kPostMediaPreviewDictKey : photoURL, kPostMediaURLDictKey : mediaURL }];
                        }
                        else
                        {
                            [photosResult addObject:@{ kPostMediaTypeDictKey : @"image", kPostMediaURLDictKey : photoURL }];
                        }
                    }
                    else
                    {
                        [photosResult addObject:@{ kPostMediaTypeDictKey : @"image", kPostMediaURLDictKey : photoURL }];
                    }
                }
            }
            else if([mediaDict[@"type"] isEqualToString:@"photo"] && [mediaDict objectForKey:@"photo"])
            {
                NSDictionary* photoDict = [mediaDict objectForKey:@"photo"];
                NSArray* images = [photoDict objectForKey:@"images"];
                
                __block NSString *previewURL = images.firstObject[@"src"];
                __block NSString *imageURL = images.lastObject[@"src"];
                
                if (!images.count)
                {
                    previewURL = mediaDict[@"src"];
                    imageURL = mediaDict[@"src"];
                }
                
                
                NSString *imageObjID = mediaDict[@"photo"][@"fbid"];
                if (imageObjID && ((!previewURL && !imageURL) || [previewURL isEqualToString:imageURL]))
                {
                    ++imagesToProcessCount;
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        
                        NSString *imageObjURL = [[NSString stringWithFormat: @"https://graph.facebook.com/%@", imageObjID] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:imageObjURL]
                                                                               cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                                           timeoutInterval:kInternetIntervalTimeout];
                        NSError *error = nil;
                        NSURLResponse *response = nil;
                                                                                            
                        NSData *imageObjData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                        if (!error && imageObjData)
                        {
                            NSDictionary *imageObj = [NSJSONSerialization JSONObjectWithData:imageObjData
                                                                                     options:kNilOptions
                                                                                       error:&error];
                            
                            if (error == nil && imageObj[@"error"] == nil)
                            {
                                NSArray *images = imageObj[@"images"];
                                if ([images isKindOfClass:[NSArray class]])
                                {
                                    if (!previewURL)
                                    {
                                        previewURL = images.lastObject[@"source"];
                                    }
            
                                    static CGFloat screenHeight = 0;
                                    static CGFloat screenWidht = 0;
                                    
                                    if (screenHeight < 0.001 || screenWidht < 0.001)
                                    {
                                        screenWidht = [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale;
                                        screenHeight = [UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale;
                                    }
                                    
                                    NSInteger iImage;
                                    for (iImage = images.count - 1; iImage >= 0; --iImage)
                                    {
                                        CGFloat width = [images[iImage][@"width"] floatValue];
                                        CGFloat height = [images[iImage][@"height"] floatValue];
                                        
                                        if (MAX(width, height) > MAX(screenWidht, screenHeight))
                                        {
                                            break;
                                        }
                                    }
                                    
                                    if (iImage + 1 < images.count && iImage)
                                    {
                                        iImage++;
                                    }
                                    
                                    imageURL = images[iImage][@"source"];
                                }
                            }
                            else if (previewURL.length)
                            {
                                // Next code based on idea, that full size image will have url:
                                // https://scontent-b.xx.fbcdn.net/hphotos-xap1/t1.0-9/10491086_10152558560128770_8992148139094685230_n.jpg
                                // in case it preview have url:
                                // https://scontent-b.xx.fbcdn.net/hphotos-xap1/t1.0-9/q71/s480x480/10491086_10152558560128770_8992148139094685230_n.jpg
                                // it can change in feature, in this case regexp and/or logic should be changed.
                                
                                DLog(@"Can't get full size image URL using request to FB, will try process URL");
                                
                                static NSString * const canBeProcessedPattern = @"/hphotos-\\w*-?\\w*?/?\\w*/t1.0-9/\\w?\\d?\\d?/?[s,p]\\d*x\\d*/";
                                
                                NSString *processingURL = previewURL;
                                NSRange processingURLRange = NSMakeRange(0, processingURL.length);
                                
                                NSError *regexpError = nil;
                                NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:canBeProcessedPattern options:0 error:&regexpError];
                                NSArray* matches = [regexp matchesInString:processingURL options:0 range:processingURLRange];
                                
                                if (matches.count)
                                {
                                    static NSString * const leftSidePattern = @"/hphotos-\\w*-?\\w*?/";
                                    static NSString * const rightSidePattern = @"/t1\\.0-9/";
                                    
                                    regexpError = nil;
                                    NSRegularExpression *leftSide = [NSRegularExpression regularExpressionWithPattern:leftSidePattern options:0 error:&regexpError];
                                    NSArray *leftSideMatches = [leftSide matchesInString:processingURL options:0 range:processingURLRange];
                                    NSTextCheckingResult *leftMatch = leftSideMatches.firstObject;
                                    
                                    regexpError = nil;
                                    NSRegularExpression *rightSide = [NSRegularExpression regularExpressionWithPattern:rightSidePattern options:0 error:&regexpError];
                                    NSArray *rightSideMatches = [rightSide matchesInString:processingURL options:0 range:processingURLRange];
                                    NSTextCheckingResult *rightMatch = rightSideMatches.firstObject;
                                    
                                    if (leftMatch.range.location + leftMatch.range.length < rightMatch.range.location)
                                    {
                                        NSInteger location = leftMatch.range.location + leftMatch.range.length;
                                        NSInteger length = rightMatch.range.location - location;
                                        processingURL = [processingURL stringByReplacingCharactersInRange:NSMakeRange(location, length) withString:@""];
                                        
                                        processingURLRange = NSMakeRange(0, processingURL.length);
                                    }
                                    
                                    static NSString * const extensionPattern = @"\\.[j,p][p,n]g";
                                    regexpError = nil;
                                    NSRegularExpression *extension = [NSRegularExpression regularExpressionWithPattern:extensionPattern options:0 error:&regexpError];
                                    NSArray *extensionMatches = [extension matchesInString:processingURL options:0 range:processingURLRange];
                                    
                                    if (extensionMatches.count)
                                    {
                                        NSRange extensionRange = [extensionMatches.firstObject range];
                                        
                                        if (extensionRange.location + extensionRange.length < processingURL.length)
                                        {
                                            processingURL = [processingURL substringToIndex:extensionRange.location + extensionRange.length];
                                            processingURLRange = NSMakeRange(0, processingURL.length);
                                        }
                                    }
                                    else
                                    {
                                        processingURL = nil;
                                        processingURLRange = NSMakeRange(0, 0);
                                    }
                                    
                                    if (processingURL)
                                    {
                                        static NSString * const sizePattern = @"/\\w?\\d?\\d?/?[s,p]\\d*x\\d*/";
                                        
                                        NSError *regexpError = nil;
                                        NSRegularExpression* regexp = [NSRegularExpression regularExpressionWithPattern:sizePattern options:0 error:&regexpError];
                                        NSArray* matches = [regexp matchesInString:processingURL options:0 range:processingURLRange];

                                        if (matches.count == 1)
                                        {
                                            imageURL = [processingURL stringByReplacingCharactersInRange:[matches.firstObject range] withString:@"/"];
#ifdef DEBUG
                                            NSURL *url  = [NSURL URLWithString:[imageURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
                                            NSURLRequest *request = [NSURLRequest requestWithURL:url];
                                            NSURLResponse *response = nil;
                                            NSError *error = nil;
                                            NSData *imageData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

                                            if (!imageData)
                                            {
                                                DLog(@"Processed URL : \"%@\" are wrong (no data)", imageURL);
                                            }
                                            else if (![UIImage imageWithData:imageData])
                                            {
                                                DLog(@"Processed URL : \"%@\" are wrong (wrong data)", imageURL);
                                            }
                                            else
                                            {
                                                DLog(@"Processed URL : \"%@\" from URL : \"%@\" are ok!", imageURL, previewURL);
                                            }
#endif
                                        }
                                        else
                                        {
                                            DLog(@"URL \"%@\" can't be automaticaly processed", previewURL);
                                        }
                                    }
                                    else
                                    {
                                        DLog(@"URL \"%@\" can't be automaticaly processed", previewURL);
                                    }
                                }
                                else
                                {
                                    DLog(@"URL \"%@\" can't be automaticaly processed", previewURL);
                                }
                            }
                            else
                            {
                                DLog(@"URL \"%@\" can't be automaticaly processed", previewURL);
                            }
                        }
                        else
                        {
                            DLog(@"Can't get information about image! Because of: %@", error.localizedDescription);
                        }
                        
                        if (!imageURL)
                        {
                            if (previewURL)
                            {
                                imageURL = previewURL;
                            }
                            else
                            {
                                DLog(@"Can't get any link to image: %@", mediaDict);
                            }
                        }
                        
                        if (!previewURL)
                        {
                            previewURL = imageURL;
                        }
                        
                        if (previewURL && imageURL)
                        {
                            [photosResult addObject:@{ kPostMediaTypeDictKey : @"image", kPostMediaPreviewDictKey : previewURL, kPostMediaURLDictKey : imageURL }];
                        }
                        else if (mediaDict[@"src"] && [mediaDict[@"src"] length])
                        {
                            [photosResult addObject:@{ kPostMediaTypeDictKey : @"image", kPostMediaPreviewDictKey : mediaDict[@"src"], kPostMediaURLDictKey : mediaDict[@"src"]}];
                        }
                        
                        if (!--imagesToProcessCount)
                        {
                            dispatch_semaphore_signal(imagesProcessed);
                        }
                    });
                }
                else if (previewURL && imageURL)
                {
                    [photosResult addObject:@{ kPostMediaTypeDictKey : @"image", kPostMediaPreviewDictKey : previewURL, kPostMediaURLDictKey : imageURL }];
                }
            }
        }
    }
    
    if (imagesToProcessCount)
    {
        dispatch_semaphore_wait(imagesProcessed, DISPATCH_TIME_FOREVER); //DISPATCH_TIME_NOW + NSEC_PER_SEC*180);
    }
    
    return photosResult;
}

-(NSMutableArray*)getObjectVideosFromDictionary:(NSDictionary *)attachment andToken:(NSString*)token
{
    NSMutableArray* photosResult = [[NSMutableArray alloc] init];
    if([attachment objectForKey:@"media"])
    {
        NSArray* media = [attachment objectForKey:@"media"];
        for (NSDictionary* mediaDict in media)
        {
            if([mediaDict objectForKey:@"type"])
            {
                if([[mediaDict objectForKey:@"type"] isEqualToString:@"video"])
                {
                    NSDictionary * video = [mediaDict objectForKey:@"video"];
                    if(video)
                    {
                        NSMutableDictionary * resultDict = [[NSMutableDictionary alloc] init];
                        NSString* videoURL = [video objectForKey:@"source_url"];
                        
                        if(videoURL)
                        {
                            [resultDict s_setObject:videoURL forKey:@"videoURL"];
                            [resultDict s_setObject:[mediaDict objectForKey:@"src"] forKey:@"videoPreview"];
                            [photosResult addObject:resultDict];
                        }
                    }
                }
            }
        }
    }
    
    return photosResult;
}

- (BOOL) isHiddenPost:(NSDictionary *)post
{
    NSDictionary* attachment = [post objectForKey:@"attachment"];
    
    if([attachment objectForKey:@"media"])
    {
        NSArray* media = [attachment objectForKey:@"media"];
        for (NSDictionary* mediaDict in media)
        {
            if([mediaDict objectForKey:@"type"])
            {
                if([[mediaDict objectForKey:@"type"] isEqualToString:@"link"])
                {
                    if(![mediaDict objectForKey:@"href"])
                    {
                        return YES;
                    }
                }
            }
        }
    }
    return NO;
}

#pragma mark - links

- (NSArray*)getLinksFromAttachment:(NSDictionary *) attachments
{
    NSMutableArray * resultArray = [[NSMutableArray alloc] init];
    
    NSArray* hrefs = [self getAttachmentHrefs:attachments];
    
    for(NSString* link in hrefs)
    {
        if ([link rangeOfString:@"www.facebook.com/photo"].location == NSNotFound && [link rangeOfString:@"www.facebook.com/video"].location == NSNotFound  && [link rangeOfString:@"www.facebook.com/album"].location == NSNotFound && [link rangeOfString:@"www.facebook.com/media"].location == NSNotFound)
        {
            [resultArray addObject:link];
        }
    }
    
    return resultArray;
}

- (BOOL)isLinkExcept:(NSString *) link
{
    if ([link rangeOfString:@"www.facebook.com/photo"].location != NSNotFound || [link rangeOfString:@"www.facebook.com/video"].location != NSNotFound  || [link rangeOfString:@"www.facebook.com/album"].location != NSNotFound || [link rangeOfString:@"www.facebook.com/media"].location != NSNotFound)
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)getUsersWhosLikedPostWithID:(NSString *)postId accessToken:(NSString *)accessToken
{
    if (!postId)
    {
        NSAssert(postId, @"postId can't be nil");
        return NO;
    }

    NSString *requestString = [NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT uid, name, pic_square, profile_url FROM user WHERE uid IN (SELECT user_id FROM like WHERE post_id == \"%@\")&access_token=%@", postId, accessToken];
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if (json[@"error"])
            {
                NSDictionary *errorDescription = json[@"error"];
                DLog(@"Facebook response with error : %@", errorDescription);
                
                if ([errorDescription[@"code"] integerValue] == 190)
                {
                    [self invalidateSocialNetworkWithToken:accessToken];
                }
                
                return NO;
            }
            
            NSManagedObjectContext *objectContext = [WDDDataBase sharedDatabase].managedObjectContext;
            NSFetchRequest *snRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([SocialNetwork class])];
            snRequest.predicate = [NSPredicate predicateWithFormat:@"SELF.accessToken == %@", accessToken];
            NSArray *objects = [objectContext executeFetchRequest:snRequest error:&error];
            
            if (!objects.count || error)
            {
                NSLog(@"Can't found socialnetowork with key: %@, error: %@", accessToken, error.localizedDescription);
                return NO;
            }
            
            SocialNetwork *socialNetwork = objects.firstObject;
            NSString *norimilizedPostID = postId;
            if ([postId rangeOfString:@"_"].location != NSNotFound)
            {
                norimilizedPostID = [postId componentsSeparatedByString:@"_"].lastObject;
            }
            
            NSFetchRequest *postRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Post class])];
            NSPredicate *postPredicate = [NSPredicate predicateWithFormat:@"postID == %@ AND subscribedBy.socialNetwork == %@", norimilizedPostID, socialNetwork];
            postRequest.predicate = postPredicate;
            objects = [objectContext executeFetchRequest:postRequest error:&error];
            
            if (!objects.count || error)
            {
                NSLog(@"Can't found post with id: %@, error: %@", postId, error.localizedDescription);
                return NO;
            }
            
            Post *post = objects.firstObject;
            
            NSFetchRequest *userRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([UserProfile class])];
            NSArray* users = [json objectForKey:@"data"];
            for (NSDictionary *userInfo in users)
            {
                NSString *userId = [NSString stringWithFormat:@"%@", userInfo[@"uid"]];
                NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"userID == %@", userId];
                userRequest.predicate = userPredicate;
                error = nil;
                objects = [objectContext executeFetchRequest:userRequest error:&error];
                UserProfile *profile = nil;
                
                if (objects.count)
                {
                    profile = objects.firstObject;
                }
                else
                {
                    profile = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([FaceBookOthersProfile class])];
                    profile.userID = userId;
                }
                
                profile.name = userInfo[@"name"];
                profile.avatarRemoteURL = userInfo[@"pic_square"];
                profile.profileURL = userInfo[@"profile_url"];
                [profile addLikedPostsObject:post];
            }
            
            [[WDDDataBase sharedDatabase] save];
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)updateLikesAndFavoritesForPostWithID:(NSString *)postId accessToken:(NSString *)accessToken
{
    NSInteger commentsCount = 0;
    NSInteger likesCount = 0;
    BOOL success = YES;
    
    // Comments
    NSString *requestString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/comments?summary=true&access_token=%@", postId, accessToken];
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        success &= (!error && !json[@"error"]);
        
        if (json[@"error"])
        {
            NSDictionary *errorDescription = json[@"error"];
            DLog(@"Facebook response with error : %@", errorDescription);
            
            if ([errorDescription[@"code"] integerValue] == 190)
            {
                [self invalidateSocialNetworkWithToken:accessToken];
            }
            
            return NO;
        }
        
        if(!error)
        {
            commentsCount = [json[@"summary"][@"total_count"] integerValue];
        }
    }
    
    success &= (data != nil);
    
    
    // Lies
    requestString = [NSString stringWithFormat:@"https://graph.facebook.com/%@/likes?summary=true&access_token=%@", postId, accessToken];
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    error = nil;
    response = nil;
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        success &= (!error && !json[@"error"]);
        
        if (json[@"error"])
        {
            NSDictionary *errorDescription = json[@"error"];
            DLog(@"Facebook response with error : %@", errorDescription);
            
            if ([errorDescription[@"code"] integerValue] == 190)
            {
                [self invalidateSocialNetworkWithToken:accessToken];
            }
            
            return NO;
        }
        
        if(!error)
        {
            likesCount = [json[@"summary"][@"total_count"] integerValue];
        }
    }
    
    success &= (data != nil);
    
    if (success)
    {
        NSManagedObjectContext *objectContext = [WDDDataBase sharedDatabase].managedObjectContext;
        NSFetchRequest *snRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([SocialNetwork class])];
        snRequest.predicate = [NSPredicate predicateWithFormat:@"SELF.accessToken == %@", accessToken];
        NSArray *objects = [objectContext executeFetchRequest:snRequest error:&error];
        
        if (!objects.count || error)
        {
            NSLog(@"Can't found socialnetowork with key: %@, error: %@", accessToken, error.localizedDescription);
            return NO;
        }
        
        SocialNetwork *socialNetwork = objects.firstObject;
        
        NSFetchRequest *postRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Post class])];
        NSPredicate *postPredicate = [NSPredicate predicateWithFormat:@"postID == %@ AND subscribedBy.socialNetwork == %@", postId, socialNetwork];
        postRequest.predicate = postPredicate;
        objects = [objectContext executeFetchRequest:postRequest error:&error];
        
        if (!objects.count || error)
        {
            NSLog(@"Can't found post with id: %@, error: %@", postId, error.localizedDescription);
            return NO;
        }
        
        Post *post = objects.firstObject;
        post.commentsCount = @(commentsCount);
        post.likesCount = @(likesCount);
        post.updateTime = [NSDate date];
        [[WDDDataBase sharedDatabase] save];
    }
    
    return NO;
}

- (void)invalidateSocialNetworkWithToken:(NSString *)accessToken
{
    SocialNetwork *network = [[WDDDataBase sharedDatabase] fetchObjectsWithEntityName:NSStringFromClass([SocialNetwork class])
                                                                        withPredicate:[NSPredicate predicateWithFormat:@"accessToken == %@ AND type == %d", accessToken, kSocialNetworkFacebook]
                                                                      sortDescriptors:nil].firstObject;
    network.accessToken = nil;
    network.activeState = @NO;
    [[WDDDataBase sharedDatabase] save];
//    [network updateSocialNetworkOnParseNow:YES];
    [network updateSocialNetworkOnParse];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[WDDDataBase sharedDatabase] save];
    });
}

#pragma mark - Like/Unlike help methods
#pragma mark

- (BOOL)likeOnObjectID:(NSString *)objectID withToken:(NSString *)token
{
    return [self likeUnlikeRequestForObjectID:objectID
                                    withToken:token
                                requestMethod:@"POST"];
}

- (BOOL)unlikeOnObjectID:(NSString *)objectID withToken:(NSString *)token
{
    return [self likeUnlikeRequestForObjectID:objectID
                                    withToken:token
                                requestMethod:@"DELETE"];
}

- (BOOL)likeUnlikeRequestForObjectID:(NSString *)objectID withToken:(NSString *)token requestMethod:(NSString *)method
{
    DLog(@"Will link/unlike post with id %@; method %@", objectID, method);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://graph.facebook.com/%@/likes", objectID]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:method];
    [request setHTTPBody:[[NSString stringWithFormat:@"access_token=%@",token] dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error)
    {
        DLog(@"Got error during like : %@", error.localizedDescription);
    }
    
    NSString* status = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (status)
    {
        DLog(@"Application response : %@", status);
    }
    
    if([status isEqualToString:@"true"])
    {
        return YES;
    }
    return NO;
}

- (void)getLocationsWithLocation:(WDDLocation*)location
                     accessToken:(NSString*)accessToken
                      completion:(void(^)(NSArray *locations))completion
{
    void(^completionBlk)(NSArray *locations) = [completion copy];
    
    int desiredAccuracy = (int)(3 * location.accuracy);
    if (desiredAccuracy < 150)
    {
        desiredAccuracy = 150;
    }
    
    NSString *requestString = [NSString stringWithFormat: @"https://graph.facebook.com/search?type=place&center=%f,%f&distance=%d&limit=50",location.coordinate.latitude, location.coordinate.longitude, desiredAccuracy];
    if (accessToken) requestString = [requestString stringByAppendingFormat:@"&access_token=%@", accessToken];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"GET"];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
    {
        NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:50];
        [JSON[@"data"] enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop)
        {
            WDDLocation *location = [[WDDLocation alloc] init];
            location.coordinate = CLLocationCoordinate2DMake([dict[@"location"][@"latitude"] doubleValue], [dict[@"location"][@"longitude"] doubleValue]);
            location.name       = dict[@"name"];
            location.facebookID = dict[@"id"];
            [resultArray addObject:location];
        }];

        DLog(@"location: %@\n request: %@\n results: %@\n", location, request, resultArray);
        
        if (completionBlk) completionBlk([resultArray sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCompare:)]]]);
    }
                                                                                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
    {
        if (completionBlk) completionBlk(nil);
    }];
    
    [operation start];
}

@end