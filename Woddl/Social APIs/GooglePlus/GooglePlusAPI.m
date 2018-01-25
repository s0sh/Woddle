//
//  GooglePlusAPI.m
//  Woddl
//
//  Created by Алексей Поляков on 30.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

typedef enum
{
    GooglePlusOperationTypeLogin = 0,
    GooglePlusOperationTypeGetPosts,
    GooglePlusOperationNothing
} GooglePlusOperationType;

#import "GooglePlusAPI.h"
#import "NetworkRequest.h"

@interface GooglePlusAPI()

@property (strong, nonatomic) NSMutableArray *posts;

@end

@implementation GooglePlusAPI


{
    GPPSignIn               *signIn;
    GooglePlusOperationType  currentOperation;
    NSMutableArray          *allActivities;
    SocialNetwork           *currentNetwork;
}

static GooglePlusAPI *googlePlus = nil;

- (NSMutableArray *)posts
{
    if (!_posts)
    {
        _posts = [[NSMutableArray alloc] init];
    }
    return _posts;
}

+ (GooglePlusAPI *)Instance
{
    static dispatch_once_t pred;
    dispatch_once(&pred,^{
        googlePlus = [[super allocWithZone:NULL] init];
    });
    return googlePlus;
}

- (void)loginWithDelegate:(id<GooglePlusAPIDelegate>)delegate_
{
    currentOperation = GooglePlusOperationTypeLogin;
    delegate = delegate_;
    
    [delegate loginGooglePlusViewController:[self login]];
}

- (void)loginSuccessWithToken:(NSString*)token timeExpire:(NSString*)expires userID:(NSString*)userID userName:(NSString *)userName imageURL:(NSString *)imageURL
{
    OAuthToken = token;
    expiresIn = expires;
    
    NSDate *today = [NSDate date];
    NSDate *expireDate = [today dateByAddingTimeInterval:[expiresIn intValue]];
    
    [delegate loginGooglePlusWithSuccessWithToken:token expire:expireDate userID:userID userName:userName imageURL:imageURL];
}

