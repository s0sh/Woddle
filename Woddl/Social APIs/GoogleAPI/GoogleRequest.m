//
//  GoogleRequest.m
//  Woddl
//
//  Created by Александр Бородулин on 04.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "GoogleRequest.h"
#import "NetworkRequest.h"
#import "LBYouTubeExtractor.h"
#import "Semaphor.h"
#import <HTMLParser.h>
#import "GooglePlusGetActivitiesOperation.h"

#import "WDDDataBase.h"
#import "GooglePlusProfile.h"
#import "GooglePlusPost.h"
#import "GoogleOthersProfile.h"

NSDateFormatter* googlePlusDF;

@implementation GoogleRequest

static NSString* kSemaphoreKey = @"mySemaphore";
static NSString* kSemaphoreQueueKey = @"queueSemaphore";

static CGFloat const kInternetIntervalTimeout = 30.0;

-(id)initWithToken:(NSString*)token
{
    if(self=[super init])
    {
        updateToken = [self stringBetweenString:@"refresh_token=" andString:@"" innerString:token];
        self.accessToken = [self refreshToken:updateToken];
    }
    return self;
}

- (NSArray *)getPostsWithCount:(NSUInteger)count andUserID:(NSString *)userID
{
    NSArray* friendsList = [self followsPeople];
    NSMutableArray* statusesResult = [[NSMutableArray alloc] init];
    [statusesResult addObjectsFromArray:[self loadPostsForPeson:userID maxCount:count]];
    
    NSInteger postsCount = 0;
    if (friendsList.count)
    {
        postsCount = 100 / friendsList.count;
    }
    
    if (!postsCount)
    {
        postsCount = 1;
    }
    
    for(NSDictionary* personDict in friendsList)
    {
        [statusesResult addObjectsFromArray:[self loadPostsForPeson:personDict[@"id"] maxCount:postsCount]];
    }
    
    NSArray *resultArray = [self statusesWithAddedCommentsForStatuses:statusesResult];
    NSArray *resultArrayWithMedia = [self statusesWithAddedMediaForStatuses:resultArray];
    
    return resultArrayWithMedia;
}

- (NSArray *)loadPostsForPeson:(NSString *)personId maxCount:(NSInteger)count
{
    NSString *pageId = nil;
    NSMutableArray *posts = [[NSMutableArray alloc] initWithCapacity:count];
    
    NSFetchRequest *userRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([GooglePlusProfile class])];
    NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"userID == %@", personId];
    userRequest.predicate = userPredicate;
    NSArray *profiles = [[WDDDataBase sharedDatabase].managedObjectContext executeFetchRequest:userRequest error:nil];
    
    BOOL needPageId = ([[profiles.firstObject posts] count] == 0);
    
LOAD_MORE_POSTS:
    {
        NSArray *statusesArray = [self getStatusesFromPersonID:personId count:count pageId:pageId needPageId:YES];
        statusesArray = [self getStatusesFromActivities:statusesArray isSearch:NO];
        
        NSArray *sorted = [statusesArray sortedArrayUsingFunction:timeSort context:nil];
        
        NSInteger postsToRemove = 0;
        BOOL havePostsToRemove = NO;
        
        BOOL needToFindPreviousPost = (([[profiles.firstObject posts] count] != 0) && (sorted.count != 0));
        NSInteger postIndex = sorted.count - 1;
        
        while (needToFindPreviousPost && postIndex >= 0 && (havePostsToRemove || !postsToRemove))
        {
            NSString *postId = [[sorted objectAtIndex:postIndex] objectForKey:kPostIDDictKey];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"postID == %@", postId];
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([GooglePlusPost class])];
            request.predicate = predicate;
            NSArray *result = [[WDDDataBase sharedDatabase].managedObjectContext executeFetchRequest:request error:nil];
            
            if (result.count || !pageId)
            {
                havePostsToRemove = YES;
                postsToRemove = postIndex;
                break;
            }
            else
            {
                ++count;
            }
            
            --postIndex;
        }
        
        if (postsToRemove)
        {
            sorted = [sorted subarrayWithRange:NSMakeRange(postsToRemove, sorted.count - postsToRemove)];
            [posts addObjectsFromArray:sorted];
        }
        else if (needToFindPreviousPost)
        {
            [posts addObjectsFromArray:sorted];
            
            pageId = [[sorted.lastObject objectForKey:kPostAuthorDictKey] objectForKey:@"pageId"];
            goto LOAD_MORE_POSTS;
        }
        else
        {
            [posts addObjectsFromArray:sorted];
        }
    }
    
    if (!needPageId)
    {
        NSMutableArray *tmp = [[NSMutableArray alloc] initWithCapacity:posts.count];
        for (NSDictionary *post in posts)
        {
            NSMutableDictionary *mPost = [post mutableCopy];
            NSMutableDictionary *mAuthor = [post[kPostAuthorDictKey] mutableCopy];
            [mAuthor removeObjectForKey:@"pageId"];
            [mPost setObject:mAuthor forKey:kPostAuthorDictKey];
            
            [tmp addObject:mPost];
        }
        
        posts = tmp;
    }
    
    return posts;
}

