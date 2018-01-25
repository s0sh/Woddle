//
//  InstagramRequest.m
//  Woddl
//
//  Created by Александр Бородулин on 07.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "InstagramRequest.h"

#import "WDDDataBase.h"
#import "SocialNetwork.h"
#import "Post.h"
#import "UserProfile.h"
#import "Comment.h"
#import "InstagramOthersProfile.h"

static NSString * const kInstagramHashtagRegExp = @"\\B#\\w*[a-zA-Z]+\\w*";

static NSString * const kInstagramHTTPBaseURLString = @"http://instagram.com";

static CGFloat const kInternetIntervalTimeout = 30.0;

@implementation InstagramRequest

-(NSArray*)getPostsWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count
{
    
    [self getFriendsWithToken:token];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.instagram.com/v1/users/self/feed?access_token=%@&count=%lu",token,count]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    NSArray *resultArray = [self postsFromData:data isSearched:NO];
    return resultArray;
}

-(NSArray*)loadMorePostsWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count maxID:(NSString*)maxID
{
    [self getFriendsWithToken:token];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.instagram.com/v1/users/self/feed?count=%lu&max_id=%@&access_token=%@",count,maxID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSArray *resultArray = [self postsFromData:data isSearched:NO];
    return resultArray;
}

- (NSArray *)searchPostsWithSearchText:(NSString *)searchText
                            token:(NSString*)token
                            limit:(NSUInteger)limit
{
    NSString *firstWord = [[searchText componentsSeparatedByString:@" "] firstObject];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.instagram.com/v1/tags/%@/media/recent?access_token=%@",firstWord,token]]];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSArray *resultPosts = [self postsFromData:data isSearched:YES];
    if (limit && resultPosts.count && (limit < resultPosts.count ))
    {
        resultPosts = [resultPosts subarrayWithRange:NSMakeRange(0, limit)];
    }
    
    return resultPosts;
}

