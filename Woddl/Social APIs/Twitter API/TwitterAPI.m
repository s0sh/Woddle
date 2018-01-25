//
//  TwitterAPI.m
//  Woddl
//
//  Created by Александр Бородулин on 30.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "TwitterAPI.h"
#import "TwitterRequest.h"
#import "FHSTwitterEngine.h"
#import "TwitterImagesLoader.h"
#import "TwitterDefault.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import "TwitterSN.h"
#import "TwitterPost.h"
#import "WDDTwitterStreamURLConnection.h"
#import "WDDDatabase.h"

typedef NS_ENUM(NSInteger, WDDTwitterNotificationType)
{
    WDDTwitterNotificationTypeAccessRevoked = 0,
    WDDTwitterNotificationTypeBlock,
    WDDTwitterNotificationTypeUnblock,
    WDDTwitterNotificationTypeFavorite,
    WDDTwitterNotificationTypeUnfavorite,
    WDDTwitterNotificationTypeFollow,
    WDDTwitterNotificationTypeUnfollow,
    WDDTwitterNotificationTypeListCreated,
    WDDTwitterNotificationTypeListDestroyed,
    WDDTwitterNotificationTypeListUpdated,
    WDDTwitterNotificationTypeListMemberAdded,
    WDDTwitterNotificationTypeListMemberRemoved,
    WDDTwitterNotificationTypeListUserSubscribed,
    WDDTwitterNotificationTypeListUserUnsubscribed,
    WDDTwitterNotificationTypeUserUpdate,
    WDDTwitterNotificationTypeUnknown = NSNotFound
};

@interface TwitterAPI () <  FHSTwitterEngineAccessTokenDelegate,
                            UIAlertViewDelegate,
                            NSURLConnectionDelegate,
                            NSURLConnectionDataDelegate
                        >

@property (weak, nonatomic) id<TwitterAPIDelegate>  delegate;
@property (strong, nonatomic) dispatch_queue_t      notificationsQueue;
@property (strong, nonatomic) NSMutableDictionary   *notificationsConnections;
@property (strong, nonatomic) NSArray               *eventTypes;

@end

@implementation TwitterAPI

static TwitterAPI * myTwitter = nil;

+ (FHSTwitterEngine *) createTwitterEngineWithToken:(NSString *)token
{
    FHSTwitterEngine * twitterEngine = [self createTwitterEngine];
    [twitterEngine setupAccessToken:token];
    
    return twitterEngine;
}

+ (FHSTwitterEngine *) createTwitterEngine
{
    FHSTwitterEngine * twitterEngine = [[FHSTwitterEngine alloc] init];
    
    [twitterEngine permanentlySetConsumerKey:kTwitterConsumerKey andSecret:kTwitterConsumerSecret];
    
    return twitterEngine;
}

+ (TwitterAPI*)Instance
{
    static dispatch_once_t pred;
    dispatch_once(&pred,^()
    {
        myTwitter = [[super allocWithZone:NULL] init];
    });
    return myTwitter;
}

- (id) init
{
    if (self = [super init])
    {
        [[FHSTwitterEngine sharedEngine]permanentlySetConsumerKey:kTwitterConsumerKey andSecret:kTwitterConsumerSecret];
        [[FHSTwitterEngine sharedEngine]setDelegate:self];
        [self switchOnToken:nil];
        
        self.notificationsQueue = dispatch_queue_create("com.ids.woddl.twitter-notifications", DISPATCH_QUEUE_SERIAL);
        self.notificationsConnections = [NSMutableDictionary new];
        
//
//  Notification types
//  as described in https://dev.twitter.com/docs/streaming-apis/messages
//
        self.eventTypes = @[@"access_revoked",
                            @"block",
                            @"unblock",
                            @"favorite",
                            @"unfavorite",
                            @"follow",
                            @"unfollow",
                            @"list_created",
                            @"list_destroyed",
                            @"list_updated",
                            @"list_member_added",
                            @"list_member_removed",
                            @"list_user_subscribed",
                            @"list_user_unsubscribed",
                            @"user_update"
                            ];
    }
    return self;
}

-(void)switchOnToken:(NSString*)newToken
{
    userAccessToken = newToken;
    [[FHSTwitterEngine sharedEngine] loadAccessToken];
}