- (id)login
{
    [self clearCookie];
    
    SEL finishedSel = @selector(viewController:finishedWithAuth:error:);
    
    GTMOAuth2ViewControllerTouch *viewController;
    
    //kGTLAuthScopePlusLogin, kGTLAuthScopePlusMe
    viewController = [GTMOAuth2ViewControllerTouch controllerWithScope:kGTLAuthScopePlusLogin
                                                              clientID:kGooglePlusClientID
                                                          clientSecret:kGooglePlusClientSecret
                                                      keychainItemName:@"OAuth Woddl Google Contacts"
                                                              delegate:self
                                                      finishedSelector:finishedSel];
    
    return viewController;
    
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error
{
    if (!error)
    {
        NSString *keychainName = [NSString stringWithFormat:@"GooglePlus%@", [auth userID]];
        DLog(@"Keychain name: %@", keychainName);
        
        signIn = [GPPSignIn sharedInstance];
        
        signIn.keychainName = keychainName;
        //[signIn signOut];
        
        [GTMOAuth2ViewControllerTouch saveParamsToKeychainForName:keychainName authentication:auth];
        
        signIn.delegate = self;
        signIn.shouldFetchGooglePlusUser = YES;
        signIn.shouldFetchGoogleUserID = YES;
        signIn.shouldFetchGoogleUserEmail = YES;
        signIn.clientID = kGooglePlusClientID;
        signIn.scopes = [NSArray arrayWithObjects: kGTLAuthScopePlusLogin, kGTLAuthScopePlusMe, nil];
        
        if ([signIn trySilentAuthentication])
        {
            [signIn authentication];
        }
    }
    else
    {
        [delegate loginGooglePlusWithFail];
    }
}

- (void)loginCancel
{
    [delegate loginGooglePlusWithFail];
}

- (void)didDisconnectWithError:(NSError *)error
{
    
}

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth
                   error:(NSError *)error
{
    if (!error)
    {
        switch (currentOperation)
        {
            case GooglePlusOperationTypeLogin:
            {
                //[GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:@"OAuth Woddl Google Contacts"];
                //[GTMOAuth2ViewControllerTouch saveParamsToKeychainForName:[NSString stringWithFormat:@"GooglePlus%@", auth.userID] authentication:auth];
                
//                DLog(@"%@", [NSString stringWithFormat:@"GooglePlus%@", auth.userID]);
                
                [delegate loginGooglePlusWithSuccessWithToken:[auth accessToken]
                                                       expire:[auth expirationDate]
                                                       userID:[auth userID]
                                                     userName:[auth userEmail]
                                                     imageURL:[[[signIn googlePlusUser] image] url]];
                
                break;
            }           
            case GooglePlusOperationTypeGetPosts:
            {
                //[GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:[NSString stringWithFormat:@"GooglePlus%@", auth.userID]];
                //[GTMOAuth2ViewControllerTouch saveParamsToKeychainForName:[NSString stringWithFormat:@"GooglePlus%@", auth.userID] authentication:auth];
                
                //dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
                //    [self getAllActivities];
                //});
                
                [self performSelectorOnMainThread:@selector(getAllActivities) withObject:nil waitUntilDone:YES];
                //[self performSelectorInBackground:@selector(getAllActivities) withObject:nil];
            }
            case GooglePlusOperationNothing:
            {
                break;
            }
        }
    }
    else
    {
        [delegate loginGooglePlusWithFail];
    }
}

- (void)addActivity:(id)activity
{
    //[_activityDelegate getAllactivities:self.posts socialNetwork:currentNetwork];
    [_activityDelegate getAllactivities:(NSMutableArray *)@[activity] socialNetwork:currentNetwork];
    //self.posts = nil;
    //[self getCommentsForPost:activity postID:[activity objectForKey:postIDDictKey]];
}

- (void)getAllActivities
{
    GTLServicePlus *service = [[GPPSignIn sharedInstance] plusService];
    
    [service setShouldFetchInBackground:YES];
    
    GTLQueryPlus *query = [GTLQueryPlus queryForActivitiesListWithUserId:@"me" collection:kGTLPlusCollectionPublic];
    
    [service executeQuery:query
                                         completionHandler:^(GTLServiceTicket *ticket,
                                                             GTLPlusActivityFeed *actFeed,
                                                             NSError *error) {
                                             
                                         }];
    
    GTLQueryPlus *queryGetPeoples = [GTLQueryPlus queryForPeopleListWithUserId:@"me"
                                                                    collection:@"visible"];
    
    [service executeQuery:queryGetPeoples
                                         completionHandler:^(GTLServiceTicket *ticket,
                                                             GTLPlusPeopleFeed *peopleFeed,
                                                             NSError *error) {
                                             if (error)
                                             {
                                                 GTMLoggerError(@"Error: %@", error);
                                             }
                                             else
                                             {
                                                 // Array of users from GTLPlusPeopleFeed
                                                 NSArray* peopleList = peopleFeed.items;
                                                 
                                                 for (GTLPlusPerson *people in peopleList)
                                                 {
                                                     
                                                     GTLQueryPlus *query1 = [GTLQueryPlus queryForActivitiesListWithUserId:[people identifier] collection:kGTLPlusCollectionPublic];
                                                     
                                                     [service executeQuery:query1
                                                         completionHandler:^(GTLServiceTicket *ticket,
                                                                                      GTLPlusActivityFeed *actFeed,
                                                                                      NSError *error) {
                                                                      
                                                                      NSArray *activities = [actFeed items];
                                                                      NSMutableDictionary *act = [[NSMutableDictionary alloc] init];
                                                                      
                                                                      for (GTLPlusActivity *activity in activities)
                                                                      {
                                                                          [act setObject:[activity title] forKey:kPostTextDictKey];
                                                                          [act setObject:[activity identifier] forKey:kPostIDDictKey];
                                                                          //[act setObject:[activity url] forKey:@"url"];
                                                                          //[act setObject:[[activity object] content] forKey:postTextDictKey];
                                                                          [act setObject:[[activity updated] date] forKey:kPostDateDictKey];
                                                                          [act setObject:[[[activity object] plusoners] totalItems] forKey:kPostLikesCountDictKey];
                                                                          
                                                                          NSDictionary *authorDict = @{kPostAuthorIDDictKey: [people identifier], kPostAuthorAvaURLDictKey: [[people image] url], kPostAuthorNameDictKey: [people displayName]};
                                                                          
                                                                          [act setObject:authorDict forKey:kPostAuthorDictKey];
                                                                          
                                                                          NSMutableArray *arrayWithMedia = [[NSMutableArray alloc] init];
                                                                          
                                                                          NSArray *attachments = [[activity object] attachments];
                                                                          if (attachments)
                                                                          {
                                                                              NSString *displayName, *fullImageURL, *thumbnailImageURL, *content, *url, *videoURL, *albumID, *albumURL, *photoID;
                                                                              
                                                                              displayName = nil;
                                                                              fullImageURL = nil;
                                                                              thumbnailImageURL = nil;
                                                                              content = nil;
                                                                              url = nil;
                                                                              videoURL = nil;
                                                                              albumID = nil;
                                                                              albumURL = nil;
                                                                              photoID = nil;
                                                                              
                                                                              for (GTLPlusActivityObjectAttachmentsItem *attachmentItem in attachments)
                                                                              {
                                                                                  NSMutableDictionary *tempMediaDict = [[NSMutableDictionary alloc] init];
//
                                                                                  if ([[attachmentItem objectType] isEqualToString:@"article"])
                                                                                  {
                                                                                      displayName = [attachmentItem displayName];
                                                                                      fullImageURL = [[attachmentItem fullImage] url];
                                                                                      thumbnailImageURL = [[attachmentItem image] url];
                                                                                      content = [attachmentItem content];
                                                                                      url = [attachmentItem url];
                                                                                      
                                                                                      if (![[act objectForKey:kPostTextDictKey] length] && [content length])
                                                                                      {
                                                                                          [act setObject:content forKey:kPostTextDictKey];
                                                                                      }
//
                                                                                      
                                                                                  }
                                                                                  if ([[attachmentItem objectType] isEqualToString:@"video"])
                                                                                  {
                                                                                      //[tempMediaDict setObject:@"video" forKey:kPostMediaTypeDictKey];
                                                                                      
                                                                                      displayName = [attachmentItem displayName];
                                                                                      content = [attachmentItem content];
                                                                                      videoURL = [attachmentItem url];
                                                                                      thumbnailImageURL = [[attachmentItem image] url];
                                                                                      
                                                                                      tempMediaDict = (NSMutableDictionary *)@{kPostMediaURLDictKey: videoURL, kPostMediaPreviewDictKey: thumbnailImageURL, kPostMediaTypeDictKey: @"video"};

                                                                                  }
                                                                                  if ([[attachmentItem objectType] isEqualToString:@"album"])
                                                                                  {
                                                                                      //[tempMediaDict setObject:@"image" forKey:kPostMediaTypeDictKey];
                                                                                      
                                                                                      displayName = [attachmentItem displayName];
                                                                                      albumID = [attachmentItem identifier];
                                                                                      albumURL = [attachmentItem url];
                                                                                      NSArray *thumbnails = [attachmentItem thumbnails];
                                                                    
                                                                                      NSMutableArray *thumbnailImages = [[NSMutableArray alloc] init];
                                                                                      for (GTLPlusActivityObjectAttachmentsItemThumbnailsItem *it in thumbnails)
                                                                                      {
                                                                                          [thumbnailImages addObject:@{kPostMediaPreviewDictKey: [[it image] url], kPostMediaURLDictKey: [[it image] url], kPostMediaTypeDictKey: @"image"}];
                                                                                      }
                                                                                      for (NSDictionary *dict in thumbnailImages)
                                                                                      {
                                                                                          [arrayWithMedia addObject:dict];
                                                                                      }
                                                                                  }
                                                                                  if ([[attachmentItem objectType] isEqualToString:@"photo"])
                                                                                  {
                                                                                      [tempMediaDict setObject:@"image" forKey:kPostMediaTypeDictKey];
                                                                                      
                                                                                      displayName = [attachmentItem displayName]; // may be nil
                                                                                      fullImageURL = [[attachmentItem fullImage] url];
                                                                                      thumbnailImageURL = [[attachmentItem image] url];
                                                                                      content = [attachmentItem content]; //NOT WORKING
                                                                                      albumURL = [attachmentItem url];
                                                                                      photoID = [attachmentItem identifier]; //may be nil
                                                                                      
                                                                                      tempMediaDict = (NSMutableDictionary *)@{kPostMediaURLDictKey: fullImageURL, kPostMediaPreviewDictKey: thumbnailImageURL, kPostMediaTypeDictKey: @"image"};
                                                                                  }
                                                                                  if (tempMediaDict)
                                                                                  {
                                                                                      [arrayWithMedia addObject:tempMediaDict];
                                                                                  }
                                                                              }
                                                                              
                                                                              if (arrayWithMedia)
                                                                              {
                                                                                  [act setObject:arrayWithMedia forKey:kPostMediaSetDictKey];
                                                                              }
                                                                          }
                                                                          
                                                                          if ([act objectForKey:@"text"])
                                                                          {
                                                                              //DLog(@"%@", [act objectForKey:@"text"]);
                                                                              NSMutableArray *hashTags = [[NSMutableArray alloc] init];
                                                                              
                                                                              NSMutableString *text = [[act objectForKey:@"text"] mutableCopy];
                                                                              NSRange range = [text rangeOfString:@"#"];
                                                                              while (range.location != NSNotFound)
                                                                              {
                                                                                  BOOL endOfString = YES;
                                                                                  NSInteger i = range.location + 1;
                                                                                  while (i < [text length])
                                                                                  {                                                                                                              if (([text characterAtIndex:i] == ' ' || [text characterAtIndex:i] == ',' || [text characterAtIndex:i] == '.' || [text characterAtIndex:i] == ';' || [text characterAtIndex:i] == '\n' || [text characterAtIndex:i] == '\t' || [[NSCharacterSet punctuationCharacterSet] characterIsMember:[text characterAtIndex:i]]) && i < [text length] - 1)
                                                                                      {
                                                                                          NSInteger length = i - range.location - 1;
                                                                                          DLog(@"HASHTAG #%@ handled;", [text substringWithRange:NSMakeRange(range.location + 1, length)]);
                                                                                          
                                                                                          [hashTags addObject:[text substringWithRange:NSMakeRange(range.location, length + 1)]];
                                                                                          [text deleteCharactersInRange:NSMakeRange(range.location, length + 1)];
                                                                                          range = [text rangeOfString:@"#"];
                                                                                          endOfString = NO;
                                                                                          break;
                                                                                      }
                                                                                      i++;
                                                                                  }
                                                                                  if (endOfString)
                                                                                  {
                                                                                      NSInteger tmpLength = [text length] - range.location - 1;
                                                                                      
                                                                                      [hashTags addObject:[text substringWithRange:NSMakeRange(range.location, tmpLength + 1)]];
                                                                                      DLog(@"HASHTAG #%@ handled;", [text substringWithRange:NSMakeRange(range.location, tmpLength)]);
                                                                                      [text deleteCharactersInRange:NSMakeRange(range.location, tmpLength)];
                                                                                      range = [text rangeOfString:@"#"];
                                                                                  }
                                                                              }
                                                                              
                                                                              if ([hashTags count])
                                                                              {
                                                                                  [act setObject:hashTags forKey:kPostTagsListKey];
                                                                              }
                                                                              
                                                                              if (act)
                                                                              {
                                                                                  [self addActivity:act];
                                                                                  
                                                                                  //[self.posts addObject:act];
                                                                              }
                                                                          }
                                                                      }
                                                                      //[self addActivity:self.posts];
                                                                  }];
                                                 }
                                             }
                                         }];
}
                                                 
- (void)getCommentsForPost:(NSMutableDictionary *)post postID:(NSString *)postID
{
    GTLQueryPlus *commentsQuery = [GTLQueryPlus queryForCommentsListWithActivityId:postID];
    
    //[[[GPPSignIn sharedInstance] plusService] executeQuery:commentsQuery delegate:self didFinishSelector:@selector(serviceTicket:finishedWithObject:error:)];
    
    [[[GPPSignIn sharedInstance] plusService] executeQuery:commentsQuery
                                         completionHandler:^(GTLServiceTicket *ticket, GTLPlusCommentFeed *feed, NSError *error) {
                                             DLog(@"");
                                             
                                             NSMutableArray *commentsArray = [[NSMutableArray alloc] init];
                                             
                                             if ([[feed items] count])
                                             {
                                                 for (GTLPlusComment *currentComment in [feed items])
                                                 {
                                                     NSMutableDictionary *commentDict = [[NSMutableDictionary alloc] init];
                                                     
                                                     [commentDict setObject:[[currentComment object] content] forKey:kPostCommentTextDictKey];
                                                     [commentDict setObject:[currentComment identifier] forKey:kPostCommentIDDictKey];
                                                     [commentDict setObject:[[currentComment published] date] forKey:kPostCommentDateDictKey];
                                                     
                                                     NSMutableDictionary *commentAuthorDict = [[NSMutableDictionary alloc] init];
                                                     [commentAuthorDict setObject:[[currentComment actor] displayName] forKey:kPostCommentAuthorNameDictKey];
                                                     [commentAuthorDict setObject:[[currentComment actor] identifier] forKey:kPostCommentAuthorIDDictKey];
                                                     [commentAuthorDict setObject:[[[currentComment actor] image] url] forKey:kPostCommentAuthorAvaURLDictKey];
                                                     
                                                     [commentDict setObject:commentAuthorDict forKey:kPostCommentAuthorDictKey];
                                                     
                                                     [commentsArray addObject:commentDict];
                                                 }
                                                 
                                                 [post setObject:commentsArray forKey:kPostCommentsDictKey];
                                                 
                                             }
                                             
                                             [_activityDelegate getAllactivities:(NSMutableArray *)@[post] socialNetwork:currentNetwork];
                                         }];

}

- (void)clearCookie
{
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *arrayOfCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    
    for(NSHTTPCookie* cookie in arrayOfCookies)
    {
        [cookies deleteCookie:cookie];
    }
}

- (void)getPostsForUser:(NSString *)userID socialNetwork:(SocialNetwork *)network andDelegate:(id <GooglePlusActivityDelegate>)activityDelegate
{
    allActivities = [[NSMutableArray alloc] init];
    
    currentOperation = GooglePlusOperationTypeGetPosts;
    _activityDelegate = activityDelegate;
    currentNetwork = network;
    
    NSString *keychainName = [NSString stringWithFormat:@"GooglePlus%@", userID];
    DLog(@"Keychain name: %@", keychainName);
    
//    GTMOAuth2Authentication *auth = nil;
//    auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:keychainName clientID:kGooglePlusClientID clientSecret:kGooglePlusClientSecret];

    signIn = [GPPSignIn sharedInstance];
    
    signIn.keychainName = keychainName;
    signIn.delegate = self;
    signIn.shouldFetchGooglePlusUser = YES;
    signIn.shouldFetchGoogleUserID = YES;
    signIn.shouldFetchGoogleUserEmail = YES;
    signIn.clientID = kGooglePlusClientID;
    signIn.scopes = [NSArray arrayWithObjects: kGTLAuthScopePlusLogin, kGTLAuthScopePlusMe, nil];
    
    [self performSelectorOnMainThread:@selector(log) withObject:nil waitUntilDone:YES];
}

- (void)log
{
    if ([signIn trySilentAuthentication])
    {
        DLog(@"Done");
        //[signIn authenticate];
    }
}

@end