- (NSArray *)postsFromData:(NSData *)data isSearched:(BOOL)isSearched
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    if(data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            NSDictionary* dataArray = [json objectForKey:@"data"];
            for(NSDictionary* dataDict in dataArray)
            {
                NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
                NSString* userID = [dataDict objectForKey:@"id"];
                NSString* createdAt = [dataDict objectForKey:@"created_time"];
                NSDate* dateAdding = [NSDate dateWithTimeIntervalSince1970:[createdAt longLongValue]];
                NSDictionary* caption = [dataDict objectForKey:@"caption"];
                [resultDictionary s_setObject:userID forKey:kPostIDDictKey];
                [resultDictionary s_setObject:dateAdding forKey:kPostDateDictKey];
                
                [resultDictionary s_setObject:[NSNumber numberWithBool:isSearched] forKey:kPostIsSearched];
                
                if (dataDict[@"link"])
                {
                    [resultDictionary s_setObject:dataDict[@"link"] forKey:kPostLinkOnWebKey];
                }
                
                if([caption isKindOfClass:[NSDictionary class]] && [caption objectForKey:@"text"])
                {
                    // TODO: get tags here
                    NSString *postText = [caption objectForKey:@"text"];
                    [self setTagsForData:resultDictionary fromText:postText];
                    [resultDictionary s_setObject:postText forKey:kPostTextDictKey];
                }
                else
                {
                    resultDictionary[kPostTextDictKey] = @"";
                }
                
                //media
                NSString* typeMedia = [dataDict objectForKey:@"type"];
                NSMutableArray* mediaResultArray = [[NSMutableArray alloc] init];
                
                
                NSMutableDictionary* mediaResultDict = [[NSMutableDictionary alloc] init];
                if([typeMedia isEqualToString:@"video"])
                {
                    NSDictionary* videos = [dataDict objectForKey:@"videos"];
                    NSDictionary* standartResolution = [videos objectForKey:@"standard_resolution"];
                    NSString* videoLink = [standartResolution objectForKey:@"url"];
                    [mediaResultDict s_setObject:videoLink forKey:kPostMediaURLDictKey];
                    [mediaResultDict s_setObject:typeMedia forKey:kPostMediaTypeDictKey];
                    
                    if (dataDict[@"images"])
                    {
                        NSDictionary* images = [dataDict objectForKey:@"images"];
                        NSDictionary* imageURLDict = [images objectForKey:@"low_resolution"];
                        [mediaResultDict s_setObject:[imageURLDict objectForKey:@"url"] forKey:kPostMediaPreviewDictKey];
                    }
                }
                else
                {
                    if (dataDict[@"images"])
                    {
                        NSDictionary* images = [dataDict objectForKey:@"images"];
                        NSDictionary* imageURLDict = [images objectForKey:@"low_resolution"];
                        [mediaResultDict s_setObject:[imageURLDict objectForKey:@"url"] forKey:kPostMediaURLDictKey];
                        [mediaResultDict s_setObject:@"image" forKey:kPostMediaTypeDictKey];
                    }
                }
                [mediaResultArray addObject:mediaResultDict];
                
                [resultDictionary s_setObject:mediaResultArray forKey:kPostMediaSetDictKey];
                
                //user Info
                NSDictionary* authorDict = [dataDict objectForKey:@"user"];
                NSString* authorID = [authorDict objectForKey:@"id"];
                NSString* authorName = [authorDict objectForKey:@"username"];
                NSString* userPicture = [authorDict objectForKey:@"profile_picture"];
                
                NSMutableDictionary* personPosted = [[NSMutableDictionary alloc] init];
                
                [personPosted setValue:authorName forKey:kPostAuthorNameDictKey];
                [personPosted setValue:userPicture forKey:kPostAuthorAvaURLDictKey];
                [personPosted setValue:authorID forKey:kPostAuthorIDDictKey];
                [personPosted setValue:[InstagramRequest profileURLForID:authorName] forKey:kPostAuthorProfileURLDictKey];
                
                [resultDictionary s_setObject:personPosted forKey:kPostAuthorDictKey];
                
                //get comments
                NSNumber* countOfComments = [NSNumber numberWithInt:0];
                if ([dataDict objectForKey:@"comments"])
                {
                    NSDictionary* commentData = [dataDict objectForKey:@"comments"];
                    NSNumber* count = [commentData objectForKey:@"count"];
                    if(count.integerValue>0)
                    {
                        NSMutableArray* commentsResArray = [[NSMutableArray alloc] init];
                        NSArray* commentsArray = [commentData objectForKey:@"data"];
                        for(NSDictionary* comment in commentsArray)
                        {
                            NSMutableDictionary* commentResDict = [[NSMutableDictionary alloc] init];
                            NSMutableDictionary* authorResDict = [[NSMutableDictionary alloc] init];
                            
                            NSString* commentText = [comment objectForKey:@"text"];
                            [self setTagsForData:commentResDict fromText:commentText];
                            
                            NSString* commentID = [comment objectForKey:@"id"];
                            NSString* commentCreatedTime = [comment objectForKey:@"created_time"];
                            NSDate* dateAddingComment = [NSDate dateWithTimeIntervalSince1970:[commentCreatedTime longLongValue]];
                            [commentResDict s_setObject:commentText forKey:kPostCommentTextDictKey];
                            [commentResDict s_setObject:commentID forKey:kPostCommentIDDictKey];
                            [commentResDict s_setObject:dateAddingComment forKey:kPostCommentDateDictKey];
                            
                            //author comment
                            NSDictionary* authorComment = [comment objectForKey:@"from"];
                            if ([authorComment objectForKey:@"profile_picture"])
                            {
                                NSString* authorCommentImageURL = [authorComment objectForKey:@"profile_picture"];
                                [authorResDict s_setObject:authorCommentImageURL forKey:kPostCommentAuthorAvaURLDictKey];
                            }
                            NSString* authorCommentName = [authorComment objectForKey:@"username"];
                            NSString* authorCommentID = [authorComment objectForKey:@"id"];
                            [authorResDict s_setObject:authorCommentName forKey:kPostCommentAuthorNameDictKey];
                            [authorResDict s_setObject:authorCommentID forKey:kPostCommentAuthorIDDictKey];
                            [authorResDict s_setObject:[InstagramRequest profileURLForID:authorCommentName] forKey:kPostAuthorProfileURLDictKey];
                            
                            [commentResDict s_setObject:authorResDict forKey:kPostCommentAuthorDictKey];
                            
                            [commentsResArray addObject:commentResDict];
                        }
                        [resultDictionary s_setObject:commentsResArray forKey:kPostCommentsDictKey];
                    }
                    countOfComments = [NSNumber numberWithInt:count.integerValue];
                }
                [resultDictionary s_setObject:countOfComments forKey:kPostCommentsCountDictKey];
                
                //likes
                if ([dataDict objectForKey:@"likes"])
                {
                    NSDictionary* like = [dataDict objectForKey:@"likes"];
                    if ([like objectForKey:@"count"])
                    {
                        NSNumber* countOfLikes = [like objectForKey:@"count"];
                        [resultDictionary s_setObject:countOfLikes forKey:kPostLikesCountDictKey];
                    }
                }
                
                [resultArray addObject:resultDictionary];
            }
        }
    }
    return [resultArray copy];
}

