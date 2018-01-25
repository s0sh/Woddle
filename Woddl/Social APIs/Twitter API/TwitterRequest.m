//
//  TwitterRequest.m
//  Woddl
//
//  Created by Александр Бородулин on 05.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "TwitterRequest.h"
#import "TwitterAPI.h"
#import "FHSTwitterEngine.h"
#import "TwitterPost.h"
#import "SocialNetwork.h"
#import "TwitterPost.h"

#import "WDDDataBase.h"
#import "WDDLocation.h"

static NSString * const kTwitterHashtagRegExp = @"\\B#\\w*[a-zA-Z]+\\w*";
static NSString * const kTwitterHTTPSBaseURLString = @"https://twitter.com";

@implementation TwitterRequest

static NSInteger const kMaxTextLengthTwitter = 140;
static NSInteger const kLinkLengthTwitter = 22;
static NSInteger const kGetCommentsQueueCount = 5;

- (id) init
{
    if (self = [super init])
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didGetFailTokenNotification:)
                                                     name:FHSTokenNotValidErrorNotification
                                                   object:nil];
        return self;
    }
    
    return nil;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray *)getPostsWithToken:(NSString *)token
                     andUserID:(NSString *)userID
                      andCount:(NSUInteger)count
                upToPostWithID:(NSString *)postId
{
    if (!token)
    {
        return nil;
    }
    
    FHSTwitterEngine * twitterEngine = [TwitterAPI createTwitterEngineWithToken:token];
    id list = [twitterEngine getHomeTimelineSinceID:postId count:(int)count];
    NSMutableArray *postsArray = [[NSMutableArray alloc] init];

    if([list isKindOfClass:[NSArray class]])
    {	
        for(NSDictionary *post in list)
        {
            NSDictionary* twitterPostData = [self getPostInfoWithToken:token andData:post];
            [postsArray addObject:twitterPostData];
        }
        
        NSMutableArray * resultPostsArray = [[NSMutableArray alloc] init];
        
        NSOperationQueue *commentsQueue = [NSOperationQueue new];
        commentsQueue.maxConcurrentOperationCount = kGetCommentsQueueCount;
        
        dispatch_semaphore_t commentsLoadingSemaphore = dispatch_semaphore_create(0);
        
         __block NSInteger postsToProcessCount = postsArray.count;
        
         [postsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
             
             NSBlockOperation *commentsOperation = [NSBlockOperation blockOperationWithBlock:^{
                 
                 NSMutableDictionary *twitterPostData = [[NSMutableDictionary alloc] initWithDictionary:obj];
                 NSDictionary *author = twitterPostData[kPostAuthorDictKey];
                 NSString *screenName = author[kPostAuthorScreenNameDictKey];
                 
                 if (screenName)
                 {
                     NSString *postID = twitterPostData[kPostIDDictKey];
                     
                     NSArray *comments = [self getCommentsWithTrack:screenName sinceID:postID token:token];
                     if (comments)
                     {
                         [twitterPostData s_setObject:comments forKey:kPostCommentsDictKey];
                     }
                     [twitterPostData s_setObject:@(comments.count) forKey:kPostCommentsCountDictKey];
                 }
                 
                 @synchronized(resultPostsArray)
                 {
                     [resultPostsArray addObject:twitterPostData];
                 }
                 
                 if (!--postsToProcessCount)
                 {
                     dispatch_semaphore_signal(commentsLoadingSemaphore);
                 }
                 
             }];
             
             [commentsQueue addOperation:commentsOperation];
             
         }];
        
        if (postsToProcessCount)
        {
            dispatch_semaphore_wait(commentsLoadingSemaphore, DISPATCH_TIME_FOREVER);
        }
        
        
        return resultPostsArray;
    }
    else
    {
        if ([list isKindOfClass:[NSError class]])
        {
            NSError *requestError = (NSError *)list;
            if ([requestError.domain isEqualToString:FHSErrorDomain] && requestError.code == 0x00000191)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:FHSTokenNotValidErrorNotification object:token];
            }
        }
        
        return nil;
    }
}