- (void)proceedLoginWithAccount:(ACAccount*)account target:(UIViewController<TwitterAPIDelegate> *)target
{
    self.delegate = target;
    
    [self performReverseAuthForAccount:account
                           withHandler:^(NSData *responseData, NSError *error) {
                               
                               NSString *token = [[NSString alloc] initWithData:responseData  encoding:NSUTF8StringEncoding];
                               if (!error && token.length && [token hasPrefix:@"oauth_token="])
                               {
                                   dispatch_async(bgQueue, ^{
                                       
                                       [[FHSTwitterEngine sharedEngine] setupAccessToken:token];
                                       [self storeAccessToken:token];
                                   });
                               }
                               else
                               {
                                   if ([self.delegate respondsToSelector:@selector(didFailLoginWithTwitter)])
                                   {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           
                                           [self.delegate didFailLoginWithTwitter];
                                       });
                                   }
                               }
                           }];
}

- (void)storeAccessToken:(NSString *)accessToken
{
    NSString* userID = [self stringBetweenString:@"user_id=" andString:@"&" innerString:accessToken];
    NSString* screenName = [self stringBetweenString:@"screen_name=" andString:@"" innerString:accessToken];
    NSString *profileURL = [TwitterRequest profileURLWithName:screenName];
    dispatch_async(bgQueue,^{
        NSString* imageURL = [self getUserImageAvatar];
        NSArray* folowers = [self getFolowers];
        dispatch_async(dispatch_get_main_queue(), ^{
            if([self.delegate respondsToSelector:@selector(loginTwitterWithSuccessWithToken:andName:andUserID:andImageURL:andFollowers:andProfileURL:)])
            {
                [self.delegate loginTwitterWithSuccessWithToken:accessToken
                                                        andName:screenName
                                                      andUserID:userID
                                                    andImageURL:imageURL
                                                   andFollowers:folowers
                                                  andProfileURL:profileURL
                 ];
            }
        });
    });
}

- (NSString *)loadAccessToken {
    return userAccessToken;
}

