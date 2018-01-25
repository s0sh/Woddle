//
//  LinkedinRequest.m
//  Woddl
//
//  Created by Александр Бородулин on 06.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "LinkedinRequest.h"
#import "DDXML.h"
#import "Group.h"
#import "LinkedinRequestGetPostOperation.h"
#import "WDDAppDelegate.h"

#import "SocialNetwork.h"
#import "WDDDataBase.h"
#import "LinkedinPost.h"
#import "UserProfile.h"

typedef NS_ENUM(NSInteger, WDDLinkedinNotificationType)
{
    WDDLinkedinNotificationTypeActivityOfConnectionInApplication = 0,
    WDDLinkedinNotificationTypeApplicaitonToMemberDirectUpdate,
    WDDLinkedinNotificationTypeCompanyFollowUpdate,
    WDDLinkedinNotificationTypeConnectionHasAddedConnections,
    WDDLinkedinNotificationTypeContactJoinedLinkedin,
    WDDLinkedinNotificationTypeConnectionPostedJob,
    WDDLinkedinNotificationTypeJoinedGroup,
    WDDLinkedinNotificationTypeChangedPicture,
    WDDLinkedinNotificationTypePeopleFollowUpdate,
    WDDLinkedinNotificationTypeExtendedProfileUpdate,
    WDDLinkedinNotificationTypeRecommendationsPREC,
    WDDLinkedinNotificationTypeRecommendationsSVPR,
    WDDLinkedinNotificationTypeChangedProfile,
    WDDLinkedinNotificationTypeSharedItem,
    WDDLinkedinNotificationTypeViralUpdate,
    WDDLinkedinNotificationTypeUnknown = NSNotFound
};

const NSUInteger kCodeOfSuccessRequest = 201;

@implementation LinkedinRequest

static NSDateFormatter* dFormatter = nil;

static NSInteger const kMaxCountOfComments = 25;

static NSMutableArray * usersInfoArray = nil;
static NSMutableArray * usersOriginalImageArray = nil;
static NSMutableArray * usersPublicProfileURLsArray = nil;

static CGFloat const kInternetIntervalTimeout = 30.0;

- (NSArray*)getPostsWithToken:(NSString*)token andUserID:(NSString*)userID andGroups:(NSArray*)groups andCount:(NSUInteger)count
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
    for(NSDictionary* groupItem in groups)
    {
        [resultArray addObjectsFromArray:[self getGroupsPostsWithToken:token andGroupID:[groupItem objectForKey:@"groupID"] from:0 count:5]];
    }

    LinkedinRequest* request = [[LinkedinRequest alloc] init];
    NSArray* posts = [request getPostsWithToken:token andUserID:userID andCount:count isSelf:YES];
    [resultArray addObjectsFromArray:posts];

    request = [[LinkedinRequest alloc] init];
    posts = [request getPostsWithToken:token andUserID:userID andCount:count isSelf:NO];
    [resultArray addObjectsFromArray:posts];
    
    return resultArray;
}

static NSString * const st_fieldsToGet = @"";//@":(update-content:(person:(current-status,id,headline,first-name,last-name,picture-url,connections:(first-name,headline,last-name,picture-url,id),member-groups:(name,site-group-request),site-standard-profile-request:(url)),company-person-update:(person:(id,headline,first-name,last-name,picture-url)),company:(name,id)),update-type,update-key,timestamp,is-commentable,update-comments,num-likes,is-likable)";

static NSString * const st_typesToLoad = @"type=CONN";//@"type=MSFC&type=CONN&type=JGRP&type=PICT&type=SHAR&type=VIRL";
static NSString * const st_urlFormatFirst = @"https://api.linkedin.com/v1/people/~/network/updates%@?oauth2_access_token=%@&count=%ld&%@&format=json";
static NSString * const st_urlFormatMore = @"https://api.linkedin.com/v1/people/~/network/updates%@?oauth2_access_token=%@&count=%ld&start=%ld&%@&format=json";

-(NSArray *)getPostsWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count isSelf:(BOOL)isSelf
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    NSString *urlString = [NSString stringWithFormat:st_urlFormatFirst, st_fieldsToGet, token, (unsigned long)count, st_typesToLoad];
    
    if (isSelf)
    {
        urlString = [urlString stringByAppendingString:@"&scope=self"];
    }
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if(data)
    {
        [self getPostsWithData:data toArray:resultArray withToken:token andUserID:userID andCount:count isSelf:isSelf];
    }
    
    return resultArray;
}

-(NSArray*)loadMorePostsWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count from:(NSUInteger)from isSelf:(BOOL)isSelf
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    NSString *urlString = [NSString stringWithFormat:st_urlFormatMore, st_fieldsToGet, token, (unsigned long)count, (unsigned long)from, st_typesToLoad];
    
    if (isSelf)
    {
        urlString = [urlString stringByAppendingString:@"&scope=self"];
    }
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if(data)
    {
        [self getPostsWithData:data toArray:resultArray withToken:token andUserID:userID andCount:count isSelf:isSelf];
    }
    
    return resultArray;
}