-(BOOL)isPostLikedMe:(NSString*)postID withToken:(NSString*)token andMyID:(NSString*)myID
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.instagram.com/v1/media/%@?access_token=%@",postID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            if ([json objectForKey:@"data"])
            {
                NSDictionary* media = [json objectForKey:@"data"];
                NSNumber *isLiked = [media objectForKey:@"user_has_liked"];
                if(isLiked.boolValue)
                    return YES;
            }
        }
    }
    return NO;
}

-(BOOL)setLikeOnObjectID:(NSString*)objectID withToken:(NSString*)token
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.instagram.com/v1/media/%@/likes?access_token=%@",objectID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"POST"];
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
            if ([json objectForKey:@"meta"])
            {
                NSDictionary* meta = [json objectForKey:@"meta"];
                NSNumber *code = [meta objectForKey:@"code"];
                if(code.intValue==200)
                    return YES;
            }
        }
    }
    return NO;
}

-(BOOL)setUnlikeOnObjectID:(NSString*)objectID withToken:(NSString*)token
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.instagram.com/v1/media/%@/likes?access_token=%@",objectID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"DELETE"];
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
            if ([json objectForKey:@"meta"])
            {
                NSDictionary* meta = [json objectForKey:@"meta"];
                NSNumber *code = [meta objectForKey:@"code"];
                if(code.intValue==200)
                    return YES;
            }
        }
    }
    return NO;
}

-(NSDictionary*)addCommentOnObjectID:(NSString*)objectID withToken:(NSString*)token andMessage:(NSString*)message
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.instagram.com/v1/media/%@/comments?access_token=%@",objectID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"text=%@",message] dataUsingEncoding:NSUTF8StringEncoding]];
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
            if ([json objectForKey:@"meta"])
            {
                NSDictionary* meta = [json objectForKey:@"meta"];
                NSNumber *code = [meta objectForKey:@"code"];
                if(code.intValue==200)
                {
                    return nil;
                }
            }
        }
    }
    return nil;
}