- (void)showLoginWindowWithTarget:(UIViewController<TwitterAPIDelegate>*)target
{
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *facebookCookies = [cookies cookiesForURL:[NSURL URLWithString:@"https://api.twitter.com"]];
    for(NSHTTPCookie* cookie in facebookCookies)
    {
        [cookies deleteCookie:cookie];
    }
    self.delegate = target;
    [[FHSTwitterEngine sharedEngine] showOAuthLoginControllerFromViewController:target withCompletion:^(BOOL success)
    {
        //[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        DLog(success?@"L0L success":@"O noes!!! Loggen faylur!!!");
        if (!success)
        {
            if ([self.delegate respondsToSelector:@selector(didFailLoginWithTwitter)])
            {
                [self.delegate didFailLoginWithTwitter];
            }
        }
    }];
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

-(NSString*)getUserImageAvatar
{
    NSString *userid = [[FHSTwitterEngine sharedEngine]loggedInID];
    NSArray* ids = [NSArray arrayWithObject:userid];
    NSArray* result = [[FHSTwitterEngine sharedEngine] lookupUsers:ids areIDs:YES];
    if([result isKindOfClass:[NSArray class]])
    {
        NSDictionary* userDict = [result lastObject];
        NSString* imageURL = [userDict objectForKey:@"profile_image_url"];
        return imageURL;
    }
    
    return nil;
}

-(NSArray*)getFolowers
{
    NSString *userid = [[FHSTwitterEngine sharedEngine]loggedInID];
    
    NSArray* follovers = nil;
    id data = [[FHSTwitterEngine sharedEngine] listFollowersForUser:userid isID:YES withCursor:@"-1"];
    if([data isKindOfClass:([NSDictionary class])])
    {
        NSDictionary* dataDict = data;
        follovers = [dataDict objectForKey:@"users"];
    }
    return follovers;
}

-(NSString*)getOAuthSecret
{
    return [FHSTwitterEngine sharedEngine].accessToken.secret;
}

#pragma mark - notifications

- (void)fetchNotificationsForUserId:(NSString*)userId
                        accessToken:(NSString*)accessToken
{
//    NSParameterAssert(userId);
//    NSParameterAssert(accessToken);
    if (!userId || !accessToken) return;
    if (!self.notificationsConnections[userId])
    {
        // Up the connection
        dispatch_async(self.notificationsQueue, ^()
        {
            self.notificationsConnections[userId] = [self getUserStreamDelimited:@NO
                                                                   stallWarnings:@YES
                                             includeMessagesFromFollowedAccounts:@YES
                                                                  includeReplies:@YES
                                                                 keywordsToTrack:nil
                                                           locationBoundingBoxes:nil
                                                                     accessToken:accessToken
                                                                          userId:userId
                                                                   progressBlock:^(id response)
            {
                dispatch_async(self.notificationsQueue, ^()
                {
                    [self processNotifications:@[response] forNetworkWithUserId:userId accessToken:accessToken];
                });
            }
                                                               stallWarningBlock:^(NSString *code, NSString *message, NSUInteger percentFull)
            {
                dispatch_async(self.notificationsQueue, ^()
                {
                    [self processStallWarning:message
                                         code:code
                                  percentFull:percentFull
                         forNetworkWithUserId:userId];
                });
            }
                                                                      errorBlock:^(NSError *error)
            {
                dispatch_async(self.notificationsQueue, ^()
                {
                    [self processError:error forNetworkWithUserId:userId];
                    [self fetchNotificationsForUserId:userId accessToken:accessToken];
                });
            }];
            
            [self.notificationsConnections[userId] setDelegateQueue:[TwitterSN operationQueue]];
            [(WDDTwitterStreamURLConnection*)self.notificationsConnections[userId] start];
        });
    }
    
    // fetch mentions and treat them as notifications
    dispatch_async(self.notificationsQueue, ^()
    {
        FHSTwitterEngine    *engine     = [[self class] createTwitterEngineWithToken:accessToken];
        NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Notification class])];
        fr.predicate = [NSPredicate predicateWithFormat:@"socialNetwork.profile.userID == %@ AND title BEGINSWITH[c] %@", userId, @"mention"];
        fr.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
        fr.fetchLimit = 1;
        NSString *lastMentionId = [[[[[WDDDataBase sharedDatabase] managedObjectContext] executeFetchRequest:fr error:nil] firstObject] externalObjectId];
        id result = [engine getMentionsTimelineWithCount:50 sinceID:lastMentionId maxID:nil];
        if (![result isKindOfClass:[NSError class]])
        {
            NSMutableArray *mentionsArray = [NSMutableArray new];
            [result enumerateObjectsUsingBlock:^(NSDictionary *mention, NSUInteger idx, BOOL *stop)
            {
                BOOL dontFetchPost  = NO;
                NSString *mentionId = mention[@"id_str"];
                NSFetchRequest *fr  = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([TwitterPost class])];
                fr.predicate        = [NSPredicate predicateWithFormat:@"postID == %@", mentionId];
                fr.fetchLimit       = 1;
                if ([[[[WDDDataBase sharedDatabase] managedObjectContext] executeFetchRequest:fr error:nil] firstObject])
                {
                    dontFetchPost = YES;
                }
                NSMutableDictionary *newMentionDict = [mention mutableCopy];
                newMentionDict[@"mention"]          = @YES;
                newMentionDict[@"dontFetchPost"]    = @(dontFetchPost);
                [mentionsArray addObject:newMentionDict];
            }];
            
            [self processNotifications:mentionsArray forNetworkWithUserId:userId accessToken:accessToken];
        }
    });
}

- (void)cancelFetchingNotificationsForUserId:(NSString *)userId
{
    NSParameterAssert(userId);
    if (!userId) return;
    [(WDDTwitterStreamURLConnection*)self.notificationsConnections[userId] cancel];
    [self.notificationsConnections removeObjectForKey:userId];
}

- (void)connection:(WDDTwitterStreamURLConnection*)connection didReceiveData:(NSData *)data
{
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:0
                                                           error:nil];
    if (json[@"warning"])
    {
        if (connection.stallWarningsBlock)
        {
            connection.stallWarningsBlock(json[@"warning"][@"code"], json[@"warning"][@"message"], [json[@"warning"][@"percent_full"] integerValue]);
        }
    }
    else if (json)
    {
        if (connection.progressBlock)
        {
            connection.progressBlock(json);
        }
    }
}

- (void)connectionDidFinishLoading:(WDDTwitterStreamURLConnection*)connection
{
    if (connection.errorBlock)
    {
        connection.errorBlock([NSError errorWithDomain:WDDErrorDomain
                                                  code:1991
                                              userInfo:@{NSLocalizedRecoverySuggestionErrorKey:@"Connection did stop, make it up again"}]);
    }
}