- (NSString *)textForUpdate:(NSDictionary *)update media:(NSArray **)media token:(NSString *)token
{
    NSString* text = nil;
    
    NSDictionary* updateContent = [update objectForKey:@"updateContent"];
    NSDictionary* person;
    if ([updateContent objectForKey:@"companyPersonUpdate"])
    {
        NSDictionary* companyPersonUpdate = [updateContent objectForKey:@"companyPersonUpdate"];
        person = [companyPersonUpdate objectForKey:@"person"];
    }
    else
    {
        person = [updateContent objectForKey:@"person"];
    }
    NSString* updateType = [update objectForKey:@"updateType"];

    
    if([updateType isEqualToString:@"NCON"])
    {
        NSString *firstName = @"";
        NSString *lastName = @"";
        if([person objectForKey:@"firstName"])
        {
            firstName = [person objectForKey:@"firstName"];
        }
        if([person objectForKey:@"lastName"])
        {
            lastName = [person objectForKey:@"lastName"];
        }
        NSString* fullName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
        
        text = [fullName stringByAppendingFormat:@" %@", NSLocalizedString(@"lskAddMeToContactsList", @"Add to contacts linked in post")];
        
        NSDictionary* mediaResultDict = [self getAvatarImageDictionaryWithPerson:person
                                                                           token:token];
        if (mediaResultDict)
        {
            *media = @[ mediaResultDict ];
        }
    }
    if([updateType isEqualToString:@"MSFC"])
    {
        NSDictionary* company = [updateContent objectForKey:@"company"];
        NSString* companyWebsite = [self getCompanyURLWithID:[company objectForKey:@"id"] andToken:token];
        if(companyWebsite)
        {
            text = [NSLocalizedString(@"lskUserStartsFollowingCompany", @"Lined in following post text") stringByAppendingFormat:@" %@ %@", [company objectForKey:@"name"], companyWebsite];
        }
        else
        {
            text = [NSLocalizedString(@"lskUserStartsFollowingCompany", @"Lined in following post text") stringByAppendingFormat:@" %@", [company objectForKey:@"name"]];
        }
    }
    if([updateType isEqualToString:@"VIRL"])
    {
        NSDictionary *updateAction = updateContent[@"updateAction"];
        NSString *actionCode = updateAction[@"action"][@"code"];
        
        NSString *actionText = nil;
        if ([actionCode isEqualToString:@"LIKE"])
        {
            actionText = NSLocalizedString(@"lskLikedItemLinkedIn", @"");
        }
        else
        {
            return nil;
            
            actionText = @"!!! UNKNOWN ACTION !!!";
        }
        
        NSDictionary *originalUpdate = updateAction[@"originalUpdate"];
        if (originalUpdate)
        {
            text = [self textForUpdate:originalUpdate media:media token:token];
            
            if (!text.length && ![*media count])
            {
                return nil;
            }
            
            NSDictionary *personInfo = originalUpdate[@"updateContent"][@"person"];
            NSString *personName = nil;
            
            NSString *firstName = personInfo[@"firstName"];
            NSString *lastName = personInfo[@"lastName"];
            if (firstName.length && lastName.length)
            {
                personName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            }
            else if (firstName.length)
            {
                personName = firstName;
            }
            else
            {
                personName = lastName;
            }
            
            if (!personName.length)
            {
                personName = NSLocalizedString(@"lskSomeoneLinkedIn", @"");
            }
        
            actionText = [NSString stringWithFormat:actionText, personName];
            
            if (text.length)
            {
                text = [actionText stringByAppendingFormat:@"\n\n\n%@", text];
            }

            text = [actionText stringByAppendingString:text];
        }
    }
    if([updateType isEqualToString:@"CONN"])
    {
        NSMutableArray* mediaResultArray = [[NSMutableArray alloc] init];
        
        NSDictionary* connections = [person objectForKey:@"connections"];
        NSArray* connectionValues = [connections objectForKey:@"values"];
        NSMutableArray * namesArray = [[NSMutableArray alloc] init];
        for(NSDictionary* connection in connectionValues)
        {
            NSString *firstName = @"";
            NSString *lastName = @"";
            if([connection objectForKey:@"firstName"])
            {
                firstName = [connection objectForKey:@"firstName"];
            }
            if([connection objectForKey:@"lastName"])
            {
                lastName = [connection objectForKey:@"lastName"];
            }
            
            NSDictionary* mediaResultDict = [self getAvatarImageDictionaryWithPerson:connection
                                                                               token:token];
            
            if (mediaResultDict)
            {
                [mediaResultArray addObject:mediaResultDict];
            }
            
            NSString* headline = [connection objectForKey:@"headline"];
            
            NSString* fullName = @"";
            if(headline)
            {
                fullName = [NSString stringWithFormat:@"%@ %@, %@", firstName, lastName, headline];
            }
            else
            {
                fullName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
            }
            
            [namesArray addObject:fullName];
        }
        *media = mediaResultArray;
        
        NSMutableString* contactsStr = [[NSMutableString alloc] init];
        for(NSString* nameItem in namesArray)
        {
            if (contactsStr.length==0)
            {
                [contactsStr appendString:nameItem];
            }
            else
            {
                NSString* nameWithComma = [NSString stringWithFormat:@", %@",nameItem];
                [contactsStr appendString:nameWithComma];
            }
        }
        
        if (!contactsStr.length || [contactsStr isEqualToString:@" "]  ||
            ([contactsStr rangeOfString:@"private" options:NSCaseInsensitiveSearch].location != NSNotFound))
        {
            return nil;
        }
        
        text = [NSLocalizedString(@"lskNowConnectedTo", @"Linked in concact added text") stringByAppendingFormat:@" %@", contactsStr];
    }
    if([updateType isEqualToString:@"JGRP"])
    {
        NSDictionary* memberGroups = [person objectForKey:@"memberGroups"];
        NSArray* values = [memberGroups objectForKey:@"values"];
        NSMutableArray * groupsInfoArray = [[NSMutableArray alloc] init];
        for(NSDictionary* valueGroup in values)
        {
            /*
             NSString* groupName = [valueGroup objectForKey:@"name"];
             [namesArray addObject:groupName];
             */
            
            [groupsInfoArray addObject:valueGroup];
        }
        NSMutableString* contactsStr = [[NSMutableString alloc] init];
        for(NSDictionary* groupItem in groupsInfoArray)
        {
            NSDictionary* siteGroupRequest = [groupItem objectForKey:@"siteGroupRequest"];
            if (contactsStr.length==0)
            {
                NSString* nameWithoutComma = [NSString stringWithFormat:@"\"%@\" %@", [groupItem objectForKey:@"name"], [siteGroupRequest objectForKey:@"url"]];
                [contactsStr appendString:nameWithoutComma];
            }
            else
            {
                NSString* nameWithComma = [NSString stringWithFormat:@", \"%@\" %@",[groupItem objectForKey:@"name"], [siteGroupRequest objectForKey:@"url"]];
                [contactsStr appendString:nameWithComma];
            }
        }
        
        text = [NSLocalizedString(@"lskNowJoinedTo", @"LinkedIn joined to group post") stringByAppendingFormat:@" %@", contactsStr];
    }
    if([updateType isEqualToString:@"PICU"])
    {
        NSArray* mediaResultArray;
        NSDictionary* mediaResultDict = [self getAvatarImageDictionaryWithPerson:person
                                                                           token:token];
        if (mediaResultDict)
        {
            mediaResultArray = @[ mediaResultDict ];
        }
        
        *media = mediaResultArray;
        text = NSLocalizedString(@"lskNewPhoto", @"LinkedIn photo added post.");
    }
    if([updateType isEqualToString:@"PROF"] || [updateType isEqualToString:@"PRFU"]  || [updateType isEqualToString:@"PRFX"])
    {
//        DLog(@"GOT PROFILE UPDATE: %@", update);
        
        return nil;
        //                text = NSLocalizedString(@"lskUseUpdatedProfile", @"LinkedIn profile updated post.");
    }
    if([updateType isEqualToString:@"CCEM"])
    {
        text = NSLocalizedString(@"lskHasJoinedLinkedIn", @"LinkedIn has joined post.");
    }
    if([updateType isEqualToString:@"SHAR"])
    {
        NSDictionary *content = person[@"currentShare"][@"content"];
        NSString *comment = person[@"currentShare"][@"comment"];
        
        NSString *title = content[@"title"];
        NSString *description = content[@"description"];
        NSString *link = content[@"eyebrowUrl"];
        NSString *imageURL = content[@"submittedImageUrl"];
        NSString *thumbnailURL = content[@"thumbnailUrl"];
        
        if (imageURL.length || thumbnailURL.length)
        {
            NSDictionary *image = nil;
            if (imageURL.length && thumbnailURL.length)
            {
                image = @{ kPostMediaURLDictKey : imageURL, kPostMediaPreviewDictKey : thumbnailURL, kPostMediaTypeDictKey : @"image" };
            }
            else if (imageURL.length)
            {
                image = @{ kPostMediaURLDictKey : imageURL, kPostMediaPreviewDictKey : imageURL, kPostMediaTypeDictKey : @"image" };
            }
            else
            {
                image = @{ kPostMediaURLDictKey : thumbnailURL, kPostMediaPreviewDictKey : thumbnailURL, kPostMediaTypeDictKey : @"image" };
            }

            *media = @[image];
        }
        
        if (!description.length && title.length)
        {
            static NSString * const st_fileNamePattern = @"\\S*\\.[J,j,p,P][P,p,n,N][e,E]?[g,G]";
            static NSRegularExpression *regexp = nil;
            
            NSError *error = nil;
            if (!regexp)
            {
                regexp = [NSRegularExpression regularExpressionWithPattern:st_fileNamePattern options:0 error:&error];
            }
            
            NSArray *matches = [regexp matchesInString:title options:0 range:NSMakeRange(0, title.length)];
            NSRange range = [matches.firstObject range];
            
            if (range.location == 0 && range.length == title.length)
            {
                title = nil;
            }
        }
        
        if (!title.length && !description.length && imageURL.length)
        {
            link = nil;
        }
        
        NSString *contentText = title ?: @"";
        if (description.length)
        {
            contentText = [contentText stringByAppendingString: contentText.length ? [@"\n" stringByAppendingString:description] : description];
        }
        if (link.length)
        {
            contentText = [contentText stringByAppendingString: contentText.length ? [@"\n" stringByAppendingString:link] : link];
        }
        
        if (comment.length)
        {
            text = contentText.length ? [comment stringByAppendingString:@"\n\n"] : comment;
        }
        else
        {
            text = @"";
        }
        
        text = [text stringByAppendingString:contentText];
        
//        DLog(@"GOT SHAR UPDATE: %@", update);
    }
    if([updateType isEqualToString:@"PFOL"])
    {
        return nil;
    }
    if([updateType isEqualToString:@"CMPY"])
    {
        return nil;
    }
    if([updateType isEqualToString:@"APPS"])
    {
        return nil;
    }
    if([updateType isEqualToString:@"APPM"])
    {
        return nil;
    }
    if([updateType isEqualToString:@"PREC"] || [updateType isEqualToString:@"SVRP"])
    {
        return nil;
    }
    if([updateType isEqualToString:@"JOBP"])
    {
        return nil;
    }
    if(!text)
    {
        text = @"";
    }

    return text;
}