-(NSArray*)getCommentsWithPostID:(NSString*)postID andToken:(NSString*)token
{
    NSMutableArray* commentsResArray = [[NSMutableArray alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.instagram.com/v1/media/%@/comments?access_token=%@",postID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            NSArray* commentsArray = [json objectForKey:@"data"];
            for(NSDictionary* comment in commentsArray)
            {
                NSMutableDictionary* commentResDict = [[NSMutableDictionary alloc] init];
                NSMutableDictionary* authorResDict = [[NSMutableDictionary alloc] init];
                
                NSString* commentText = [comment objectForKey:@"text"];
                NSString* commentID = [comment objectForKey:@"id"];
                NSString* commentCreatedTime = [comment objectForKey:@"created_time"];
                NSDate* dateAddingComment = [NSDate dateWithTimeIntervalSince1970:[commentCreatedTime longLongValue]];
                [commentResDict s_setObject:commentText forKey:kPostCommentTextDictKey];
                [commentResDict s_setObject:commentID forKey:kPostCommentIDDictKey];
                [commentResDict s_setObject:dateAddingComment forKey:kPostCommentDateDictKey];
                
                //author comment
                NSDictionary* authorComment = [comment objectForKey:@"from"];
                if ([authorComment objectForKey:@"profile_picture"])
                {
                    NSString* authorCommentImageURL = [authorComment objectForKey:@"profile_picture"];
                    [authorResDict s_setObject:authorCommentImageURL forKey:kPostCommentAuthorAvaURLDictKey];
                }
                NSString* authorCommentName = [authorComment objectForKey:@"username"];
                NSString* authorCommentID = [authorComment objectForKey:@"id"];
                [authorResDict s_setObject:authorCommentName forKey:kPostCommentAuthorNameDictKey];
                [authorResDict s_setObject:authorCommentID forKey:kPostCommentAuthorIDDictKey];
                
                [commentResDict s_setObject:authorResDict forKey:kPostCommentAuthorDictKey];
                
                [commentsResArray addObject:commentResDict];
            }

        }
    }
    
    return commentsResArray;
}

-(NSArray*)getFriendsWithToken:(NSString*)token
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.instagram.com/v1/users/self/follows?access_token=%@",token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            NSArray* friendsData = [json objectForKey:@"data"];
            for(NSDictionary* friend in friendsData)
            {
                NSMutableDictionary* resultDictionary = [[NSMutableDictionary alloc] init];
                
                [resultDictionary s_setObject:[friend objectForKey:@"id"] forKey:kFriendID];
                
                NSString* fullName = [friend objectForKey:@"full_name"];
                if(fullName&&fullName.length>0)
                {
                    [resultDictionary s_setObject:fullName forKey:kFriendName];
                }
                else
                {
                    [resultDictionary s_setObject:[friend objectForKey:@"username"] forKey:kFriendName];
                }
                
                if([friend objectForKey:@"profile_picture"])
                {
                    [resultDictionary s_setObject:[friend objectForKey:@"profile_picture"] forKey:kFriendPicture];
                }
                
                [resultDictionary s_setObject:[[self class] profileURLForID:[friend objectForKey:@"id"]] forKey:kFriendLink];
                
                [resultArray addObject:resultDictionary];
            }
        }
    }
    
    return resultArray;
}

#pragma mark - help methods
+ (NSString *)profileURLForID:(NSString *)profileID
{
    return [kInstagramHTTPBaseURLString stringByAppendingPathComponent:profileID];
}

- (void)setTagsForData:(NSMutableDictionary *)dict fromText:(NSString *)text
{
    if (!text)
    {
        return ;
    }
    
    NSError *regExpError = nil;
    NSMutableArray *tagsList = [[NSMutableArray alloc] initWithCapacity:100];
    NSRegularExpression *hashtagsRegExp = [NSRegularExpression regularExpressionWithPattern:kInstagramHashtagRegExp
                                                                                    options:0
                                                                                      error:&regExpError];
    NSAssert(!regExpError, [regExpError localizedDescription]);
    NSArray *tagsMatches = [hashtagsRegExp matchesInString:text
                                                   options:0
                                                     range:NSMakeRange(0, text.length)];
    
    for (NSTextCheckingResult *tagMatch in tagsMatches)
    {
        [tagsList addObject:[text substringWithRange:tagMatch.range]];
    }
    
    if (tagsList.count)
    {
        [dict s_setObject:tagsList forKey:kPostTagsListKey];
    }
}