- (void)connection:(WDDTwitterStreamURLConnection*)connection didFailWithError:(NSError *)error
{
    if (connection.errorBlock)
    {
        connection.errorBlock(error);
    }
}

- (id)getUserStreamDelimited:(NSNumber *)delimited
               stallWarnings:(NSNumber *)stallWarnings
includeMessagesFromFollowedAccounts:(NSNumber *)includeMessagesFromFollowedAccounts
              includeReplies:(NSNumber *)includeReplies
             keywordsToTrack:(NSArray *)keywordsToTrack
       locationBoundingBoxes:(NSArray *)locationBoundingBoxes
                 accessToken:(NSString *)accessToken
                      userId:(NSString *)userId
               progressBlock:(void(^)(id response))progressBlock
           stallWarningBlock:(void(^)(NSString *code, NSString *message, NSUInteger percentFull))stallWarningBlock
                  errorBlock:(void(^)(NSError *error))errorBlock
{
    NSMutableDictionary *md = [NSMutableDictionary dictionary];
    md[@"adc"] = @"phone";
    md[@"stringify_friend_ids"] = @"1";
    if(delimited) md[@"delimited"] = [delimited boolValue] ? @"1" : @"0";
    if(stallWarnings) md[@"stall_warnings"] = [stallWarnings boolValue] ? @"1" : @"0";
    if(includeMessagesFromFollowedAccounts) md[@"with"] = @"user"; // default is 'followings'
    if(includeReplies && [includeReplies boolValue]) md[@"replies"] = @"all";
    
    NSString *keywords = [keywordsToTrack componentsJoinedByString:@","];
    NSString *locations = [locationBoundingBoxes componentsJoinedByString:@","];
    
    if([keywords length]) md[@"keywords"] = keywords;
    if([locations length]) md[@"locations"] = locations;
    
    FHSTwitterEngine    *engine     = [[self class] createTwitterEngineWithToken:accessToken];
    NSMutableString     *baseURL    = [@"https://userstream.twitter.com/1.1/user.json?" mutableCopy];
    
    [md enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop)
     {
         [baseURL appendFormat:@"%@=%@&", key, obj];
     }];
    
    [baseURL deleteCharactersInRange:NSMakeRange(baseURL.length - 1, 1)];
    
    NSURL                   *url    = [NSURL URLWithString:[baseURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    NSMutableURLRequest *request    = [NSMutableURLRequest requestWithURL:url];
    
    [engine signRequest:request];
    
    WDDTwitterStreamURLConnection *connection = [WDDTwitterStreamURLConnection connectionWithRequest:request
                                                                                            delegate:self
                                                                                    startImmediately:NO];
    
    connection.userId               = userId;
    connection.progressBlock        = progressBlock;
    connection.stallWarningsBlock   = stallWarningBlock;
    connection.errorBlock           = errorBlock;
    
    return connection;
}

//
// processing of twitter notifications as described in
// https://dev.twitter.com/docs/streaming-apis/messages
//

- (void)processNotifications:(NSArray*)notifications forNetworkWithUserId:(NSString*)userId accessToken:(NSString*)accessToken
{
    NSMutableArray *notificationObjects             = [NSMutableArray new];
    NSMutableArray *postObjects                     = [NSMutableArray new];
    NSMutableArray *notificationRelatedUserObjects  = [NSMutableArray new];
    
    [notifications enumerateObjectsUsingBlock:^(NSDictionary *notification, NSUInteger idx, BOOL *stop)
    {
//        DLog(@"notification %@", notification);
        
        NSMutableDictionary *notificationDictionary = [NSMutableDictionary new];
        
        if (notification[@"friends"]) // Initial stanza, sent only once, contains friends list, not actually a notification so skipping
        {
            return;
        }
        
        NSString *createdAt = notification[@"created_at"];
        if (createdAt)
        {
            NSDate *createdAtDate = [NSDate twitterDateFromString:createdAt];
            if (createdAtDate)
            {
                notificationDictionary[@"date"]             = createdAtDate;
                
                // we use custom identifier for twitter notification, because twitter doesn't provide us with any
                notificationDictionary[@"notificationId"]   = [NSString stringWithFormat:@"%lu_%@",
                                                               (unsigned long)[createdAtDate timeIntervalSince1970],
                                                               userId];
            }
        }

        notificationDictionary[@"isUnread"]             = @YES;
        
        BOOL targetObjectIsTweet = NO;
        
        NSDictionary *source        = notification[@"source"];
        
        if (![source isKindOfClass:[NSDictionary class]])
        {
            source = notification[@"user"];
        }
        
        NSDictionary *target        = notification[@"target"];
        NSDictionary *targetObject  = notification[@"target_object"];
        
        NSString *event = notification[@"event"];
        if (!event) // There's no event in notification dictionary, so this may be reply, retweet, or something unknown
        {
            if ([notification[@"mention"] isEqualToNumber:@YES])
            {
                source                                          = notification[@"user"];
                targetObject                                    = notification;
                targetObjectIsTweet                             = YES;
                notificationDictionary[@"title"]                = [NSString stringWithFormat:@"Mention:\n%@", targetObject[@"text"]];
                notificationDictionary[@"isUnread"]             = @NO;
                notificationDictionary[@"senderId"]             = source[@"id_str"];
                notificationDictionary[@"externalObjectType"]   = @"stream";
                notificationDictionary[@"externalObjectId"]     = targetObject[@"id_str"];
                if (notificationDictionary[@"notificationId"])
                {
                    notificationDictionary[@"notificationId"] = [@"ME" stringByAppendingString:notificationDictionary[@"notificationId"]];
                }
            }
            else if (![notification[@"in_reply_to_user_id_str"] isKindOfClass:[NSNull class]] && [notification[@"in_reply_to_user_id_str"] isEqualToString:userId])
            {
                // reply
                source                                          = notification[@"user"];
                if ([source[@"id_str"] isEqualToString:userId])
                {
                    // This is self-reply generated by dumb twitter
                    return;
                }
                targetObject                                    = notification;
                targetObjectIsTweet                             = YES;
                notificationDictionary[@"title"]                = [NSString stringWithFormat:@"@%@ replied to your status", source[@"screen_name"]];
                notificationDictionary[@"senderId"]             = source[@"id_str"];
                notificationDictionary[@"externalObjectType"]   = @"stream";
                notificationDictionary[@"externalObjectId"]     = targetObject[@"id_str"];
                if (notificationDictionary[@"notificationId"])
                {
                    notificationDictionary[@"notificationId"] = [@"RE" stringByAppendingString:notificationDictionary[@"notificationId"]];
                }
            }
            else if (notification[@"retweeted_status"])
            {
                // retweet
                source                                          = notification[@"user"];
                if ([source[@"id_str"] isEqualToString:userId])
                {
                    // This is self-retweet generated by dumb twitter
                    return;
                }
                targetObject                                    = notification[@"retweeted_status"];
                targetObjectIsTweet                             = YES;
                notificationDictionary[@"title"]                = [NSString stringWithFormat:@"@%@ retweeted your status", source[@"screen_name"]];
                notificationDictionary[@"senderId"]             = source[@"id_str"];
                notificationDictionary[@"externalObjectType"]   = @"stream";
                notificationDictionary[@"externalObjectId"]     = targetObject[@"id_str"];
                if (notificationDictionary[@"notificationId"])
                {
                    notificationDictionary[@"notificationId"] = [@"RT" stringByAppendingString:notificationDictionary[@"notificationId"]];
                }
            }
        }
        
        WDDTwitterNotificationType type = [self.eventTypes indexOfObject:event];
        
        switch (type)
        {
            case WDDTwitterNotificationTypeAccessRevoked:
                DLog(@"User access revoked for notification stream with userId %@", userId);
                return; // For further process
                break;
            case WDDTwitterNotificationTypeBlock:
                DLog(@"");
                notificationDictionary[@"title"]    = [NSString stringWithFormat:@"You have blocked @%@", target[@"screen_name"]];
                notificationDictionary[@"senderId"] = target[@"id_str"];
                notificationDictionary[@"iconURL"]  = target[@"profile_image_url_https"];
                break;
            case WDDTwitterNotificationTypeUnblock:
                notificationDictionary[@"title"]    = [NSString stringWithFormat:@"You have unblocked @%@", target[@"screen_name"]];
                notificationDictionary[@"senderId"] = target[@"id_str"];
                notificationDictionary[@"iconURL"]  = target[@"profile_image_url_https"];
                break;
            case WDDTwitterNotificationTypeFavorite:
                if ([userId isEqualToString:target[@"id_str"]])
                {
                    // Current user's tweet is favorited
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"@%@ has favorited your tweet", source[@"screen_name"]];
                    notificationDictionary[@"senderId"] = source[@"id_str"];
                    notificationDictionary[@"iconURL"]  = source[@"profile_image_url_https"];
                }
                else
                {
                    // Current user favorited a tweet
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"You have favorited @%@'s tweet", target[@"screen_name"]];
                    notificationDictionary[@"senderId"] = target[@"id_str"];
                    notificationDictionary[@"iconURL"]  = target[@"profile_image_url_https"];
                }
                
                notificationDictionary[@"externalObjectType"]   = @"stream";
                notificationDictionary[@"externalObjectId"]     = targetObject[@"id_str"];
                
                targetObjectIsTweet = YES;
                break;
            case WDDTwitterNotificationTypeUnfavorite:
                if ([userId isEqualToString:target[@"id_str"]])
                {
                    // Current user's tweet is unfavorited
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"@%@ has unfavorited your tweet", source[@"screen_name"]];
                    notificationDictionary[@"senderId"] = source[@"id_str"];
                    notificationDictionary[@"iconURL"]  = source[@"profile_image_url_https"];
                }
                else
                {
                    // Current user unfavorited a tweet
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"You have unfavorited @%@'s tweet", target[@"screen_name"]];
                    notificationDictionary[@"senderId"] = target[@"id_str"];
                    notificationDictionary[@"iconURL"]  = target[@"profile_image_url_https"];
                }
                
                notificationDictionary[@"externalObjectType"]   = @"stream";
                notificationDictionary[@"externalObjectId"]     = targetObject[@"id_str"];
                
                targetObjectIsTweet = YES;
                break;
            case WDDTwitterNotificationTypeFollow:
                if ([userId isEqualToString:target[@"id_str"]])
                {
                    // Current user is followed
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"@%@ followed you", source[@"screen_name"]];
                    notificationDictionary[@"senderId"] = source[@"id_str"];
                    notificationDictionary[@"iconURL"]  = source[@"profile_image_url_https"];
                }
                else
                {
                    // Current user followed a buddy
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"You followed @%@", target[@"screen_name"]];
                    notificationDictionary[@"senderId"] = target[@"id_str"];
                    notificationDictionary[@"iconURL"]  = target[@"profile_image_url_https"];
                }
                break;
            case WDDTwitterNotificationTypeUnfollow:
                if ([userId isEqualToString:target[@"id_str"]])
                {
                    // Current user is unfollowed
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"@%@ unfollowed you", source[@"screen_name"]];
                    notificationDictionary[@"senderId"] = source[@"id_str"];
                    notificationDictionary[@"iconURL"]  = source[@"profile_image_url_https"];
                }
                else
                {
                    // Current user unfollowed a buddy
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"You unfollowed @%@", target[@"screen_name"]];
                    notificationDictionary[@"senderId"] = target[@"id_str"];
                    notificationDictionary[@"iconURL"]  = target[@"profile_image_url_https"];
                }
                break;
            case WDDTwitterNotificationTypeListCreated:
                notificationDictionary[@"externalURL"]          = [NSString stringWithFormat:@"https://twitter.com/%@", targetObject[@"uri"]];
                notificationDictionary[@"title"]                = [NSString stringWithFormat:@"You have created list %@", targetObject[@"name"]];
                notificationDictionary[@"senderId"]             = target[@"id_str"];
                notificationDictionary[@"iconURL"]              = target[@"profile_image_url_https"];
                notificationDictionary[@"externalObjectType"]   = @"list";
                notificationDictionary[@"externalObjectId"]     = targetObject[@"id_str"];
                break;
            case WDDTwitterNotificationTypeListDestroyed:
                notificationDictionary[@"externalURL"]          = [NSString stringWithFormat:@"https://twitter.com/%@", targetObject[@"uri"]];
                notificationDictionary[@"title"]                = [NSString stringWithFormat:@"You have deleted list %@", targetObject[@"name"]];
                notificationDictionary[@"senderId"]             = target[@"id_str"];
                notificationDictionary[@"iconURL"]              = target[@"profile_image_url_https"];
                notificationDictionary[@"externalObjectType"]   = @"list";
                notificationDictionary[@"externalObjectId"]     = targetObject[@"id_str"];
                break;
            case WDDTwitterNotificationTypeListUpdated:
                notificationDictionary[@"externalURL"]          = [NSString stringWithFormat:@"https://twitter.com/%@", targetObject[@"uri"]];
                notificationDictionary[@"title"]                = [NSString stringWithFormat:@"You have updated list %@", targetObject[@"name"]];
                notificationDictionary[@"senderId"]             = target[@"id_str"];
                notificationDictionary[@"iconURL"]              = target[@"profile_image_url_https"];
                notificationDictionary[@"externalObjectType"]   = @"list";
                notificationDictionary[@"externalObjectId"]     = targetObject[@"id_str"];
                break;
            case WDDTwitterNotificationTypeListMemberAdded:
                if ([userId isEqualToString:target[@"id_str"]])
                {
                    // Current user is added to list
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"@%@ added you to list @%@", source[@"screen_name"], targetObject[@"name"]];
                    notificationDictionary[@"senderId"] = source[@"id_str"];
                    notificationDictionary[@"iconURL"]  = source[@"profile_image_url_https"];
                }
                else
                {
                    // Current user added a buddy to list
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"You added @%@ to list %@", target[@"screen_name"], targetObject[@"name"]];
                    notificationDictionary[@"senderId"] = target[@"id_str"];
                    notificationDictionary[@"iconURL"]  = target[@"profile_image_url_https"];
                }
                notificationDictionary[@"externalURL"]          = [NSString stringWithFormat:@"https://twitter.com/%@", targetObject[@"uri"]];
                notificationDictionary[@"externalObjectType"]   = @"list";
                notificationDictionary[@"externalObjectId"]     = targetObject[@"id_str"];
                break;
            case WDDTwitterNotificationTypeListMemberRemoved:
                if ([userId isEqualToString:target[@"id_str"]])
                {
                    // Current user is removed from list
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"@%@ removed you from list @%@", source[@"screen_name"], targetObject[@"name"]];
                    notificationDictionary[@"senderId"] = source[@"id_str"];
                    notificationDictionary[@"iconURL"]  = source[@"profile_image_url_https"];
                }
                else
                {
                    // Current user removed a buddy from list
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"You removed @%@ from list %@", target[@"screen_name"], targetObject[@"name"]];
                    notificationDictionary[@"senderId"] = target[@"id_str"];
                    notificationDictionary[@"iconURL"]  = target[@"profile_image_url_https"];
                }
                notificationDictionary[@"externalURL"]          = [NSString stringWithFormat:@"https://twitter.com/%@", targetObject[@"uri"]];
                notificationDictionary[@"externalObjectType"]   = @"list";
                notificationDictionary[@"externalObjectId"]     = targetObject[@"id_str"];
                break;
            case WDDTwitterNotificationTypeListUserSubscribed:
                if ([userId isEqualToString:target[@"id_str"]])
                {
                    // Someone subscribed to current users list
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"@%@ subscribed to your list @%@", source[@"screen_name"], targetObject[@"name"]];
                    notificationDictionary[@"senderId"] = source[@"id_str"];
                    notificationDictionary[@"iconURL"]  = source[@"profile_image_url_https"];
                }
                else
                {
                    // Current user subscribed to someone's list
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"You subscribed to @%@'s list %@", target[@"screen_name"], targetObject[@"name"]];
                    notificationDictionary[@"senderId"] = target[@"id_str"];
                    notificationDictionary[@"iconURL"]  = target[@"profile_image_url_https"];
                }
                notificationDictionary[@"externalURL"]          = [NSString stringWithFormat:@"https://twitter.com/%@", targetObject[@"uri"]];
                notificationDictionary[@"externalObjectType"]   = @"list";
                notificationDictionary[@"externalObjectId"]     = targetObject[@"id_str"];
                break;
            case WDDTwitterNotificationTypeListUserUnsubscribed:
                if ([userId isEqualToString:target[@"id_str"]])
                {
                    // Someone unsubscribed from current users list
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"@%@ unsubscribed from your list @%@", source[@"screen_name"], targetObject[@"name"]];
                    notificationDictionary[@"senderId"] = source[@"id_str"];
                    notificationDictionary[@"iconURL"]  = source[@"profile_image_url_https"];
                }
                else
                {
                    // Current user unsubscribed from someone's list
                    notificationDictionary[@"title"]    = [NSString stringWithFormat:@"You unsubscribed from @%@'s list %@", target[@"screen_name"], targetObject[@"name"]];
                    notificationDictionary[@"senderId"] = target[@"id_str"];
                    notificationDictionary[@"iconURL"]  = target[@"profile_image_url_https"];
                }
                notificationDictionary[@"externalURL"]          = [NSString stringWithFormat:@"https://twitter.com/%@", targetObject[@"uri"]];
                notificationDictionary[@"externalObjectType"]   = @"list";
                notificationDictionary[@"externalObjectId"]     = targetObject[@"id_str"];
                break;
            case WDDTwitterNotificationTypeUserUpdate:
                DLog(@"User info update for userId %@\nUpdate:%@", userId, source);
                return; // For further process
                break;
            case WDDTwitterNotificationTypeUnknown:
                break;
        }
        
        NSMutableArray *notificationRelatedUsers        = [NSMutableArray new];
        
        if (source && [notificationRelatedUserObjects indexOfObjectPassingTest:^BOOL(NSDictionary *alreadyParsedUser, NSUInteger idx, BOOL *stop)
        {
            return [alreadyParsedUser[kPostAuthorIDDictKey] isEqualToString:source[@"id_str"]];
        }] == NSNotFound)
        {
            [notificationRelatedUsers addObject:source];
        }
        if (target && [notificationRelatedUserObjects indexOfObjectPassingTest:^BOOL(NSDictionary *alreadyParsedUser, NSUInteger idx, BOOL *stop)
        {
            return [alreadyParsedUser[kPostAuthorIDDictKey] isEqualToString:target[@"id_str"]];
        }] == NSNotFound)
        {
            [notificationRelatedUsers addObject:target];
        }
        
        [notificationRelatedUsers enumerateObjectsUsingBlock:^(NSDictionary *userInfo, NSUInteger idx, BOOL *stop)
        {
            if (![userInfo isKindOfClass:[NSDictionary class]])
            {
#ifdef DEBUG
                dispatch_async(dispatch_get_main_queue(), ^()
                {
                    [[[UIAlertView alloc] initWithTitle:@"IMPORTANT!!!"
                                                message:[NSString stringWithFormat:@"This is debug alert to determine why userInfo is not dictionary in %s. Please, send log to one of developers oleg.komaristov@gmail.com, soxjke@gmail.com. The app will crash after you pres OK", __PRETTY_FUNCTION__]
                                               delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil] show];
                    NSLog(@"%@", notifications);
                });
#endif
                return;
            }
            
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
        
            [notificationRelatedUserObjects addObject:friendInfo];
        }];
        
        NSDictionary *postInfo;
        if (targetObjectIsTweet && ![notification[@"dontFetchPost"] isEqualToNumber:@YES])
        {
            TwitterRequest *req = [TwitterRequest new];
            postInfo = [req getPostInfoWithToken:accessToken andData:targetObject];
            if (postInfo)
            {
                [postObjects addObject:postInfo];
            }
        }
        
        [notificationObjects addObject:notificationDictionary];
    }];

    dispatch_async([TwitterSN networkQueue], ^()
    {
        NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([TwitterSN class])];
        fr.predicate = [NSPredicate predicateWithFormat:@"profile.userID == %@", userId];
        fr.fetchLimit = 1;
        TwitterSN *socialNetwork = [[[[WDDDataBase sharedDatabase] managedObjectContext] executeFetchRequest:fr error:nil] firstObject];

        [notificationRelatedUserObjects enumerateObjectsUsingBlock:^(NSDictionary *userProfileDict, NSUInteger idx, BOOL *stop)
        {
            [socialNetwork twitterProfileWithDescription:userProfileDict];
        }];
        [postObjects enumerateObjectsUsingBlock:^(NSDictionary *postInfo, NSUInteger idx, BOOL *stop)
        {
            [socialNetwork addPostToDataBase:postInfo];
        }];
        [socialNetwork saveNotificationsToDataBase:notificationObjects];
    });
}

- (void)processStallWarning:(NSString*)stallWarning
                       code:(NSString*)code
                percentFull:(NSUInteger)percentFull
       forNetworkWithUserId:(NSString*)userId
{
    DLog(@"stall warning %@ %@ %lu", code, stallWarning, (unsigned long)percentFull);
}

- (void)processError:(NSError*)error forNetworkWithUserId:(NSString*)userId
{
    DLog(@"error %@", error);
    WDDTwitterStreamURLConnection *connection = (WDDTwitterStreamURLConnection*)self.notificationsConnections[userId];
    [connection cancel];
    [self.notificationsConnections removeObjectForKey:userId];
}

#ifdef DEBUG
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    exit(0);
}
#endif

@end