- (void)getPostsWithData:(NSData *)data
                 toArray:(NSMutableArray *)resultArray
               withToken:(NSString *)token
               andUserID:(NSString *)userID
                andCount:(NSUInteger)count
                  isSelf:(BOOL)isSelf
{
    NSError* error = nil;
    NSDictionary* json = [NSJSONSerialization
                          JSONObjectWithData:data
                          options:kNilOptions
                          error:&error];

//    DLog(@"LinkedIn response: %@", json);
    
    if(!error)
    {
        if ([json[@"status"] integerValue] == 401)
        {
            [self invalidateSocialNetworkWithToken:token];
            
            return;
        }
        
        DLog(@"LinkedIN replay: %@", json);
    
        NSArray* valuesArray = [json objectForKey:@"values"];
        for(NSDictionary* valueDict in valuesArray)
        {
            NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
            
            NSDictionary* updateContent = [valueDict objectForKey:@"updateContent"];
            NSDictionary* person;
            if ([updateContent objectForKey:@"companyPersonUpdate"])
            {
                NSDictionary* companyPersonUpdate = [updateContent objectForKey:@"companyPersonUpdate"];
                person = [companyPersonUpdate objectForKey:@"person"];
            }
            else
            {
                person = [updateContent objectForKey:@"person"];
            }

            NSString* personID = [person objectForKey:@"id"];
            NSString* updateKey = [valueDict objectForKey:@"updateKey"];
            NSNumber* timestampNum = [valueDict objectForKey:@"timestamp"];
            long long timestamp = ( [timestampNum isKindOfClass:[NSNumber class]] ? (long long )[timestampNum longLongValue]/1000 : 0);
            NSDate* dateAdding = [NSDate dateWithTimeIntervalSince1970:timestamp];
            
            [resultDictionary setObject:valueDict[@"isCommentable"] forKey:@"isCommentable"];
            [resultDictionary setObject:valueDict[@"isLikable"] forKey:@"isLikable"];
            
            NSArray* comments = nil;
            
            NSNumber* isCommentable = [valueDict objectForKey:@"isCommentable"];
            if(isCommentable.boolValue)
            {
                NSDictionary *commentsInfo = valueDict[@"updateComments"];
                [resultDictionary s_setObject:@([commentsInfo[@"_total"] integerValue]) forKey:kPostCommentsCountDictKey];
                
                if ([commentsInfo[@"_total"] integerValue])
                {
                    NSArray *commentsList = commentsInfo[@"values"];
                    if ([commentsList isKindOfClass:[NSArray class]] && commentsList.count == [commentsInfo[@"_total"] integerValue])
                    {
                        comments = [self getCommentsFromData:commentsInfo andToken:token];
                    }
                }
                
                if (!comments.count && (!commentsInfo[@"_total"] || [commentsInfo[@"_total"] integerValue]))
                {
                    comments = [self getCommentsFromPostID:updateKey andToken:token];
                }
            }
            else
            {
                [resultDictionary s_setObject:[NSNumber numberWithBool:NO] forKey:kPostIsCommentableDictKey];
            }
            
            NSString* firstName = [person objectForKey:@"firstName"];
            NSString* lastName = [person objectForKey:@"lastName"];
            NSString* avatarURL = [person objectForKey:@"pictureUrl"];
            NSString *profileURL = [LinkedinRequest publicProfileURLWithID:[person objectForKey:@"id"]
                                                                     token:token];
            
            NSString* picURL = [self getOriginalImageURLWithID:[person objectForKey:@"id"] andToken:token];
            if(picURL)
            {
                avatarURL = picURL;
            }
            
            ////////////////////
            NSString* name = nil;
            if(!firstName)
            {
                name = lastName;
            }
            else
            {
                name = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
            }
            
            if (!name.length || [name isEqualToString:@" "]  ||
                ([name rangeOfString:@"private" options:NSCaseInsensitiveSearch].location != NSNotFound))
            {
                continue;
            }
            
            NSArray *medias = nil;
            NSString *text = [self textForUpdate:valueDict media:&medias token:token];
            
            if (!text.length && !medias.count)
            {
                continue;
            }
            
            if (medias)
            {
                [resultDictionary setObject:medias forKey:kPostMediaSetDictKey];
            }
            
            [resultDictionary s_setObject:text forKey:kPostTextDictKey];
//            [resultDictionary s_setObject:[NSString stringWithFormat:@"%@%@_%@", userID, timestamp, updateType] forKey:kPostIDDictKey];
            [resultDictionary s_setObject:[NSString stringWithFormat:@"%@_%lld", updateKey, timestamp] forKey:kPostIDDictKey];
            [resultDictionary s_setObject:dateAdding forKey:kPostDateDictKey];
            [resultDictionary s_setObject:updateKey forKey:kPostUpdateKey];
            if (comments)
            {
                [resultDictionary s_setObject:comments forKey:kPostCommentsDictKey];
            }
            
            NSMutableDictionary* personPosted = [[NSMutableDictionary alloc] init];
            
            [personPosted setValue:name forKey:kPostAuthorNameDictKey];
            [personPosted setValue:avatarURL forKey:kPostAuthorAvaURLDictKey];
            [personPosted setValue:personID forKey:kPostAuthorIDDictKey];
            [personPosted setValue:profileURL forKey:kPostAuthorProfileURLDictKey];
            
            [resultDictionary setValue:personPosted forKey:kPostAuthorDictKey];
            
            //likes
            NSNumber* isLikable = [valueDict objectForKey:@"isLikable"];
            if(isLikable.boolValue)
            {
                NSNumber* likesCount = [NSNumber numberWithInt:0];
                if ([valueDict objectForKey:@"numLikes"])
                {
                    likesCount = [valueDict objectForKey:@"numLikes"];
                }
                [resultDictionary s_setObject:likesCount forKey:kPostLikesCountDictKey];
            }
            else
            {
                [resultDictionary s_setObject:[NSNumber numberWithBool:NO] forKey:kPostLikesIsLikableDictKey];
            }
            
            //link
            NSDictionary* siteStandardProfileRequest = [person objectForKey:@"siteStandardProfileRequest"];
            if (siteStandardProfileRequest[@"url"])
            {
                resultDictionary[kPostLinkOnWebKey] = siteStandardProfileRequest[@"url"];
            }
            
            [resultArray addObject:resultDictionary];
        }
        
        NSInteger gotCount = [json[@"_count"] integerValue];
        NSInteger start = [json[@"_start"] integerValue];
        NSInteger total = [json[@"_total"] integerValue];
        
        if (gotCount && total && (gotCount + start < total))
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"postID == %@ && subscribedBy.socialNetwork.accessToken == %@", resultArray.lastObject[@"postID"], token];
            NSArray *posts = [[WDDDataBase sharedDatabase] fetchObjectsWithEntityName:NSStringFromClass([LinkedinPost class])
                                                                        withPredicate:predicate
                                                                      sortDescriptors:nil];
            if (!posts.count)
            {
                count = MIN(count, total - (gotCount + start));
                [resultArray addObjectsFromArray:[self loadMorePostsWithToken:token andUserID:userID andCount:count from:gotCount+start isSelf:isSelf]];
            }
        }
    }
}

-(NSString*)getCompanyURLWithID:(NSString*)companyID andToken:(NSString*)token
{
    NSString* companyURL = nil;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/companies/%@:(website-url)?oauth2_access_token=%@&format=json", companyID, token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            if ([json[@"status"] integerValue] == 401)
            {
                [self invalidateSocialNetworkWithToken:token];
                
                return nil;
            }
            
            if([json objectForKey:@"websiteUrl"])
            {
                companyURL = [json objectForKey:@"websiteUrl"];
            }
        }
    }
    
    return companyURL;
}

-(NSString*)getOriginalImageURLWithID:(NSString*)userID andToken:(NSString*)token
{
    @synchronized(usersOriginalImageArray)
    {
        if(!usersOriginalImageArray)
        {
            usersOriginalImageArray = [[NSMutableArray alloc] init];
        }
        for(NSDictionary* userInfoItemDict in usersOriginalImageArray)
        {
            if([[userInfoItemDict objectForKey:@"userID"] isEqualToString:userID])
            {
                return [userInfoItemDict objectForKey:@"image"];
            }
        }
        NSString* resultString = nil;
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/%@/picture-urls::(original)?oauth2_access_token=%@&format=json",userID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
                NSMutableDictionary* userAvaImage = [[NSMutableDictionary alloc] init];
                
                if ([json[@"status"] integerValue] == 401)
                {
                    [self invalidateSocialNetworkWithToken:token];
                    
                    return nil;
                }
                
                if ([json objectForKey:@"values"])
                {
                    NSArray* values = [json objectForKey:@"values"];
                    [userAvaImage s_setObject:userID forKey:@"userID"];
                    [userAvaImage s_setObject:[values lastObject] forKey:@"image"];
                    [usersOriginalImageArray addObject:userAvaImage];
                    return [values lastObject];
                }
            }
        }
        return resultString;
    }
}

-(NSArray*)getCommentsFromPostID:(NSString*)postID andToken:(NSString*)token
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    //NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/~/network/updates/key=%@/update-comments?oauth2_access_token=%@&count=%i&format=json",postID,token,kMaxCountOfComments]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout]; //return most recent comments
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/~/network/updates/key=%@/update-comments:(comment,timestamp,person:(id,first-name,last-name))?oauth2_access_token=%@&count=%i&format=json",postID,token,kMaxCountOfComments]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    resultArray = [self getCommentsFromData:data andToken:token];
    return resultArray;
}

-(NSArray*)getCommentsFromGroupPostID:(NSString*)postID andToken:(NSString*)token
{
    NSInteger totalPostsCount = [self getCountOfCommentsFromGroupPostID:postID andToken:token];
    
    NSInteger startFrom = totalPostsCount - kMaxCountOfComments;
    
    if(startFrom<0)
    {
        startFrom = 0;
    }
    
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/posts/%@/comments?oauth2_access_token=%@&count=%i&start=%ld&format=json",postID,token,kMaxCountOfComments,(long)startFrom]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            if ([json[@"status"] integerValue] == 401)
            {
                [self invalidateSocialNetworkWithToken:token];
                
                return nil;
            }
            
            NSArray* values = [json objectForKey:@"values"];
            for (NSDictionary* value in values)
            {
                NSMutableDictionary* commentResultDict = [[NSMutableDictionary alloc] init];
                
                NSNumber* commentTimestampNum = [value objectForKey:@"creationTimestamp"];
                long long commentTimestamp = ( [commentTimestampNum isKindOfClass:[NSNumber class]] ? (long long )[commentTimestampNum longLongValue]/1000 : 0);
                [commentResultDict s_setObject:[value objectForKey:@"text"] forKey:kPostCommentTextDictKey];
                [commentResultDict s_setObject:[NSDate dateWithTimeIntervalSince1970:commentTimestamp] forKey:kPostCommentDateDictKey];
                
                
                NSDictionary* commentCreator = [value objectForKey:@"creator"];
                
                NSMutableDictionary* resultCommentCreator = [[NSMutableDictionary alloc] init];
                
                [resultCommentCreator s_setObject:[commentCreator objectForKey:@"id"] forKey:kPostCommentAuthorIDDictKey];
                [resultCommentCreator s_setObject:[commentCreator objectForKey:@"lastName"] forKey:kPostCommentAuthorNameDictKey];
                [resultCommentCreator s_setObject:[commentCreator objectForKey:@"pictureUrl"] forKey:kPostCommentAuthorAvaURLDictKey];
                
                
                NSString* commentID = [NSString stringWithFormat:@"%lld%@",commentTimestamp,[commentCreator objectForKey:@"id"]];
                [commentResultDict s_setObject:commentID forKey:kPostCommentIDDictKey];
                
                [commentResultDict s_setObject:resultCommentCreator forKey:kPostCommentAuthorDictKey];
                
                [resultArray addObject:commentResultDict];
                
            }
        }
    }
    
    return resultArray;
}