- (NSArray *)getPostsWithCount:(NSUInteger)count from:(NSString*)from
{
    NSArray* friendsList = [self followsPeople];
    NSMutableArray* statusesResult = [[NSMutableArray alloc] init];
    
    NSInteger onePersonCount = count;
    
    if (friendsList.count)
    {
        onePersonCount = count / friendsList.count;
        if (!onePersonCount)
        {
            onePersonCount = 1;
        }
    }
    
    for(NSDictionary* personDict in friendsList)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userID == %@", personDict[@"id"]];
        NSFetchRequest *friendRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([GooglePlusProfile class])];
        friendRequest.predicate = predicate;
        
        NSString *pageId = nil;
        NSArray *profiles = [[WDDDataBase sharedDatabase].managedObjectContext executeFetchRequest:friendRequest error:nil];
        if (profiles.count)
        {
            pageId = [profiles.firstObject pageId];
        }
        
        NSArray* statusesArray = [self getStatusesFromPersonID:personDict[@"id"] count:onePersonCount pageId:pageId needPageId:YES];
        statusesArray = [self getStatusesFromActivities:statusesArray isSearch:NO];
        [statusesResult addObjectsFromArray:statusesArray];
    }
    
    NSArray *resultArray = [self statusesWithAddedCommentsForStatuses:statusesResult];
    NSArray *resultArrayWithMedia = [self statusesWithAddedMediaForStatuses:resultArray];
    
    return resultArrayWithMedia;
}

- (NSArray *)searchPostsWithSearchText:(NSString *)searchText
                                 limit:(NSUInteger)limit
{
    NSArray* activities = [self getStatusesFromSearchWithText:searchText
                                                        limit:limit];
    NSArray *statuses = [self getStatusesFromActivities:activities isSearch:YES];
    NSArray *resultArray = [self statusesWithAddedCommentsForStatuses:statuses];
    NSArray *resultArrayWithMedia = [self statusesWithAddedMediaForStatuses:resultArray];
    return resultArrayWithMedia;
}