- (NSArray *)getPostsWithToken:(NSString *)token fromID:(NSString*)fromID to:(NSString*)to
{
    FHSTwitterEngine * twitterEngine = [TwitterAPI createTwitterEngineWithToken:token];
    
    id list = [twitterEngine getHomeTimelineFromID:fromID count:[to intValue]];
    NSMutableArray *postsArray = [[NSMutableArray alloc] init];
    
    if([list isKindOfClass:[NSArray class]])
    {
        for(NSDictionary *post in list)
        {
            NSDictionary* twitterPostData = [self getPostInfoWithToken:token andData:post];
            [postsArray addObject:twitterPostData];
        }
        return postsArray;
    }
    else
    {
        return nil;
    }
}

-(NSDictionary*)getPostInfoWithToken:(NSString *)token andData:(NSDictionary*)post
{
    NSMutableDictionary *twitterPostData = [[NSMutableDictionary alloc] init];
    NSString *created_at = [post objectForKey:@"created_at"];
    NSDate *dateCreation = [NSDate twitterDateFromString:created_at];
    NSDictionary *user = [post objectForKey:@"user"];
    
    if (user[@"screen_name"] && post[@"id_str"])
    {
        NSString *baseUrl = @"https://twitter.com";
        NSString* link = [NSString stringWithFormat:@"%@/%@/%@/%@",baseUrl,user[@"screen_name"],@"status",post[@"id_str"]];
        twitterPostData[kPostLinkOnWebKey] = link;
    }
    
    //Author
    NSMutableDictionary *personPosted = [[NSMutableDictionary alloc] init];
    [personPosted s_setObject:[user objectForKey:@"profile_image_url"] forKey:kPostAuthorAvaURLDictKey];
    NSString *authorName = [user objectForKey:@"name"];
    if(!authorName.length)
    {
        authorName = [user objectForKey:@"screen_name"];
    }
    [personPosted s_setObject:authorName forKey:kPostAuthorNameDictKey];
    
    if ([user objectForKey:@"screen_name"])
    {
        [personPosted s_setObject:[user objectForKey:@"screen_name"] forKey:kPostAuthorScreenNameDictKey];
    }
    
    if (user[@"id_str"])
    {
        personPosted[kPostAuthorIDDictKey] = user[@"id_str"];
    }
    if (user[@"screen_name"])
    {
        personPosted[kPostAuthorProfileURLDictKey] = [TwitterRequest profileURLWithName:user[@"screen_name"]];
    }
    
    NSMutableString *postText = [[post objectForKey:@"text"] mutableCopy];
    postText = [[self textWithReplacedWrongSimbolsWithText:postText] mutableCopy];
    
    NSString *postID = [post objectForKey:@"id_str"];
    [twitterPostData s_setObject:postID forKey:kPostIDDictKey];
    [twitterPostData s_setObject:dateCreation forKey:kPostDateDictKey];
    [twitterPostData s_setObject:personPosted forKey:kPostAuthorDictKey];
    
    NSNumber *retweetsCount = [post objectForKey:@"retweet_count"];
    [twitterPostData s_setObject:@(retweetsCount.integerValue) forKey:kPostRetweetsCountDictKey];
    
    [self setTagsForTweetData:twitterPostData fromText:postText];
    /*
    NSArray *comments = [self getCommentsWithTrack:[user objectForKey:@"screen_name"] sinceID:postID];
    if (comments)
    {
        [twitterPostData s_setObject:comments forKey:kPostCommentsDictKey];
    }    
    [twitterPostData s_setObject:@(comments.count) forKey:kPostCommentsCountDictKey];
    */
    //likes
    if ([post objectForKey:@"favorite_count"])
    {
        [twitterPostData s_setObject:@([[post objectForKey:@"favorite_count"] integerValue])
                            forKey:kPostLikesCountDictKey];
    }
    
    //media
    
    if([post objectForKey:@"entities"])
    {
        NSDictionary* entities = [post objectForKey:@"entities"];
        if([entities objectForKey:@"media"])
        {
            NSMutableArray* mediaResultArray = [[NSMutableArray alloc] init];
            NSArray* mediaArray = [entities objectForKey:@"media"];
            for(NSDictionary* mediaDict in mediaArray)
            {
                NSString* type = [mediaDict objectForKey:@"type"];
                if([type isEqualToString:@"photo"])
                {
                    NSMutableDictionary* mediaResultDict = [[NSMutableDictionary alloc] init];
                    [mediaResultDict s_setObject:mediaDict[@"media_url"] forKey:kPostMediaURLDictKey];
                    [mediaResultDict s_setObject:@"image" forKey:kPostMediaTypeDictKey];
                    [mediaResultDict s_setObject:mediaDict[@"url"] forKey:@"mediaTwitterURL"];
                    [mediaResultArray addObject:mediaResultDict];
                }
            }
            [twitterPostData s_setObject:mediaResultArray forKey:kPostMediaSetDictKey];
        }
    }
    
    for (NSDictionary *mediaInfo in twitterPostData[kPostMediaSetDictKey])
    {
        [postText replaceOccurrencesOfString:mediaInfo[@"mediaTwitterURL"]
                                  withString:@""
                                     options:NSCaseInsensitiveSearch
                                       range:NSMakeRange(0, postText.length)];
    }
    [twitterPostData s_setObject:[postText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                          forKey:kPostTextDictKey];
    
    return twitterPostData;
}

- (NSArray *)getCommentsWithTrack:(NSString *)track sinceID:(NSString *)fromID
{
    NSMutableArray *allComments = [[NSMutableArray alloc] init];
    
    id stream =[[FHSTwitterEngine sharedEngine] searchTweetsWithQuery:[NSString stringWithFormat:@"@%@", track] count:5 resultType:FHSTwitterEngineResultTypeRecent unil:nil sinceID:fromID maxID:nil];
    
    allComments = [self getCommentsFromStream:stream forPostID:fromID];
    
    if(allComments.count>5)
    {
        return [allComments subarrayWithRange: NSMakeRange(0,5)];
    }
    
    return allComments;
}

- (NSArray *)getCommentsWithTrack:(NSString *)track sinceID:(NSString *)fromID token:(NSString *)token
{
    NSMutableArray *allComments = [[NSMutableArray alloc] init];
    
    FHSTwitterEngine * twitterEngine = [TwitterAPI createTwitterEngineWithToken:token];
    
    id stream =[twitterEngine searchTweetsWithQuery:[NSString stringWithFormat:@"@%@", track] count:100 resultType:FHSTwitterEngineResultTypeRecent unil:nil sinceID:fromID maxID:nil];
    
    allComments = [self getCommentsFromStream:stream forPostID:fromID];
    
    if(allComments.count>5)
    {
        return [allComments subarrayWithRange: NSMakeRange(0,5)];
    }
    
    return allComments;
}

- (NSArray *)getCommentsWithTrack:(NSString *)track postID:(NSString*)postID fromID:(NSString *)fromID count:(NSUInteger)count
{
    NSMutableArray *allComments = [[NSMutableArray alloc] init];
    id stream =[[FHSTwitterEngine sharedEngine] searchTweetsWithQuery:[NSString stringWithFormat:@"@%@",track] count:count resultType:FHSTwitterEngineResultTypeRecent unil:nil sinceID:@"" maxID:fromID];

    allComments = [self getCommentsFromStream:stream forPostID:postID];
    
    if(allComments.count>count)
    {
        return [allComments subarrayWithRange: NSMakeRange(allComments.count-count,count)];
    }
    
    return allComments;
}

- (NSMutableArray *)getCommentsFromStream:(NSDictionary *)stream forPostID:(NSString *)postID
{
    NSMutableArray *allComments = [[NSMutableArray alloc] init];
    
    if([stream isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *streamDict = stream;
        if ([streamDict objectForKey:@"statuses"])
        {
            
            NSArray *statuses = [streamDict objectForKey:@"statuses"];
            for (NSDictionary *comment in statuses)
            {
                NSString *replyToStatusID = [comment objectForKey:@"in_reply_to_status_id_str"];
                if ([replyToStatusID isEqualToString:postID])
                {
                    NSMutableDictionary* commentResult = [[NSMutableDictionary alloc] init];
                    [commentResult s_setObject:[comment objectForKey:@"id_str"] forKey:kPostCommentIDDictKey];
                    
                    NSString *commentText = [comment objectForKey:@"text"];
                    if (commentText)
                    {
                        commentText = [self textWithReplacedWrongSimbolsWithText:commentText];
                        [commentResult s_setObject:commentText forKey:kPostCommentTextDictKey];
                        [self setTagsForTweetData:commentResult fromText:commentText];
                    }
                    
                    NSString *createdAt = [comment objectForKey:@"created_at"];
                    NSDate *dateCreateComment = [NSDate twitterDateFromString:createdAt];
                    [commentResult s_setObject:dateCreateComment forKey:kPostCommentDateDictKey];
                    
                    //author
                    NSMutableDictionary *userResultDict = [[NSMutableDictionary alloc] init];
                    NSDictionary *userInfo = [comment objectForKey:@"user"];
                    
                    [userResultDict s_setObject:[userInfo objectForKey:@"profile_image_url"] forKey:kPostCommentAuthorAvaURLDictKey];
                    [userResultDict s_setObject:[userInfo objectForKey:@"screen_name"] forKey:kPostCommentAuthorNameDictKey];
                    [userResultDict s_setObject:[userInfo objectForKey:@"id_str"] forKey:kPostCommentAuthorIDDictKey];
                    [userResultDict s_setObject:[TwitterRequest profileURLWithName:userInfo[@"screen_name"]] forKey:kPostAuthorProfileURLDictKey];
                    
                    [commentResult s_setObject:userResultDict forKey:kPostCommentAuthorDictKey];
                    
                    [allComments addObject:commentResult];
                }
            }
        }
    }
    
    return allComments;
}

- (BOOL)setLikeOnObjectID:(NSString *)objectID withToken:(NSString *)token
{
    [[TwitterAPI Instance] switchOnToken:token];
    NSError *error = [[FHSTwitterEngine sharedEngine] markTweet:objectID asFavorite:YES];
    if(!error)
    {
        return YES;
    }
    return NO;
}

- (BOOL)setUnlikeOnObjectID:(NSString *)objectID withToken:(NSString *)token
{
    [[TwitterAPI Instance] switchOnToken:token];
    NSError *error = [[FHSTwitterEngine sharedEngine] markTweet:objectID asFavorite:NO];
    if(!error)
    {
        return YES;
    }
    return NO;
}

- (BOOL)isPostLikedMe:(NSString *)postID withToken:(NSString *)token andMyID:(NSString *)myID
{
    [[TwitterAPI Instance] switchOnToken:token];
    id list = [[FHSTwitterEngine sharedEngine] getDetailsForTweet:postID];
    if([list isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *info = list;
        NSNumber *favorited = [info objectForKey:@"favorited"];
        if(favorited.boolValue==YES)
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)retweet:(NSString *)tweetID withToken:(NSString *)token
{
    [[TwitterAPI Instance] switchOnToken:token];
    NSError *error = [[FHSTwitterEngine sharedEngine] retweet:tweetID];
    if(!error)
    {
        return YES;
    }
    return NO;
}

- (BOOL)addTwitt:(NSString *)message withLink:(NSString *)link andToken:(NSString *)token
{
    NSString *twitt = nil;
    if (message && link)
    {
        if ((message.length + kLinkLengthTwitter + 1) > kMaxTextLengthTwitter)
        {
            twitt = [[message substringToIndex:kMaxTextLengthTwitter - kLinkLengthTwitter - 5] stringByAppendingString:@"... "];
            twitt = [twitt stringByAppendingString:link];
        }
        else
        {
            twitt = [message stringByAppendingFormat:@" %@", link];
        }
//        twitt = [NSString stringWithFormat:@"%@ %@", message, link];
//        
//        if (twitt.length > kMaxTextLengthTwitter)
//        {
//            twitt = [[message substringToIndex:kMaxTextLengthTwitter - kLinkLengthTwitter - 4] stringByAppendingString:@"..."];
//            twitt = [NSString stringWithFormat:@"%@ %@", twitt, link];
//        }
    }
    else if (message)
    {
        if(message.length>kMaxTextLengthTwitter)
        {
            twitt = [[message substringToIndex:kMaxTextLengthTwitter-3] stringByAppendingString:@"..."];
        }
        else
        {
            twitt = message;
        }
    }
    else if(link)
    {
        if(!(link.length>kMaxTextLengthTwitter))
        {
            twitt = link;
        }
    }
    
    DLog(@"Will try to tweet: \"%@\"", twitt);
    
    if(twitt)
    {
        [[TwitterAPI Instance] switchOnToken:token];
        NSDictionary *result = [[FHSTwitterEngine sharedEngine] postTweet:twitt];
        
        DLog(@"Twitter response with result : %@", result);
        
        if(result)
        {
            return YES;
        }
    }
    
    return NO;
}

- (NSDictionary*)replyToTwittWithMessage:(NSString *)message andTwittID:(NSString *)twittID andImage:(NSData*)image andToken:(NSString *)token
{
    [[TwitterAPI Instance] switchOnToken:token];
    NSDictionary *result = [[FHSTwitterEngine sharedEngine] postTweet:message withImageData:image inReplyTo:twittID];
    
    NSMutableDictionary* info = [[NSMutableDictionary alloc] init];
    [info s_setObject:[NSDate date] forKey:kPostCommentDateDictKey];
    [info s_setObject:[result objectForKey:@"id_str"] forKey:kPostCommentIDDictKey];
    [info s_setObject:message forKey:kPostCommentTextDictKey];
    [info s_setObject:[NSNumber numberWithInt:0] forKey:kPostCommentLikesCountDictKey];
    return info;
    
    if(info)
    {
        return [self getPostInfoWithToken:token andData:result];
    }
    
    return nil;
}

- (NSDictionary*)addStatusWithMessage:(NSString *)message andImage:(NSData*)image  location:(WDDLocation *)location andToken:(NSString *)token
{
    FHSTwitterEngine * twitterEngine = [TwitterAPI createTwitterEngineWithToken:token];
    
    id result = [twitterEngine postTweet:message withImageData:image location:location inReplyTo:@""];
    if(result)
    {
        if ([result isKindOfClass:[NSDictionary class]])
        {
            return [self getPostInfoWithToken:token andData:result];
        }
    }
    return nil;
}

- (BOOL)getUsersWhosLikedPostWithID:(NSString *)postId accessToken:(NSString *)accessToken
{
    return YES;
}

- (BOOL)updateLikesAndFavoritesForPostWithID:(NSString *)postId accessToken:(NSString *)accessToken
{
    FHSTwitterEngine * twitterEngine = [TwitterAPI createTwitterEngineWithToken:accessToken];
    id tweetInfo = [twitterEngine getDetailsForTweet:postId];
    
    if (tweetInfo && [tweetInfo isKindOfClass:[NSDictionary class]])
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
        
        TwitterPost *post = objects.firstObject;
        if ([tweetInfo[@"retweet_count"] respondsToSelector:@selector(integerValue)])
        {
            post.retweetsCount = @([tweetInfo[@"retweet_count"] integerValue]);
        }
        
        if ([tweetInfo[@"favorite_count"] respondsToSelector:@selector(integerValue)])
        {
            post.likesCount = @([tweetInfo[@"favorite_count"] integerValue]);
        }
        
        NSArray *comments = nil;
        if ([tweetInfo[@"user"] isKindOfClass:[NSDictionary class]] &&
            ![tweetInfo[@"user"][@"screen_name"] isKindOfClass:[NSNull class]])
        {
            comments = [self getCommentsWithTrack:tweetInfo[@"user"][@"screen_name"] sinceID:post.postID];
            if (comments)
            {
                [socialNetwork setCommentsFromPostInfo:@{kPostCommentsDictKey : comments}
                                                toPost:post];
            }
        }
        
        post.commentsCount = @(comments.count);
        post.updateTime = [NSDate date];
        
        [[WDDDataBase sharedDatabase] save];
    }
    else
    {
        tweetInfo = nil;
    }
    
    return tweetInfo != nil;
}

- (NSArray *)getFriendsWithToken:(NSString *)token userID:(NSString *)userID
{
    [[TwitterAPI Instance] switchOnToken:token];
    NSMutableArray *friends = [NSMutableArray new];
    NSNumber *cursor = @(-1);

GET_NEXT_PART:
    {
        id result = [[FHSTwitterEngine sharedEngine] listFriendsForUser:userID isID:YES withCursor:cursor.stringValue];

        if (![result isKindOfClass:[NSDictionary class]])
        {
            return nil;
        }
        
        if ([result[@"users"] isKindOfClass:[NSArray class]])
        {
            for (NSDictionary *userInfo in result[@"users"])
            {
                NSMutableDictionary *friendInfo = [NSMutableDictionary new];
                
                [friendInfo s_setObject:userInfo[@"profile_image_url"] forKey:kPostAuthorAvaURLDictKey];
                NSString *name = userInfo[@"name"];
                if(!name.length)
                {
                    name = userInfo[@"screen_name"];
                }
                [friendInfo s_setObject:name forKey:kPostAuthorNameDictKey];
                [friendInfo s_setObject:userInfo[@"id_str"] forKey:kPostAuthorIDDictKey];
                [friendInfo s_setObject:[TwitterRequest profileURLWithName:userInfo[@"screen_name"]] forKey:kPostAuthorProfileURLDictKey];

                [friends addObject:friendInfo];
            }
        }
        
        if (![result[@"next_cursor"] isKindOfClass:[NSNull class]] && [result[@"next_cursor"] longLongValue] > 0)
        {
            cursor = result[@"next_cursor"];
            goto GET_NEXT_PART;
        }
    }
    
    return friends;
}

- (id)profileInformationWithToken:(NSString *)token
{
    FHSTwitterEngine * twitterEngine = [TwitterAPI createTwitterEngineWithToken:token];
    return [twitterEngine verifyCredentials];
}

#pragma mark - Search

- (NSArray*)searchPostsWithSearchText:(NSString *)searchText
                            token:(NSString*)token
                            limit:(NSUInteger)limit
{
    NSMutableArray *allComments = [[NSMutableArray alloc] init];
    id stream =[[FHSTwitterEngine sharedEngine] searchTweetsWithQuery:[NSString stringWithFormat:@"%@",searchText] count:limit resultType:FHSTwitterEngineResultTypeRecent unil:nil sinceID:@"" maxID:nil];
    
    if([stream isKindOfClass:([NSDictionary class])])
    {
        for(NSDictionary *post in [stream objectForKey:@"statuses"])
        {
            NSDictionary* twitterPostData = [self getPostInfoWithToken:token andData:post];
            NSMutableDictionary* resultPostData = [NSMutableDictionary dictionaryWithDictionary:twitterPostData];
            [resultPostData s_setObject:[NSNumber numberWithBool:YES] forKey:kPostIsSearched];
            [allComments addObject:resultPostData];
        }
        if(allComments.count>limit)
        {
            return [allComments subarrayWithRange: NSMakeRange(allComments.count-limit,limit)];
        }
    }
    
    return allComments;
}

#pragma mark - Instruments

- (NSString *)stringBetweenString:(NSString *)start andString:(NSString *)end innerString:(NSString *)str
{
    NSScanner *scanner = [NSScanner scannerWithString:str];
    [scanner setCharactersToBeSkipped:nil];
    [scanner scanUpToString:start intoString:NULL];
    if([scanner scanString:start intoString:NULL])
    {
        NSString *result = nil;
        if([scanner scanUpToString:end intoString:&result])
        {
            return result;
        }
    }
    return nil;
}

#pragma mark - Help methods
+ (NSString *)profileURLWithName:(NSString *)name
{
    return [kTwitterHTTPSBaseURLString stringByAppendingPathComponent:name];
}

- (void)setTagsForTweetData:(NSMutableDictionary *)tweet fromText:(NSString *)text
{
    NSError *regExpError = nil;
    NSMutableArray *tagsList = [[NSMutableArray alloc] initWithCapacity:100];
    NSRegularExpression *hashtagsRegExp = [NSRegularExpression regularExpressionWithPattern:kTwitterHashtagRegExp
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
        [tweet s_setObject:tagsList forKey:kPostTagsListKey];
    }
}

#pragma mark - Notifications

- (void)didGetFailTokenNotification:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSString * accessToken = [notification object];
        
        NSPredicate *predicate = nil;
        if (accessToken)
        {
            predicate = [NSPredicate predicateWithFormat:@"accessToken CONTAINS %@ AND type == %d", accessToken, kSocialNetworkTwitter];
        }
        else
        {
            predicate = [NSPredicate predicateWithFormat:@"accessToken == nil AND type == %d", kSocialNetworkTwitter];
        }
        
        SocialNetwork *network = [[WDDDataBase sharedDatabase] fetchObjectsWithEntityName:NSStringFromClass([SocialNetwork class])
                                                                            withPredicate:predicate
                                                                          sortDescriptors:nil].firstObject;
        
        if (network && network.accessToken)
        {
            network.accessToken = nil;
            network.activeState = @NO;
            [[WDDDataBase sharedDatabase] save];
//            [network updateSocialNetworkOnParseNow:YES];
            [network updateSocialNetworkOnParse];
        }
    });
}

@end