-(NSArray*)loadMoreCommentsFromGroupPostID:(NSString*)postID from:(NSInteger)from count:(NSInteger)count andToken:(NSString*)token
{
    NSInteger totalPostsCount = [self getCountOfCommentsFromGroupPostID:postID andToken:token];
    
    NSInteger startFrom = totalPostsCount - from - count;
    
    if(startFrom<0)
    {
        startFrom = 0;
    }
    
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/posts/%@/comments?oauth2_access_token=%@&count=%ld&start=%ld&format=json",postID,token,(long)count,(long)startFrom]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            if ([json[@"status"] integerValue] == 401)
            {
                [self invalidateSocialNetworkWithToken:token];
                
                return nil;
            }
            
            NSArray* values = [json objectForKey:@"values"];
            for (NSDictionary* value in values)
            {
                NSMutableDictionary* commentResultDict = [[NSMutableDictionary alloc] init];
                
                NSNumber* commentTimestampNum = [value objectForKey:@"creationTimestamp"];
                long long commentTimestamp = ( [commentTimestampNum isKindOfClass:[NSNumber class]] ? (long long )[commentTimestampNum longLongValue]/1000 : 0);
                [commentResultDict s_setObject:[value objectForKey:@"text"] forKey:kPostCommentTextDictKey];
                [commentResultDict s_setObject:[NSDate dateWithTimeIntervalSince1970:commentTimestamp] forKey:kPostCommentDateDictKey];
                
                
                NSDictionary* commentCreator = [value objectForKey:@"creator"];
                
                NSMutableDictionary* resultCommentCreator = [[NSMutableDictionary alloc] init];
                
                [resultCommentCreator s_setObject:[commentCreator objectForKey:@"id"] forKey:kPostCommentAuthorIDDictKey];
                [resultCommentCreator s_setObject:[commentCreator objectForKey:@"lastName"] forKey:kPostCommentAuthorNameDictKey];
                [resultCommentCreator s_setObject:[commentCreator objectForKey:@"pictureUrl"] forKey:kPostCommentAuthorAvaURLDictKey];
                
                
                NSString* commentID = [NSString stringWithFormat:@"%lld%@",commentTimestamp,[commentCreator objectForKey:@"id"]];
                [commentResultDict s_setObject:commentID forKey:kPostCommentIDDictKey];
                
                [commentResultDict s_setObject:resultCommentCreator forKey:kPostCommentAuthorDictKey];
                
                [resultArray addObject:commentResultDict];
                
            }
        }
    }
    
    return resultArray;
}

-(NSUInteger)getCountOfCommentsFromGroupPostID:(NSString*)postID andToken:(NSString*)token
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/posts/%@/comments?oauth2_access_token=%@&format=json&count=1",postID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            if ([json[@"status"] integerValue] == 401)
            {
                [self invalidateSocialNetworkWithToken:token];
                
                return 0;
            }
            
            if([json objectForKey:@"_total"])
            {
                NSNumber* total = [json objectForKey:@"_total"];
                return total.integerValue;
            }
        }
    }
    
    return 0;
}

-(NSArray*)getMoreCommentsFromGroupPostID:(NSString*)postID andToken:(NSString*)token
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/posts/%@/comments?oauth2_access_token=%@&count=%i&format=json",postID,token,kMaxCountOfComments]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            if ([json[@"status"] integerValue] == 401)
            {
                [self invalidateSocialNetworkWithToken:token];
                
                return nil;
            }
            
            NSArray* values = [json objectForKey:@"values"];
            for (NSDictionary* value in values)
            {
                NSMutableDictionary* commentResultDict = [[NSMutableDictionary alloc] init];
                
                NSNumber* commentTimestampNum = [value objectForKey:@"creationTimestamp"];
                long long commentTimestamp = ( [commentTimestampNum isKindOfClass:[NSNumber class]] ? (long long )[commentTimestampNum longLongValue]/1000 : 0);
                [commentResultDict s_setObject:[value objectForKey:@"text"] forKey:kPostCommentTextDictKey];
                [commentResultDict s_setObject:[NSDate dateWithTimeIntervalSince1970:commentTimestamp] forKey:kPostCommentDateDictKey];
                
                
                NSDictionary* commentCreator = [value objectForKey:@"creator"];
                
                NSMutableDictionary* resultCommentCreator = [[NSMutableDictionary alloc] init];
                
                [resultCommentCreator s_setObject:[commentCreator objectForKey:@"id"] forKey:kPostCommentAuthorIDDictKey];
                [resultCommentCreator s_setObject:[commentCreator objectForKey:@"lastName"] forKey:kPostCommentAuthorNameDictKey];
                [resultCommentCreator s_setObject:[commentCreator objectForKey:@"pictureUrl"] forKey:kPostCommentAuthorAvaURLDictKey];
                
                
                NSString* commentID = [NSString stringWithFormat:@"%lld%@",commentTimestamp,[commentCreator objectForKey:@"id"]];
                [commentResultDict s_setObject:commentID forKey:kPostCommentIDDictKey];
                
                [commentResultDict s_setObject:resultCommentCreator forKey:kPostCommentAuthorDictKey];
                
                [resultArray addObject:commentResultDict];
                
            }
        }
    }
    
    return resultArray;
}


-(NSArray*) getMoreCommentsFromPostID:(NSString*)postID andToken:(NSString*) token
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/~/network/updates/key=%@/update-comments?oauth2_access_token=%@&count=25&start=0&format=json",postID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout]; //return most recent comments
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    resultArray = [self getCommentsFromData:data andToken:token];
    
    return resultArray;
}

-(NSMutableArray *)getCommentsFromData:(id)data andToken:(NSString *)token
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    if(data)
    {
        NSDictionary* json = nil;
        NSError* error = nil;
        
        if ([data isKindOfClass:[NSData class]])
        {
            json = [NSJSONSerialization JSONObjectWithData:data
                                                   options:kNilOptions
                                                     error:&error];
        }
        else
        {
            json = (NSDictionary *)data;
        }
        
        if(!error)
        {
            if ([json[@"status"] integerValue] == 401)
            {
                [self invalidateSocialNetworkWithToken:token];
                
                return nil;
            }
            
            NSNumber* total = [json objectForKey:@"_total"];
            if(total.intValue>0)
            {
                NSArray* values = [json objectForKey:@"values"];
                for(NSDictionary* comment in values)
                {
                    NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
                    //NSNumber* commentIDNum = [comment objectForKey:@"id"];
                    //NSString* commentID = commentIDNum.stringValue;
                    NSString* commentText = [comment objectForKey:@"comment"];
                    NSNumber* commentTimeNum = [comment objectForKey:@"timestamp"];
                    long long commentTimestamp = ( [commentTimeNum isKindOfClass:[NSNumber class]] ? (long long )[commentTimeNum longLongValue]/1000 : 0);
                    
                    NSDate* commentDate = [NSDate dateWithTimeIntervalSince1970:commentTimestamp];
                    
                    NSDictionary* persAddComment = [comment objectForKey:@"person"];
                    NSString* commentID = nil;
                    
                    if (comment[@"id"])
                    {
                        commentID = [NSString stringWithFormat:@"%@", comment[@"id"]];
                    }
                    else
                    {
                        commentID = [NSString stringWithFormat:@"%lld%@",commentTimestamp,[persAddComment objectForKey:@"id"]];
                    }
                    
                    [resultDictionary s_setObject:commentID forKey:kPostCommentIDDictKey];
                    [resultDictionary s_setObject:commentText forKey:kPostCommentTextDictKey];
                    [resultDictionary s_setObject:commentDate forKey:kPostCommentDateDictKey];
                    
                    //person infocommentTimestamp
                    NSDictionary* personDict = [comment objectForKey:@"person"];
                    NSString* authorID = [personDict objectForKey:@"id"];
                    NSString* firstName = [personDict objectForKey:@"firstName"];
                    NSString* lastName = [personDict objectForKey:@"lastName"];
                    NSString *profileURL = [LinkedinRequest publicProfileURLWithID:personDict[@"id"]
                                                                             token:token];
                    
                    NSString* authorName = nil;
                    if(firstName)
                    {
                        authorName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                    }
                    else
                    {
                        authorName = lastName;
                    }
                    
                    NSDictionary* authorInfo = [self getUserInfoWithID:authorID andAccessToken:token];
                    
                    NSMutableDictionary *authorInfoDict = [[NSMutableDictionary alloc] init];
                    [authorInfoDict s_setObject:authorID forKey:kPostCommentAuthorIDDictKey];
                    [authorInfoDict s_setObject:authorName forKey:kPostCommentAuthorNameDictKey];
                    if ([authorInfo objectForKey:kPostCommentAuthorAvaURLDictKey])
                    {
                        [authorInfoDict s_setObject:[authorInfo objectForKey:kPostCommentAuthorAvaURLDictKey] forKey:kPostCommentAuthorAvaURLDictKey];
                    }
                    if (profileURL)
                    {
                        [authorInfoDict s_setObject:profileURL forKey:kPostAuthorProfileURLDictKey];
                    }
                    
                    [resultDictionary s_setObject:authorInfoDict forKey:kPostCommentAuthorDictKey];
                    
                    [resultArray addObject:resultDictionary];
                }
            }
        }
    }
    return resultArray;
}

-(BOOL)setLikeOnObjectID:(NSString*)objectID withToken:(NSString*)token
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/~/network/updates/key=%@/is-liked?oauth2_access_token=%@",objectID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    
    NSString * str = [NSString stringWithFormat:@"<?xml version=\"1.0\"?>\n<is-liked>true</is-liked>"];
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[str dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger code = [httpResponse statusCode];
    if (code==kCodeOfSuccessRequest)
    {
        return YES;
    }
    else
    {
        NSString *stringResponse = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        DLog(@"Can't like post %@ (%d), because of: %@", objectID, code, stringResponse);
    }
    return NO;
}