- (NSArray *)getStatusesFromActivities:(NSArray *)activities isSearch:(BOOL)isSearch
{
    NSMutableArray *statuses = [[NSMutableArray alloc] initWithCapacity:activities.count];

    for(NSDictionary* activityDict in activities)
    {
        NSMutableDictionary* resultDictionary = [[NSMutableDictionary alloc] init];
        NSString* text = [[activityDict objectForKey:@"object"] objectForKey:@"content"];
        if (![text length])
        {
            NSArray *attachments = activityDict[@"object"][@"attachments"];
            if ([attachments isKindOfClass:[NSArray class]] && attachments.count)
            {
                text = attachments.firstObject[@"content"];
            }
        }
        NSString* postID = [activityDict objectForKey:@"id"];
        NSDate* datePost = [GoogleRequest convertGoogleDateToNSDate:[activityDict objectForKey:@"published"]];
        
        NSError *error;
        HTMLParser *parser = [[HTMLParser alloc] initWithString:text error:&error];
        HTMLNode *bodyNode = [parser body];
        text = [bodyNode allContents];
        
        [resultDictionary s_setObject:[NSNumber numberWithBool:isSearch] forKey:kPostIsSearched];
        
        [resultDictionary s_setObject:postID forKey:kPostIDDictKey];
        [resultDictionary s_setObject:datePost forKey:kPostDateDictKey];
        
        //author
        NSDictionary* authorDict = [activityDict objectForKey:@"actor"];
        NSString* authorID = [authorDict objectForKey:@"id"];
        NSString* authorName = [authorDict objectForKey:@"displayName"];
        
        NSString* userPicture = [[authorDict objectForKey:@"image"] objectForKey:@"url"];
        NSString *profileURLString = authorDict[@"url"];
        
        NSMutableDictionary* personPosted = [[NSMutableDictionary alloc] init];
        
        [personPosted s_setObject:authorName forKey:kPostAuthorNameDictKey];
        if(userPicture)
            [personPosted s_setObject:userPicture forKey:kPostAuthorAvaURLDictKey];
        [personPosted s_setObject:authorID forKey:kPostAuthorIDDictKey];
        [personPosted s_setObject:profileURLString forKey:kPostAuthorProfileURLDictKey];
        [personPosted s_setObject:authorDict[@"pageId"] forKey:@"pageId"];
        
        [resultDictionary s_setObject:personPosted forKey:kPostAuthorDictKey];
        
        //media
        
        NSDictionary* object = [activityDict objectForKey:@"object"];
        NSArray* attachments = [object objectForKey:@"attachments"];
        if(attachments)
        {
            [resultDictionary s_setObject:attachments forKey:@"attachmentsGoogle"];
        }
        
        for (NSDictionary *attachment in attachments)
        {
            if ([attachment[@"objectType"] isEqualToString:@"article"])
            {
                NSString *displayName = attachment[@"displayName"];
                NSString *url = attachment[@"url"];
                
                text = [text stringByAppendingFormat:@"\n %@ %@", displayName, url];
            }
            else if ([attachment[@"objectType"] isEqualToString:@"album"])
            {
                NSString *displayName = attachment[@"displayName"];
                NSString *url = attachment[@"url"];
                
                NSString *albumInfo = [NSString stringWithFormat:@"%@ %@ %@", NSLocalizedString(@"lskAddAlbum", @"Google+ album post"), displayName, url];
                if (text.length)
                {
                    text = [text stringByAppendingFormat:@"\n %@", albumInfo];
                }
                else
                {
                    text = albumInfo;
                }
            }
        }
        
        NSString *placeName = activityDict[@"placeName"];
        NSDictionary *locationInfo = activityDict[@"location"];
        
        if (locationInfo)
        {
            NSMutableDictionary *placeDict = [[NSMutableDictionary alloc] initWithCapacity:8];
            [placeDict s_setObject:postID forKey:kPlaceIdDictKey];
            [placeDict s_setObject:locationInfo[@"displayName"] forKey:kPlaceNameDictKey];
            [placeDict s_setObject:locationInfo[@"address"][@"formatted"] forKey:kPlaceAddressDictKey];
            [placeDict s_setObject:@([locationInfo[@"position"][@"latitude"] doubleValue]) forKey:kPlaceLatitudeDictKey];
            [placeDict s_setObject:@([locationInfo[@"position"][@"longitude"] doubleValue]) forKey:kPlaceLongitudeDictKey];

            [resultDictionary setObject:@[placeDict] forKey:kPostPlacesListKey];
        }
        
        
        if (!text.length && [object[@"objectType"] isEqualToString:@"note"] &&
            ![object[@"attachments"] count] && [object[@"url"] length] && !placeName.length)
        {
            NSString *url = object[@"url"];
            text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"lskSharedNote", @"Google+ note shared"), url];
        }
        
        if(!text)
        {
            if (placeName.length)
            {
                text = [NSString stringWithFormat:NSLocalizedString(@"lskCheckinAction", @"G+ checkin action"), placeName];
            }
            else
            {
                text = @" ";
            }
            [resultDictionary s_setObject:text forKey:kPostTextDictKey];
        }
        else
        {
            [resultDictionary s_setObject:text forKey:kPostTextDictKey];
        }
        
        //link
        resultDictionary[kPostLinkOnWebKey] = activityDict[@"url"];
        
        [resultDictionary s_setObject:object[@"plusoners"][@"totalItems"] forKey:kPostLikesCountDictKey];
        
        NSArray* hashTags = [self getHashTags:text];
        [resultDictionary s_setObject:hashTags forKey:kPostTagsListKey];
        
        [statuses addObject:resultDictionary];
    }
    
    return statuses;
}