- (UserProfile *)userProfileWithDescription:(NSDictionary *)userInfo
{
    NSFetchRequest *userRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([UserProfile class])];
    
    NSString *userId = [NSString stringWithFormat:@"%@", userInfo[@"id"]];
    NSPredicate *userPredicate = [NSPredicate predicateWithFormat:@"userID == %@", userId];
    userRequest.predicate = userPredicate;
    NSError *error = nil;
    NSArray *objects = [[WDDDataBase sharedDatabase].managedObjectContext executeFetchRequest:userRequest error:&error];
    UserProfile *profile = nil;
    
    if (objects.count)
    {
        profile = objects.firstObject;
    }
    else
    {
        profile = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([InstagramOthersProfile class])];
        profile.userID = userId;
    }
    
    profile.name = userInfo[@"full_name"];
    profile.avatarRemoteURL = userInfo[@"profile_picture"];
    profile.profileURL = [[self class] profileURLForID:userId];
    
    return profile;
}

- (BOOL)getUsersWhosLikedPostWithID:(NSString *)postId accessToken:(NSString *)accessToken
{
    if (!postId)
    {
        NSAssert(postId, @"postId can't be nil");
        return NO;
    }
    
    NSString *requestString = [NSString stringWithFormat:@"https://api.instagram.com/v1/media/%@/likes?access_token=%@", postId, accessToken];
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
//
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
            
            NSArray* users = [json objectForKey:@"data"];
            for (NSDictionary *userInfo in users)
            {
                UserProfile *profile = [self userProfileWithDescription:userInfo];
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
    if (!postId)
    {
        NSAssert(postId, @"postId can't be nil");
        return NO;
    }
    
    NSString *requestString = [NSString stringWithFormat:@"https://api.instagram.com/v1/media/%@?access_token=%@", postId, accessToken];
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    //
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
            
            NSDictionary *likesInfo = json[@"data"][@"likes"];
            
            post.likesCount = @([likesInfo[@"count"] integerValue]);
            NSArray* users = likesInfo[@"data"];
            for (NSDictionary *userInfo in users)
            {
                UserProfile *profile = [self userProfileWithDescription:userInfo];
                [profile addLikedPostsObject:post];
            }
            
            NSDictionary *commentsInfo = json[@"data"][@"comments"];
            
            post.commentsCount = @([commentsInfo[@"count"] integerValue]);
            NSArray *comments = commentsInfo[@"data"];
            NSFetchRequest *commentRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Comment class])];
            
            for (NSDictionary *commentInfo in comments)
            {
                NSString *commentID = [commentsInfo[@"id"] stringValue];
                NSPredicate *commentPredicate = [NSPredicate predicateWithFormat:@"commentID == %@", commentID];
                commentRequest.predicate = commentPredicate;
                NSArray *objects = [[WDDDataBase sharedDatabase].managedObjectContext executeFetchRequest:commentRequest
                                                                                                    error:nil];
                Comment *comment = objects.firstObject;
                if (!comment)
                {
                    comment = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([Comment class])];
                }
                else
                {
                    continue;
                }
                
                comment.commentID = commentID;
                comment.text = commentInfo[@"text"];
                comment.date = [NSDate dateWithTimeIntervalSince1970:[commentsInfo[@"created_time"] longLongValue]];
                
                NSDictionary* authorInfo = commentInfo[@"from"];
                comment.author = [self userProfileWithDescription:authorInfo];
                [post addCommentsObject:comment];
            }
            post.updateTime = [NSDate date];
            
            [[WDDDataBase sharedDatabase] save];
            return YES;
        }
    }
    
    return NO;
}

- (id)profileInformationWithToken:(NSString *)token userID:(NSString *)userID
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.instagram.com/v1/users/%@?access_token=%@", userID, token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (data)
    {
        NSError* error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            return json[@"data"];
        }
    }

    return nil;
}


@end