-(BOOL)setLikeOnGroupObjectID:(NSString*)objectID withToken:(NSString*)token
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/posts/%@/relation-to-viewer/is-liked?oauth2_access_token=%@",objectID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    
    NSString * str = [NSString stringWithFormat:@"<?xml version=\"1.0\"?>\n<is-liked>true</is-liked>"];
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[str dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error = nil; NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger code = [httpResponse statusCode];
    if (code==204)
    {
        return YES;
    }
    return NO;
}

-(BOOL)setUnlikeOnObjectID:(NSString*)objectID withToken:(NSString*)token
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/~/network/updates/key=%@/is-liked?oauth2_access_token=%@",objectID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    
    NSString * str = [NSString stringWithFormat:@"<?xml version=\"1.0\"?>\n<is-liked>false</is-liked>"];
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[str dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error = nil; NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger code = [httpResponse statusCode];
    if (code==kCodeOfSuccessRequest)
    {
        return YES;
    }
    return NO;
}

-(BOOL)setUnlikeOnGroupObjectID:(NSString*)objectID withToken:(NSString*)token
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/posts/%@/relation-to-viewer/is-liked?oauth2_access_token=%@",objectID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    
    NSString * str = [NSString stringWithFormat:@"<?xml version=\"1.0\"?>\n<is-liked>false</is-liked>"];
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[str dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error = nil; NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger code = [httpResponse statusCode];
    if (code==204)
    {
        return YES;
    }
    return NO;
}

-(NSDictionary*)addCommentToPost:(NSString*)postID withToken:(NSString*)token andMessage:(NSString*)message andUserID:(NSString*)userID
{
    [self addCommentToGroupPost:postID withToken:token andMessage:message andUserID:userID];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/~/network/updates/key=%@/update-comments?oauth2_access_token=%@",postID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSMutableDictionary* info = [[NSMutableDictionary alloc] init];
    NSString * str = [NSString stringWithFormat:@"<?xml version=\"1.0\"?>\n<update-comment>\n<comment>%@</comment>\n</update-comment>",message];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[str dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSError *error = nil; NSURLResponse *response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger code = [httpResponse statusCode];
    
    if (code==kCodeOfSuccessRequest)
    {
        NSDictionary* headers = [httpResponse allHeaderFields];
        NSString* dateCreation = [headers objectForKey:@"Date"];
        NSString* timeCreation = [NSString stringWithFormat:@"%i",[LinkedinRequest convertLinkedinDateToTimestamp:dateCreation]];
        NSString* commentID = [NSString stringWithFormat:@"%@%@",timeCreation,userID];
        NSDate* dateAdding = [NSDate dateWithTimeIntervalSince1970:[timeCreation longLongValue]];
        [info s_setObject:dateAdding forKey:kPostCommentDateDictKey];
        [info s_setObject:commentID forKey:kPostCommentIDDictKey];
        [info s_setObject:message forKey:kPostCommentTextDictKey];
        [info s_setObject:[NSNumber numberWithInt:0] forKey:kPostCommentLikesCountDictKey];
        return info;
    }
    else
    {
        error = nil;
        DDXMLDocument *xmlDocument = [[DDXMLDocument alloc] initWithData:data options:0 error:&error];
        if(!error)
        {
            DDXMLElement *rootElement = xmlDocument.rootElement;
            DDXMLElement* statusElement = [[rootElement elementsForName:@"status"] objectAtIndex:0];
            if(statusElement)
            {
                NSString* status = [statusElement stringValue];
                [info s_setObject:status forKey:@"error"];
                return info;
            }
        }
    }
    return nil;
}

-(NSDictionary*)addCommentToGroupPost:(NSString*)postID withToken:(NSString*)token andMessage:(NSString*)message andUserID:(NSString*)userID
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/posts/%@/comments?oauth2_access_token=%@",postID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSMutableDictionary* info = [[NSMutableDictionary alloc] init];
    NSString * str = [NSString stringWithFormat:@"<?xml version=\"1.0\"?>\n<comment>\n<text>%@</text>\n</comment>",message];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[str dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSError *error = nil; NSURLResponse *response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger code = [httpResponse statusCode];
    
    if (code==kCodeOfSuccessRequest)
    {
        NSDictionary* headers = [httpResponse allHeaderFields];
        NSString* dateCreation = [headers objectForKey:@"Date"];
        NSString* timeCreation = [NSString stringWithFormat:@"%i",[LinkedinRequest convertLinkedinDateToTimestamp:dateCreation]];
        NSString* commentID = [NSString stringWithFormat:@"%@%@",timeCreation,userID];
        NSDate* dateAdding = [NSDate dateWithTimeIntervalSince1970:[timeCreation longLongValue]];
        [info s_setObject:dateAdding forKey:kPostCommentDateDictKey];
        [info s_setObject:commentID forKey:kPostCommentIDDictKey];
        [info s_setObject:message forKey:kPostCommentTextDictKey];
        [info s_setObject:[NSNumber numberWithInt:0] forKey:kPostCommentLikesCountDictKey];
        return info;
    }
    else
    {
        error = nil;
        DDXMLDocument *xmlDocument = [[DDXMLDocument alloc] initWithData:data options:0 error:&error];
        if(!error)
        {
            DDXMLElement *rootElement = xmlDocument.rootElement;
            DDXMLElement* statusElement = [[rootElement elementsForName:@"status"] objectAtIndex:0];
            if(statusElement)
            {
                NSString* status = [statusElement stringValue];
                [info s_setObject:status forKey:@"error"];
                return info;
            }
        }
    }
    return nil;
}


-(NSDictionary*)isPostLikedMe:(NSString*)postID withToken:(NSString*)token andMyID:(NSString*)myID
{
    
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/~/network/updates/key=%@/likes?oauth2_access_token=%@&format=json",postID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            if ([json[@"status"] integerValue] == 401)
            {
                [self invalidateSocialNetworkWithToken:token];
                
                return nil;
            }
            
            if([json objectForKey:@"_total"])
            {
                NSNumber* total = [json objectForKey:@"_total"];
                if(total.intValue>0)
                {
                    NSArray* values = [json objectForKey:@"values"];
                    for(NSDictionary* like in values)
                    {
                        NSDictionary* person = [like objectForKey:@"person"];
                        NSString* personID = [person objectForKey:@"id"];
                        if([personID isEqualToString:myID])
                        {
                            [result s_setObject:[NSNumber numberWithBool:YES] forKey:@"isLiked"];
                            return result;
                        }
                    }
                }
                [result setObject:@NO forKey:@"isLiked"];
                return result;
            }
            else if (![json[@"errorCode"] integerValue])
            {
                [result setObject:@NO forKey:@"isLiked"];
                return result;
            }
            else
            {
                [result s_setObject:@"error" forKey:@"error"];
                if([json objectForKey:@"errorCode"])
                {
                    [result setValuesForKeysWithDictionary:json];
                    return result;
                }
            }
        }
    }
    [result s_setObject:@"error" forKey:@"error"];
    return result;
}

-(NSDictionary*)isGroupPostLikedMe:(NSString*)postID withToken:(NSString*)token andMyID:(NSString*)myID
{
    NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/posts/%@:(relation-to-viewer:(is-liked))?oauth2_access_token=%@&format=json",postID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            if ([json[@"status"] integerValue] == 401)
            {
                [self invalidateSocialNetworkWithToken:token];
                
                return nil;
            }
            
            if([json objectForKey:@"relationToViewer"])
            {
                
                NSDictionary* relationToViewer = [json objectForKey:@"relationToViewer"];
                
                NSNumber* isLiked = [relationToViewer objectForKey:@"isLiked"];
                
                [result s_setObject:isLiked forKey:@"isLiked"];
                
                return result;
            }
            else
            {
                [result s_setObject:@"error" forKey:@"error"];
                if([json objectForKey:@"errorCode"])
                {
                    [result setValuesForKeysWithDictionary:json];
                    return result;
                }
            }
        }
    }
    [result s_setObject:@"error" forKey:@"error"];
    return result;
}