- (NSArray *)statusesWithAddedMediaForStatuses:(NSArray *)statuses
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
    for(NSDictionary* itemDict in statuses)
    {
        NSMutableDictionary* resultDictionary = [itemDict mutableCopy];
        
        NSArray* attachments = [itemDict objectForKey:@"attachmentsGoogle"];
        NSMutableArray* mediaResultArray = [[NSMutableArray alloc] init];
        for(NSDictionary* attachment in attachments)
        {
            NSString* type = [attachment objectForKey:@"objectType"];
            if([type isEqualToString:@"video"])
            {
                NSMutableDictionary* mediaResultDict = [[NSMutableDictionary alloc] init];
                //NSString* videoLink = [[attachment objectForKey:@"embed"] objectForKey:@"url"];
                NSString* videoLink = [attachment objectForKey:@"url"];
                
                Semaphor* semaphor = [[Semaphor alloc] init];
                
                LBYouTubeExtractor* youtubeExtractor = [[LBYouTubeExtractor alloc] initWithURL:[NSURL URLWithString:videoLink] quality:1];
                [youtubeExtractor extractVideoURLWithCompletionBlock:^(NSURL *videoURL, NSError *error) {
                    
                    if (videoURL)
                    {
                        [mediaResultDict s_setObject:[videoURL absoluteString]
                                            forKey:kPostMediaURLDictKey];
                    }
                    else
                    {
                        [mediaResultDict s_setObject:videoLink forKey:kPostMediaURLDictKey];
                    }
                    [semaphor lift:kSemaphoreKey];
                }];
                
                [semaphor waitForKey:kSemaphoreKey];
                
                [mediaResultDict s_setObject:@"video" forKey:kPostMediaTypeDictKey];
                
                NSString* imagePreview = [[attachment objectForKey:@"image"] objectForKey:@"url"];
                [mediaResultDict s_setObject:imagePreview forKey:kPostMediaPreviewDictKey];
                [mediaResultArray addObject:mediaResultDict];
            }
            else if([type isEqualToString:@"photo"])
            {
                NSMutableDictionary* mediaResultDict = [[NSMutableDictionary alloc] init];
                NSString* image = [[attachment objectForKey:@"image"] objectForKey:@"url"];
                [mediaResultDict s_setObject:image forKey:kPostMediaURLDictKey];
                [mediaResultDict s_setObject:@"image" forKey:kPostMediaTypeDictKey];
                [mediaResultDict s_setObject:image forKey:kPostMediaPreviewDictKey];
                [mediaResultArray addObject:mediaResultDict];
            }
            else if([type isEqualToString:@"article"] && attachment[@"fullImage"])
            {
                NSString *imageURL = attachment[@"image"][@"url"];
                NSString *fullImageURL = attachment[@"fullImage"][@"url"];
                
                NSMutableDictionary* mediaResultDict = [[NSMutableDictionary alloc] init];
                [mediaResultDict s_setObject:fullImageURL forKey:kPostMediaURLDictKey];
                [mediaResultDict s_setObject:@"image" forKey:kPostMediaTypeDictKey];
                [mediaResultDict s_setObject:imageURL forKey:kPostMediaPreviewDictKey];
                [mediaResultArray addObject:mediaResultDict];
            }
            else if([type isEqualToString:@"album"] && attachment[@"thumbnails"])
            {
                for (NSDictionary *imageInfo in attachment[@"thumbnails"])
                {
                    NSMutableDictionary* mediaResultDict = [[NSMutableDictionary alloc] init];
                    [mediaResultDict s_setObject:imageInfo[@"image"][@"url"] forKey:kPostMediaURLDictKey];
                    [mediaResultDict s_setObject:@"image" forKey:kPostMediaTypeDictKey];
                    [mediaResultDict s_setObject:imageInfo[@"image"][@"url"] forKey:kPostMediaPreviewDictKey];
                    [mediaResultArray addObject:mediaResultDict];
                }
            }
        }
        [resultDictionary s_setObject:mediaResultArray forKey:kPostMediaSetDictKey];
        
        [resultArray addObject:resultDictionary];
    }
    
    return resultArray;
}

- (NSArray *)statusesWithAddedCommentsForStatuses:(NSArray *)statuses
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    for(NSDictionary* itemDict in statuses)
    {
        NSMutableDictionary* resultDictionary = [itemDict mutableCopy];
        NSArray* comments = [self getCommentsFromActivityID:[itemDict objectForKey:kPostIDDictKey]];
        NSNumber* countOfComments = [NSNumber numberWithInteger:comments.count];
        
        [resultDictionary s_setObject:comments forKey:kPostCommentsDictKey];
        [resultDictionary s_setObject:countOfComments forKey:kPostCommentsCountDictKey];
        
        [resultArray addObject:resultDictionary];
    }
    return [resultArray copy];
}

NSComparisonResult dateSort(NSDictionary *s1, NSDictionary *s2, void *context)
{
    NSDate* d1 = [s1 objectForKey:@"date"];
    NSDate* d2 = [s2 objectForKey:@"date"];
    return [d1 compare:d2];
}

NSComparisonResult timeSort(NSDictionary *s1, NSDictionary *s2, void *context)
{
    NSDate* d1 = [s1 objectForKey:@"time"];
    NSDate* d2 = [s2 objectForKey:@"time"];
    return [d1 compare:d2];
}

-(NSArray*)followsPeople
{
    NSArray* resultArray = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://www.googleapis.com/plus/v1/people/me/people/visible?access_token=%@",self.accessToken]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    
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
            resultArray = [json objectForKey:@"items"];
        }
    }
    return resultArray;
}

-(NSArray*)getFriends
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
    NSArray* friends = [self followsPeople];
    
    for(NSDictionary* friend in friends)
    {
        NSMutableDictionary* resultDictionary = [[NSMutableDictionary alloc] init];
        
        [resultDictionary s_setObject:[friend objectForKey:@"id"] forKey:kFriendID];
        [resultDictionary s_setObject:[friend objectForKey:@"url"] forKey:kFriendLink];
        [resultDictionary s_setObject:[friend objectForKey:@"displayName"] forKey:kFriendName];
        
        NSDictionary* image = [friend objectForKey:@"image"];
        
        if(image)
        {
            [resultDictionary s_setObject:[image objectForKey:@"url"] forKey:kFriendPicture];
        }
        
        [resultArray addObject:resultDictionary];
    }
    
    return resultArray;
}

- (NSArray *)getStatusesFromPersonID:(NSString *)personID
                               count:(NSInteger)count
                              pageId:(NSString *)pageId
                          needPageId:(BOOL)needPageId
{
    NSMutableArray* resultArray = nil;
    
    NSString *requestString = nil;
    
    if (pageId)
    {
        requestString = [NSString stringWithFormat: @"https://www.googleapis.com/plus/v1/people/%@/activities/public?access_token=%@&maxResults=%ld&pageToken=%@",personID,self.accessToken, (long)count, pageId];
    }
    else
    {
        requestString = [NSString stringWithFormat: @"https://www.googleapis.com/plus/v1/people/%@/activities/public?access_token=%@&maxResults=%ld",personID,self.accessToken, (long)count];
    }
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    //fields=id,published&
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
            NSString *nextPageToken = json[@"nextPageToken"];
            if (nextPageToken && needPageId)
            {
                resultArray = [[NSMutableArray alloc] initWithCapacity:[json[@"items"] count]];
                for (NSDictionary *item in json[@"items"])
                {
                    NSMutableDictionary *mItem = [item mutableCopy];
                    NSMutableDictionary *authorInfo = [item[@"actor"] mutableCopy];
                    [authorInfo setObject:nextPageToken forKey:@"pageId"];
                    [mItem setObject:authorInfo forKey:@"actor"];
                    
                    [resultArray addObject:mItem];
                }
            }
            else
            {
                resultArray = [json objectForKey:@"items"];
            }
        }
    }
    return resultArray;
}

- (NSArray *)getStatusesFromSearchWithText:(NSString *)searchText
                                     limit:(NSInteger)limit
{
    NSArray* resultArray = nil;
    NSString *queryString = [searchText  stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://www.googleapis.com/plus/v1/activities?query=%@&orderBy=recent&access_token=%@&maxResults=%ld",queryString,self.accessToken, (long)limit]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    
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
            resultArray = [json objectForKey:@"items"];
        }
    }
    
    return resultArray;
}

-(NSArray*)getCommentsFromActivityID:(NSString*)activityID
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://www.googleapis.com/plus/v1/activities/%@/comments?access_token=%@&maxResults=5&sortOrder=descending",activityID,self.accessToken]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    resultArray = [self getCommentsWithData:data];
    return resultArray;
}

-(NSArray*)getCommentsFromActivityID:(NSString*)activityID count:(NSUInteger)count
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://www.googleapis.com/plus/v1/activities/%@/comments?access_token=%@&maxResults=%lu&sortOrder=descending",activityID,self.accessToken,(unsigned long)count]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    resultArray = [self getCommentsWithData:data];
    return resultArray;
}