-(BOOL)addStatusPostWithToken:(NSString*)token andMessage:(NSString*)message withLink:(NSString*)link andDescription:(NSString*)description andImageURL:(NSString*)imageURL
{
    
    NSMutableDictionary* update = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* visibility = [[NSMutableDictionary alloc] init];
    [visibility s_setObject:@"anyone" forKey:@"code"];
    [update s_setObject:visibility forKey:@"visibility"];
    if(message)
    {
        [update s_setObject:message forKey:@"comment"];
    }
    if(link)
    {
        NSMutableDictionary * content = [[NSMutableDictionary alloc] init];
        [content s_setObject:link forKey:@"submittedUrl"];
        if(description)
        {
            [content s_setObject:description forKey:@"description"];
        }
        if(imageURL)
        {
            [content s_setObject:imageURL forKey:@"submittedImageUrl"];
        }
        [update s_setObject:content forKey:@"content"];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/~/shares?oauth2_access_token=%@",token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    NSString *updateString = nil;
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:update
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    if (! jsonData) {
        DLog(@"Got an error: %@", error);
    } else {
        updateString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    NSURLResponse *response = nil;
    [request setHTTPBody:[updateString dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger code = [httpResponse statusCode];
    
    if (code==kCodeOfSuccessRequest)
    {
        return YES;
    }
    return NO;
}
/*
-(BOOL)addStatusWithToken:(NSString*)token andMessage:(NSString*)message andImageURL:(NSString*)imageURL
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/~/current-status?oauth2_access_token=%@",token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    
    NSString * str = [NSString stringWithFormat:@"<?xml version=\"1.0\"?>\n<current-status>%@</current-status>",message];
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"application/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[str dataUsingEncoding:NSUTF8StringEncoding]];
    NSError *error = nil; NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger code = [httpResponse statusCode];
    if (code==kCodeOfSuccessRequest||code==204)
    {
        return YES;
    }
    return NO;
}
 */

-(BOOL)addStatusWithToken:(NSString*)token andMessage:(NSString*)message andImageURL:(NSString*)imageURL
{
    
    NSMutableDictionary* update = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* visibility = [[NSMutableDictionary alloc] init];
    [visibility s_setObject:@"anyone" forKey:@"code"];
    [update s_setObject:visibility forKey:@"visibility"];
    if(message)
    {
        [update s_setObject:message forKey:@"comment"];
    }
    if(imageURL)
    {
        NSMutableDictionary * content = [[NSMutableDictionary alloc] init];
        if(imageURL)
        {
            SocialNetwork *socialNetwork = [[WDDDataBase sharedDatabase] fetchObjectsWithEntityName:NSStringFromClass([SocialNetwork class])
                                                                                                               withPredicate:[NSPredicate predicateWithFormat:@"accessToken == %@ AND type == %d", token, kSocialNetworkLinkedIN]
                                                                                                             sortDescriptors:nil].firstObject;
            NSString *text = [NSString stringWithFormat:NSLocalizedString(@"lskSharedPhotoLinedIn", @""), socialNetwork.profile.name];
            
            [content s_setObject:text forKey:@"title"];
//            [content s_setObject:@"www.woddl.com" forKey:@"submitted-url"];
//            [content s_setObject:@"photo" forKey:@"title"];
//            if(true)
//            {
//                [content s_setObject:@"photo" forKey:@"description"];
//            }

//            [content s_setObject:imageURL forKey:@"submitted-image-url"];
            [content s_setObject:imageURL forKey:@"submitted-url"];
        }
        [update s_setObject:content forKey:@"content"];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/~/shares?oauth2_access_token=%@",token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setValue:@"json" forHTTPHeaderField:@"x-li-format"];
    [request setValue:@"application/xml" forHTTPHeaderField:@"Content-Type"];
    NSString *updateString = nil;
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:update
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    if (! jsonData) {
        DLog(@"Got an error: %@", error);
    } else {
        updateString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }
    NSURLResponse *response = nil;
    [request setHTTPBody:[updateString dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    NSInteger code = [httpResponse statusCode];
    
    if (code==kCodeOfSuccessRequest || code==204)
    {
        return YES;
    }
    
    return NO;
}


-(NSDictionary*)getUserInfoWithID:(NSString*)userID andAccessToken:(NSString*)token
{
    @synchronized(usersInfoArray)
    {
        if(!usersInfoArray)
        {
            usersInfoArray = [[NSMutableArray alloc] init];
        }
        for(NSDictionary* userInfoItemDict in usersInfoArray)
        {
            if([[userInfoItemDict objectForKey:@"userID"] isEqualToString:userID])
            {
                return userInfoItemDict;
            }
        }
        NSMutableDictionary* userInfo = [[NSMutableDictionary alloc] init];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/id=%@:(picture-url)?oauth2_access_token=%@&format=json",userID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
                if ([json[@"status"] integerValue] == 401)
                {
                    [self invalidateSocialNetworkWithToken:token];
                    
                    return nil;
                }
                
                if ([json objectForKey:@"pictureUrl"])
                {
                    NSString* pictureURL = [json objectForKey:@"pictureUrl"];
                    [userInfo s_setObject:pictureURL forKey:kPostCommentAuthorAvaURLDictKey];
                    [userInfo s_setObject:userID forKey:@"userID"];
                    [usersInfoArray addObject:userInfo];
                }
            }
        }
        return userInfo;
    }
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

+ (NSString *)publicProfileURLWithID:(NSString *)profileID token:(NSString *)token
{
    @synchronized(usersPublicProfileURLsArray)
    {
        if(!usersPublicProfileURLsArray)
        {
            usersPublicProfileURLsArray = [[NSMutableArray alloc] init];
        }
        
        for(NSDictionary* profileURL in usersPublicProfileURLsArray)
        {
            if([profileURL objectForKey:profileID])
            {
                return [profileURL objectForKey:profileID];
            }
        }
        
        NSString *publicURLString;
    
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/%@:(public-profile-url)?oauth2_access_token=%@&format=json",profileID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
        NSError *error = nil; NSURLResponse *response = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
        if (!error)
        {
            NSDictionary *urlDict = [NSJSONSerialization JSONObjectWithData:data
                                                                    options:0
                                                                      error:&error];
            if (!error)
            {
                publicURLString = urlDict[@"publicProfileUrl"];
                
                if(publicURLString)
                {
                    NSDictionary* publicURLDict = [NSDictionary dictionaryWithObject:publicURLString forKey:profileID];
                    [usersPublicProfileURLsArray addObject:publicURLDict];
                }
            }
        }
    
        return publicURLString;
        
    }
}

-(NSArray*)getFriendsWithToken:(NSString*)token
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/~/connections:(id,first-name,last-name,site-standard-profile-request,picture-url)?oauth2_access_token=%@&format=json",token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (!error)
    {
        error = nil;
        NSDictionary* json = [NSJSONSerialization
                              JSONObjectWithData:data
                              options:kNilOptions
                              error:&error];
        if(!error)
        {
            if ([json[@"status"] integerValue] == 401)
            {
                [self invalidateSocialNetworkWithToken:token];
                
                return nil;
            }
            
            NSArray* values = [json objectForKey:@"values"];
            for(NSDictionary* value in values)
            {
                NSMutableDictionary* resultDictionary = [[NSMutableDictionary alloc] init];
                [resultDictionary s_setObject:[value objectForKey:@"id"] forKey:kFriendID];
                [resultDictionary s_setObject:[[value objectForKey:@"siteStandardProfileRequest"] objectForKey:@"url"] forKey:kFriendLink];
                [resultDictionary s_setObject:[value objectForKey:@"pictureUrl"] forKey:kFriendPicture];
                
                NSString* firstName = [value objectForKey:@"firstName"];
                NSString* lastName = [value objectForKey:@"lastName"];
                
                if(!firstName)
                    firstName = @"";
                if(!lastName)
                    lastName = @"";
                
                NSString* name = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                [resultDictionary s_setObject:name forKey:kFriendName];
                
                [resultArray addObject:resultDictionary];
            }
        }
    }
    
    return resultArray;
}

-(NSArray*)getGroupsWithToken:(NSString*)token
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/people/~/group-memberships:(group:(id))?oauth2_access_token=%@&format=json",token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            if ([json[@"status"] integerValue] == 401)
            {
                [self invalidateSocialNetworkWithToken:token];
                
                return nil;
            }
            
            NSArray * values = [json objectForKey: @"values"];
            for (NSDictionary* value in values)
            {
                NSDictionary* group = [value objectForKey:@"group"];
                NSString* groupID = [group objectForKey:@"id"];
                
                NSDictionary* resultDict = [self getGroupInfoWithID:groupID andToken:token];
                if(resultDict)
                {
                    [resultArray addObject:resultDict];
                }
            }
        }
    }
    return resultArray;
}

-(NSDictionary*)getGroupInfoWithID:(NSString*)groupID andToken:(NSString*)token
{
    NSMutableDictionary* resultDict = [[NSMutableDictionary alloc] init];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/groups/%@:(name,short-description,website-url,site-group-url,large-logo-url)?oauth2_access_token=%@&format=json",groupID,token]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            if ([json[@"status"] integerValue] == 401)
            {
                [self invalidateSocialNetworkWithToken:token];
                
                return nil;
            }
            
            if([json objectForKey:@"name"])
            {
                [resultDict s_setObject:[json objectForKey:@"name"] forKey:kGroupNameKey];
                [resultDict s_setObject:[json objectForKey:@"largeLogoUrl"] forKey:kGroupImageURLKey];
                [resultDict s_setObject:[json objectForKey:@"websiteUrl"] forKey:kGroupURLKey];
                [resultDict s_setObject:groupID forKey:kGroupIDKey];
                [resultDict s_setObject:[NSNumber numberWithInt:kGroupTypeGroup] forKey:kGroupTypeKey];
                
                return resultDict;
            }
        }
    }
    
    return nil;
}