-(NSMutableArray*)getCommentsWithData:(NSData*)data
{
    NSMutableArray* resultArray = nil;
    if(data)
    {
        resultArray = [[NSMutableArray alloc] init];
        
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            NSArray* comments = [json objectForKey:@"items"];
            for(NSDictionary* comment in comments)
            {
                NSMutableDictionary* commentResult = [[NSMutableDictionary alloc] init];
                [commentResult s_setObject:[comment objectForKey:@"id"] forKey:kPostCommentIDDictKey];
                if([comment objectForKey:@"object"])
                {
                    NSDictionary* object = [comment objectForKey:@"object"];
                    
                    NSError *error;
                    NSString *tempCommentString = [object objectForKey:@"content"];
                    HTMLParser *parser = [[HTMLParser alloc] initWithString:tempCommentString error:&error];
                    HTMLNode *bodyNode = [parser body];
                    tempCommentString = [bodyNode allContents];
                    
                    [commentResult s_setObject:tempCommentString forKey:kPostCommentTextDictKey];
                }
                NSDate* datePost = [GoogleRequest convertGoogleDateToNSDate:[comment objectForKey:@"updated"]];
                [commentResult s_setObject:datePost forKey:kPostCommentDateDictKey];
                
                //author
                NSMutableDictionary* userResultDict = [[NSMutableDictionary alloc] init];
                NSDictionary* userInfo = [comment objectForKey:@"actor"];
                
                NSString* commentAuthImage = [[userInfo objectForKey:@"image"] objectForKey:@"url"];
                [userResultDict s_setObject:commentAuthImage forKey:kPostCommentAuthorAvaURLDictKey];
                [userResultDict s_setObject:[userInfo objectForKey:@"displayName"] forKey:kPostCommentAuthorNameDictKey];
                [userResultDict s_setObject:[userInfo objectForKey:@"id"] forKey:kPostCommentAuthorIDDictKey];
                [userResultDict s_setObject:userInfo[@"url"] forKey:kPostAuthorProfileURLDictKey];
                
                [commentResult s_setObject:userResultDict forKey:kPostCommentAuthorDictKey];
                
                [resultArray addObject:commentResult];
            }
        }
    }
    return resultArray;
}

- (void)addCommentWithMessage:(NSString *)message toPostURL:(NSString *)postURL
{
    NSString *niceMessage = [message stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://www.googleapis.com/plus/v1/people/me/moments/vault"/*userIdpostURL,accessToken*/]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    request.HTTPMethod = @"POST";
    
    NSMutableDictionary *httpBodyDict   = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *result         = [[NSMutableDictionary alloc] init];
    
    httpBodyDict[@"type"]   = @"http://schemas.google.com/CommentActivity";
    httpBodyDict[@"target"] = @{@"url":postURL};
    httpBodyDict[@"result"] = result;

    result[@"url"]  = postURL;
    result[@"type"] = @"http://schema.org/Comment";
    result[@"name"] = @"Comment";
    result[@"text"] = niceMessage;

    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:httpBodyDict options:NSJSONWritingPrettyPrinted error:nil];
    
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    
//    NSError *error = nil; NSURLResponse *response = nil;
//    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
//    if(data)
//    {
//        NSError* error = nil;
//        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data
//                                                             options:kNilOptions
//                                                               error:&error];
//    }
}

-(void)AddActivity
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://www.googleapis.com/plus/v1/people/me/moments/vault?access_token=%@",self.accessToken]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"POST"];
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSMutableDictionary *httpBodyDict   = [[NSMutableDictionary alloc] init];
    httpBodyDict[@"type"]   = @"http://schemas.google.com/CommentActivity";
    NSMutableDictionary* target = [[NSMutableDictionary alloc] init];
    [target s_setObject:@"http://schema.org/CreativeWork" forKey:@"url"];
    //[target s_setObject:@"z13lhbpwmmqaefby504chnyptobwfhgzuyo0k" forKey:@"id"];
    httpBodyDict[@"target"]   = target;
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    [result s_setObject:@"http://schema.org/Comment" forKey:@"type"];
    [result s_setObject:@"https://www.googleapis.com/plus/v1/activities/z13lhbpwmmqaefby504chnyptobwfhgzuyo0k/comments" forKey:@"url"];
    [result s_setObject:@"Interesting Post" forKey:@"name"];
    [result s_setObject:@"I like it vary mach :)" forKey:@"text"];
    httpBodyDict[@"result"]   = result;
    
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:httpBodyDict options:NSJSONWritingPrettyPrinted error:nil];
    NSError *error = nil; NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if(error)
    {
        DLog(@"Error: %@", [error localizedDescription]);
    }
}