-(NSArray*)getGroupsPostsWithToken:(NSString*) token andGroupID:(NSString *) groupID from:(NSInteger)from count:(NSInteger) count
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.linkedin.com/v1/groups/%@/posts:(id,creation-timestamp,title,comments;count=5,creator)?oauth2_access_token=%@&format=json&count=%ld&start=%ld",groupID,token,(long)count,(long)from]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            if ([json[@"status"] integerValue] == 401)
            {
                [self invalidateSocialNetworkWithToken:token];
                
                return nil;
            }
            
            NSArray* values = [json objectForKey:@"values"];
            
            for (NSDictionary* value in values)
            {
                NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
                
                [resultDictionary s_setObject:[value objectForKey:@"title"] forKey:kPostTextDictKey];
                
                NSNumber* timestampNum = [value objectForKey:@"creationTimestamp"];
                long long timestamp = ( [timestampNum isKindOfClass:[NSNumber class]] ? (long long )[timestampNum longLongValue]/1000 : 0);
                
                [resultDictionary s_setObject:[NSDate dateWithTimeIntervalSince1970:timestamp] forKey:kPostDateDictKey];
                [resultDictionary s_setObject:[value objectForKey:@"id"] forKey:kPostUpdateKey];
                [resultDictionary s_setObject:groupID forKey:kPostGroupID];
                [resultDictionary s_setObject:@(kGroupTypeGroup) forKey:kPostGroupType];
                [resultDictionary s_setObject:value[@"id"] forKey:kPostIDDictKey];
                
                //creator
                
                NSDictionary* creator = [value objectForKey:@"creator"];
                
                NSMutableDictionary* personPosted = [[NSMutableDictionary alloc] init];
                
                NSString* firstName = [creator objectForKey:@"firstName"];
                NSString* lastName = [creator objectForKey:@"lastName"];
                
                NSString* creatorName = nil;
                
                if(lastName && firstName)
                {
                    creatorName = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
                }
                else if(!firstName)
                {
                    creatorName = lastName;
                }
                else
                {
                    creatorName = firstName;
                }
                
                NSString *profileURL = [LinkedinRequest publicProfileURLWithID:[creator objectForKey:@"id"]
                                                                         token:token];
                
                [personPosted s_setObject:creatorName forKey:kPostAuthorNameDictKey];
                [personPosted s_setObject:[creator objectForKey:@"pictureUrl"] forKey:kPostAuthorAvaURLDictKey];
                [personPosted s_setObject:[creator objectForKey:@"id"] forKey:kPostAuthorIDDictKey];
                [personPosted s_setObject:profileURL forKey:kPostAuthorProfileURLDictKey];
                
                [resultDictionary setValue:personPosted forKey:kPostAuthorDictKey];
                
//                [resultDictionary s_setObject:[NSString stringWithFormat:@"%@%@",timestamp,[creator objectForKey:@"id"]] forKey:kPostIDDictKey];
                
                //comments
                
                NSDictionary* comments = [value objectForKey:@"comments"];
                
                NSNumber *totalComments = [comments objectForKey:@"_total"];
                
                NSArray* commentsValues = [comments objectForKey:@"values"];
                
                NSMutableArray * resultCommentsArray = [[NSMutableArray alloc] init];
                
                [resultDictionary s_setObject:totalComments forKey:kPostCommentsCountDictKey];
                
                for(NSDictionary* comment in commentsValues)
                {
                    
                    NSMutableDictionary* commentResultDict = [[NSMutableDictionary alloc] init];
                    
                    NSNumber* commentTimestampNum = [comment objectForKey:@"creationTimestamp"];
                    long long commentTimestamp = ( [commentTimestampNum isKindOfClass:[NSNumber class]] ? (long long )[commentTimestampNum longLongValue]/1000 : 0);
                    
                    [commentResultDict s_setObject:[comment objectForKey:@"text"] forKey:kPostCommentTextDictKey];
                    [commentResultDict s_setObject:[NSDate dateWithTimeIntervalSince1970:commentTimestamp] forKey:kPostCommentDateDictKey];
                    
                    NSDictionary* commentCreator = [comment objectForKey:@"creator"];
                    
                    NSMutableDictionary* resultCommentCreator = [[NSMutableDictionary alloc] init];
                    
                    [resultCommentCreator s_setObject:[commentCreator objectForKey:@"id"] forKey:kPostCommentAuthorIDDictKey];
                    [resultCommentCreator s_setObject:[commentCreator objectForKey:@"lastName"] forKey:kPostCommentAuthorNameDictKey];
                    [resultCommentCreator s_setObject:[commentCreator objectForKey:@"pictureUrl"] forKey:kPostCommentAuthorAvaURLDictKey];
                    
                    NSString* commentID = [NSString stringWithFormat:@"%lld%@",commentTimestamp,[commentCreator objectForKey:@"id"]];
                    [commentResultDict s_setObject:commentID forKey:kPostCommentIDDictKey];
                    
                    [commentResultDict s_setObject:resultCommentCreator forKey:kPostCommentAuthorDictKey];
                    
                    [resultCommentsArray addObject:commentResultDict];
                    
                }
                
                [resultDictionary s_setObject:resultCommentsArray forKey:kPostCommentsDictKey];
                
                [resultArray addObject:resultDictionary];
            }
        }
    }
    
    return resultArray;
}

- (BOOL)getUsersWhosLikedPostWithID:(NSString *)postId accessToken:(NSString *)accessToken
{
    return YES;
}

- (BOOL)updateLikesAndFavoritesForPostWithID:(NSString *)postId accessToken:(NSString *)accessToken
{
    return YES;
}

+ (NSInteger)convertLinkedinDateToTimestamp:(NSString*)date
{
    @synchronized(dFormatter)
    {
        //NSString* created_at = @"16 Dec 2013 09:40:27 GMT";
        NSMutableString *dateMutableStr = [[NSMutableString alloc]init];
        [dateMutableStr appendString:[date substringWithRange:NSMakeRange(5, [date length]-5)]];
    
        if(!dFormatter)
        {
            dFormatter = [[NSDateFormatter alloc] init];
            [dFormatter setLocale:[NSLocale localeWithLocaleIdentifier:@"En_us"]];
            [dFormatter setDateFormat:@"d MMM yyyy HH:mm:ss Z"];
        }
    
        NSDate* convertedDate = [dFormatter dateFromString:dateMutableStr];
        NSInteger timestamp = [convertedDate timeIntervalSince1970];
        return timestamp;
    }
}

- (void)invalidateSocialNetworkWithToken:(NSString *)token
{
    DLog(@"Got invalid token state.");
    
    SocialNetwork *network = [[WDDDataBase sharedDatabase] fetchObjectsWithEntityName:NSStringFromClass([SocialNetwork class])
                                                                        withPredicate:[NSPredicate predicateWithFormat:@"accessToken == %@ AND type == %d", token, kSocialNetworkLinkedIN]
                                                                      sortDescriptors:nil].firstObject;
    
    DLog(@"Found SN with invalid token %@", network);
    
    network.accessToken = nil;
    network.activeState = @NO;
//    [network updateSocialNetworkOnParseNow:YES];
    
    DLog(@"Clean token");
    [network updateSocialNetworkOnParse];
    
    DLog(@"Updating social network on parse.com");
    [[WDDDataBase sharedDatabase] save];
    
    DLog(@"Saved updated SN to DB");
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[WDDDataBase sharedDatabase] save];
        DLog(@"Saved updated SN to DB in main thread");
    });
}

#pragma mark - Operation Queue