#pragma mark - Instruments

-(NSArray*)getHashTags:(NSString*)text
{
    NSMutableArray* hashTags = [[NSMutableArray alloc] init];
    if(text)
    {
        NSError *error = nil;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#(\\w+)" options:0 error:&error];
        NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
        for (NSTextCheckingResult *match in matches)
        {
            NSRange wordRange = [match rangeAtIndex:1];
            NSString* word = [NSString stringWithFormat:@"#%@",[text substringWithRange:wordRange] ];
            [hashTags addObject:word];
        }
    }
    return hashTags;
}

+(NSDate*)convertGoogleDateToNSDate:(NSString*)created_at
{
    @synchronized(googlePlusDF)
    {
        if(!googlePlusDF)
        {
            googlePlusDF = [[NSDateFormatter alloc] init];
            [googlePlusDF setLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]];
            [googlePlusDF setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
            [googlePlusDF setTimeZone:[NSTimeZone systemTimeZone]];
        }
    
        NSDate* convertedDate = [googlePlusDF dateFromString:created_at];
    
        return convertedDate;
    }
}


-(NSString*)refreshToken:(NSString*)refreshToken
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://accounts.google.com/o/oauth2/token"]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[[NSString stringWithFormat:@"client_id=%@&client_secret=%@&refresh_token=%@&grant_type=refresh_token", kGooglePlusClientID, kGooglePlusClientSecret, refreshToken] dataUsingEncoding:NSUTF8StringEncoding]];
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
            if ([json objectForKey:@"access_token"])
            {
                NSString* token = [json objectForKey:@"access_token"];
                return token;
            }
        }
    }
    return nil;
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

- (BOOL)getUsersWhosLikedPostWithID:(NSString *)postId accessToken:(NSString *)accessToken
{
    if (!postId)
    {
        NSAssert(postId, @"postId can't be nil");
        return NO;
    }
    
    NSString *requestString = [NSString stringWithFormat:@"https://www.googleapis.com/plus/v1/activities/%@/people/plusoners?access_token=%@", postId, self.accessToken];
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
            
            NSFetchRequest *userRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([UserProfile class])];
            NSArray* users = [json objectForKey:@"items"];
            for (NSDictionary *userInfo in users)
            {
                NSString *userId = [NSString stringWithFormat:@"%@", userInfo[@"id"]];
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
                    profile = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([GoogleOthersProfile class])];
                    profile.userID = userId;
                }
                
                profile.name = userInfo[@"displayName"];
                profile.avatarRemoteURL = userInfo[@"image"][@"url"];
                profile.profileURL = userInfo[@"url"];
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
    NSError *error = nil;
    
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
    
    BOOL updated = NO;
    Post *post = objects.firstObject;
    
    NSString *requestString = [NSString stringWithFormat:@"https://www.googleapis.com/plus/v1/activities/%@?access_token=%@", postId, self.accessToken];
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *requestURL = [NSURL URLWithString:requestString];
    
    NSHTTPURLResponse *response = nil;
    NSError *requestError = nil;
    NSData *postData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:requestURL]
                                             returningResponse:&response
                                                         error:&requestError];
    if (postData && !requestError)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:postData
                                                             options:kNilOptions
                                                               error:&error];
        if(!error)
        {
            id likesCount = json[@"object"][@"plusoners"][@"totalItems"];
            post.likesCount = @([likesCount integerValue]);
            updated = YES;
        }
    }
    
    NSArray* comments = [self getCommentsFromActivityID:postId];
    if (!comments)
    {
        updated = NO;
    }
    else
    {
        NSDictionary *postInfo = @{kPostCommentsDictKey : comments};
        
        if (post.commentsCount.integerValue < comments.count)
        {
            post.commentsCount = @(comments.count);
            [socialNetwork setCommentsFromPostInfo:postInfo toPost:post];
        }
    }
    
    if (updated)
    {
        post.updateTime = [NSDate date];
    }
    
    [[WDDDataBase sharedDatabase] save];
  
    return YES;
}

#pragma mark - Operation Queue

+ (NSOperationQueue *)operationQueue
{
    NSMutableDictionary *operationQueues = [GoogleRequest operationQueues];
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

@end