+ (NSOperationQueue *)operationQueue
{
    NSMutableDictionary *operationQueues = [LinkedinRequest operationQueues];
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

#pragma mark - help methods

- (NSDictionary *)getAvatarImageDictionaryWithPerson:(NSDictionary *)person
                                   token:(NSString *)token
{
    NSMutableDictionary *mediaResultDict = nil;
    
    if([person objectForKey:@"pictureUrl"])
    {
        mediaResultDict = [NSMutableDictionary new];
        NSString* picURL = [self getOriginalImageURLWithID:[person objectForKey:@"id"] andToken:token];
        if(picURL)
        {
            [mediaResultDict s_setObject:picURL forKey:kPostMediaURLDictKey];
        }
        else
        {
            [mediaResultDict s_setObject:[person objectForKey:@"pictureUrl"] forKey:kPostMediaURLDictKey];
        }
        [mediaResultDict s_setObject:[person objectForKey:@"pictureUrl"] forKey:kPostMediaPreviewDictKey];
        [mediaResultDict s_setObject:@"image" forKey:kPostMediaTypeDictKey];
    }
    
    return mediaResultDict;
}

- (void)getNotificationsWithToken:(NSString*)accessToken
                           userId:(NSString*)userId
                            after:(NSString*)after
                  completionBlock:(void(^)(NSDictionary *resultDictionary))completionBlock
                  completionQueue:(dispatch_queue_t)queue
{
    void (^completionBlk)(NSDictionary *resultDictionary) = [completionBlock copy];
    
    static NSArray *linkedInUpdateTypes;
    
    if (!linkedInUpdateTypes)
    {
        linkedInUpdateTypes = @[@"APPS",
                                @"APPM",
                                @"CMPY",
                                @"CONN",
                                @"CCEM",
                                @"JOBP",
                                @"JGRP",
                                @"PICU",
                                @"PFOL",
                                @"PRFX",
                                @"PREC",
                                @"SVPR",
                                @"PROF",
                                @"SHAR",
                                @"VIRL"
                                ];
    }
    
    NSString *requestString =
    [NSString stringWithFormat:@"https://api.linkedin.com/v1/people/~/network/updates?oauth2_access_token=%@&after=%@&format=json&scope=self", accessToken, after];
    
    NSURL *requestURL       = [NSURL        URLWithString:requestString];
    NSURLRequest *request   = [NSURLRequest requestWithURL:requestURL];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
                                         {
                                             NSMutableDictionary * resultDictionary     = [NSMutableDictionary new];
                                             resultDictionary[@"notifications"]         = [NSMutableArray new];
                                             NSArray            * values                = JSON[@"values"];
                                             
                                             [values enumerateObjectsUsingBlock:^(NSDictionary *object, NSUInteger idx, BOOL *stop)
                                              {
                                                  
                                                  NSString * updateType                   = object[@"updateType"];
                                                  WDDLinkedinNotificationType noteType    = [linkedInUpdateTypes indexOfObject:updateType];
                                                  NSMutableDictionary * notification         = [NSMutableDictionary new];

                                                  NSDictionary * updateContent = [object objectForKey:@"updateContent"];
                                                  NSDictionary * person;
                                                  if ([updateContent objectForKey:@"companyPersonUpdate"])
                                                  {
                                                      NSDictionary * companyPersonUpdate = [updateContent objectForKey:@"companyPersonUpdate"];
                                                      person = [companyPersonUpdate objectForKey:@"person"];
                                                  }
                                                  else
                                                  {
                                                      person = [updateContent objectForKey:@"person"];
                                                  }
                                                  
                                                  NSString * personID       = [person objectForKey:@"id"];
                                                  NSString * updateKey      = [object objectForKey:@"updateKey"];
                                                  NSNumber * timestampNum   = [object objectForKey:@"timestamp"];
                                                  long long timestamp       = ( [timestampNum isKindOfClass:[NSNumber class]] ? (long long )[timestampNum longLongValue]/1000 : 0);
                                                  NSDate * dateAdding       = [NSDate dateWithTimeIntervalSince1970:timestamp];
                                                  
                                                  notification[@"notificationId"]   = [NSString stringWithFormat:@"%lu_%@",
                                                                                       (unsigned long)timestamp,
                                                                                       personID];
                                                  
                                                  if (noteType == WDDLinkedinNotificationTypeActivityOfConnectionInApplication)
                                                  {
                                                      notification = nil;
                                                  }
                                                  else if (noteType == WDDLinkedinNotificationTypeApplicaitonToMemberDirectUpdate)
                                                  {
                                                      notification = nil;
                                                  }
                                                  else if (noteType == WDDLinkedinNotificationTypeCompanyFollowUpdate)
                                                  {
                                                      notification = nil;
                                                  }
                                                  else if (noteType == WDDLinkedinNotificationTypeConnectionHasAddedConnections)
                                                  {
                                                      
                                                      NSMutableArray * mediaResultArray = [[NSMutableArray alloc] init];
                                                      
                                                      NSDictionary * connections    = [person objectForKey:@"connections"];
                                                      NSArray * connectionValues    = [connections objectForKey:@"values"];
                                                      NSMutableArray * namesArray   = [[NSMutableArray alloc] init];
                                                      
                                                      for (NSDictionary * connection in connectionValues)
                                                      {
                                                          NSString * firstName = @"";
                                                          NSString * lastName = @"";
                                                          if ([connection objectForKey:@"firstName"])
                                                          {
                                                              firstName = [connection objectForKey:@"firstName"];
                                                          }
                                                          if([connection objectForKey:@"lastName"])
                                                          {
                                                              lastName = [connection objectForKey:@"lastName"];
                                                          }
                                                          
                                                          NSString* headline = [connection objectForKey:@"headline"];
                                                          
                                                          NSString* fullName = @"";
                                                          if(headline)
                                                          {
                                                              fullName = [NSString stringWithFormat:@"%@ %@, %@", firstName, lastName, headline];
                                                          }
                                                          else
                                                          {
                                                              fullName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                                                          }
                                                          
                                                          [namesArray addObject:fullName];
                                                      }
                                                      [resultDictionary s_setObject:mediaResultArray forKey:kPostMediaSetDictKey];
                                                      
                                                      NSMutableString * contactsStr = [[NSMutableString alloc] init];
                                                      for(NSString* nameItem in namesArray)
                                                      {
                                                          if (contactsStr.length==0)
                                                          {
                                                              [contactsStr appendString:nameItem];
                                                          }
                                                          else
                                                          {
                                                              NSString* nameWithComma = [NSString stringWithFormat:@", %@",nameItem];
                                                              [contactsStr appendString:nameWithComma];
                                                          }
                                                      }
                                                      
                                                      if (!contactsStr.length || [contactsStr isEqualToString:@" "]  ||
                                                          ([contactsStr rangeOfString:@"private" options:NSCaseInsensitiveSearch].location != NSNotFound))
                                                      {
                                                          notification = nil;
                                                      }
                                                      else
                                                      {
                                                          if (notification[@"notificationId"])
                                                          {
                                                              notification[@"notificationId"] = [@"CT" stringByAppendingString:notification[@"notificationId"]];
                                                          }
                                                          notification[@"title"]           = [NSLocalizedString(@"lskNowConnectedTo", @"Linked in concact added text") stringByAppendingFormat:@" %@", contactsStr];
                                                          notification[@"senderId"]        = personID;
                                                          notification[@"date"]            = dateAdding;
                                                      }
                                                  }
                                                  else if(noteType == WDDLinkedinNotificationTypeConnectionHasAddedConnections)
                                                  {
                                                      if (notification[@"notificationId"])
                                                      {
                                                          notification[@"notificationId"] = [@"JP" stringByAppendingString:notification[@"notificationId"]];
                                                      }
                                                      
                                                      notification[@"title"]           = NSLocalizedString(@"lskHasJoinedLinkedIn", @"LinkedIn has joined post.");
                                                      notification[@"senderId"]        = personID;
                                                      notification[@"date"]            = dateAdding;
                                                  }
                                                  else if (noteType == WDDLinkedinNotificationTypeConnectionPostedJob)
                                                  {
                                                      notification = nil;
                                                  }
                                                  else if(noteType == WDDLinkedinNotificationTypeJoinedGroup)
                                                  {
                                                      if (notification[@"notificationId"])
                                                      {
                                                          notification[@"notificationId"] = [@"JG" stringByAppendingString:notification[@"notificationId"]];
                                                      }
                                                      
                                                      NSDictionary    * memberGroups      = [person objectForKey:@"memberGroups"];
                                                      NSArray         * values            = [memberGroups objectForKey:@"values"];
                                                      NSMutableArray  * groupsInfoArray   = [[NSMutableArray alloc] init];
                                                      
                                                      for(NSDictionary* valueGroup in values)
                                                      {
                                                          /*
                                                           NSString* groupName = [valueGroup objectForKey:@"name"];
                                                           [namesArray addObject:groupName];
                                                           */
                                                          
                                                          [groupsInfoArray addObject:valueGroup];
                                                      }
                                                      
                                                      NSMutableString* contactsStr = [[NSMutableString alloc] init];
                                                      for(NSDictionary* groupItem in groupsInfoArray)
                                                      {
                                                          NSDictionary* siteGroupRequest = [groupItem objectForKey:@"siteGroupRequest"];
                                                          if (contactsStr.length==0)
                                                          {
                                                              NSString* nameWithoutComma = [NSString stringWithFormat:@"\"%@\" %@", [groupItem objectForKey:@"name"], [siteGroupRequest objectForKey:@"url"]];
                                                              [contactsStr appendString:nameWithoutComma];
                                                          }
                                                          else
                                                          {
                                                              NSString* nameWithComma = [NSString stringWithFormat:@", \"%@\" %@",[groupItem objectForKey:@"name"], [siteGroupRequest objectForKey:@"url"]];
                                                              [contactsStr appendString:nameWithComma];
                                                          }
                                                      }
                                                      
                                                      notification[@"title"]           = [NSLocalizedString(@"lskNowJoinedTo", @"LinkedIn joined to group post") stringByAppendingFormat:@" %@", contactsStr];
                                                      notification[@"senderId"]        = personID;
                                                      notification[@"date"]            = dateAdding;
                                                  }
                                                  else if(noteType == WDDLinkedinNotificationTypeChangedPicture)
                                                  {
                                                      if (notification[@"notificationId"])
                                                      {
                                                          notification[@"notificationId"] = [@"CP" stringByAppendingString:notification[@"notificationId"]];
                                                      }
                                                      notification[@"title"]           = NSLocalizedString(@"lskNewPhoto", @"LinkedIn photo added post.");
                                                      notification[@"senderId"]        = personID;
                                                      notification[@"date"]            = dateAdding;
                                                  }
                                                  else if (noteType == WDDLinkedinNotificationTypePeopleFollowUpdate)
                                                  {
                                                      notification = nil;
                                                  }
                                                  else if (noteType == WDDLinkedinNotificationTypeExtendedProfileUpdate)
                                                  {
                                                      notification = nil;
                                                  }
                                                  else if (noteType == WDDLinkedinNotificationTypeRecommendationsPREC)
                                                  {
                                                      notification = nil;
                                                  }
                                                  else if (noteType == WDDLinkedinNotificationTypeRecommendationsSVPR)
                                                  {
                                                      notification = nil;
                                                  }
                                                  else if (noteType == WDDLinkedinNotificationTypeChangedProfile)
                                                  {
                                                      notification = nil;
                                                  }
                                                  else if (noteType == WDDLinkedinNotificationTypeSharedItem)
                                                  {
                                                      notification = nil;
                                                  }
                                                  else if (noteType == WDDLinkedinNotificationTypeViralUpdate)
                                                  {
                                                      notification = nil;
                                                  }
                                                  else if (noteType == WDDLinkedinNotificationTypeUnknown)
                                                  {
                                                      notification = nil;
                                                  }
                                                  
                                                  if (notification)
                                                  {
                                                      [notification setObject:@(1) forKey:@"isUnread"];
                                                      [resultDictionary[@"notifications"] addObject:notification];
                                                  }
                                              }];
                                             
                                             if (completionBlk)
                                             {
                                                 completionBlk(resultDictionary);
                                             }
                                         }
                                                                                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
                                         {
                                             if (completionBlk)
                                             {
                                                 completionBlk(nil);
                                             }
                                         }];
    
    operation.successCallbackQueue = queue;
    operation.failureCallbackQueue = queue;
    
    [operation start];
}

@end
