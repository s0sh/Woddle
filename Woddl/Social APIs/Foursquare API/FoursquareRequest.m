//
//  FoursquareRequest.m
//  Woddl
//
//  Created by Александр Бородулин on 07.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FoursquareRequest.h"

#import "WDDDataBase.h"
#import "SocialNetwork.h"
#import "Post.h"
#import "UserProfile.h"
#import "Comment.h"
#import "FoursquareOthersProfile.h"

@implementation FoursquareRequest

static NSString* const version = @"20131101";
static NSInteger const kRadiusCheckin = 1000;
static NSString * const kFoursquareHTTPSBaseURLString = @"https://foursquare.com";
static NSString * const kFoursquareUserPathComponent = @"user";
static CGFloat const kInternetIntervalTimeout = 30.0;


-(NSArray*)getPostsWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count
{
    [self getFriendsWithToken:token];
    
    NSArray* resultArray = [[NSArray alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.foursquare.com/v2/checkins/recent?oauth_token=%@&v=%@&limit=%ld",token,version,count]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    NSError *error = nil; NSURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    resultArray = [self getPostsWithData:data andAccessToken:token];
    
    return resultArray;
}

-(NSArray*)getPostsWithData:(NSData*)data andAccessToken:(NSString*)token
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
            NSDictionary* response = [json objectForKey:@"response"];
            NSArray* recent = [response objectForKey:@"recent"];
            for(NSDictionary* recentDict in recent)
            {
                NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
                NSMutableDictionary *authorResultDict = [[NSMutableDictionary alloc] init];
                NSDictionary* venue = [recentDict objectForKey:@"venue"];
                NSString* createdAt = [recentDict objectForKey:@"createdAt"];
                NSDictionary* location = [venue objectForKey:@"location"];
                NSString* address = [location objectForKey:@"address"];
                NSString* name = [venue objectForKey:@"name"];
                NSString* postID = [recentDict objectForKey:@"id"];
                NSDate* dateAdding = [NSDate dateWithTimeIntervalSince1970:[createdAt longLongValue]];
                
                NSString* shout = @"";
                if([recentDict objectForKey:@"shout"])
                {
                    shout = [recentDict objectForKey:@"shout"];
                }
                
                [resultDictionary s_setObject:postID forKey:kPostIDDictKey];
                if(!address)
                {
                    [resultDictionary s_setObject:[NSString stringWithFormat:@"%@ \n%@",name,shout] forKey:kPostTextDictKey];
                }
                else
                {
                    [resultDictionary s_setObject:[NSString stringWithFormat:@"%@ %@ \n%@",name,address,shout] forKey:kPostTextDictKey];
                }
                [resultDictionary s_setObject:dateAdding forKey:kPostDateDictKey];
                
                NSMutableDictionary *placeDict = [[NSMutableDictionary alloc] initWithCapacity:8];
                [placeDict s_setObject:venue[@"id"] forKey:kPlaceIdDictKey];
                [placeDict s_setObject:name forKey:kPlaceNameDictKey];
                [placeDict s_setObject:location[@"cc"] forKey:kPlaceCountryCodeDictKey];
                [placeDict s_setObject:@([location[@"lat"] doubleValue]) forKey:kPlaceLatitudeDictKey];
                [placeDict s_setObject:@([location[@"lng"] doubleValue]) forKey:kPlaceLongitudeDictKey];
                [placeDict s_setObject:@([venue[@"stats"][@"checkinsCount"] integerValue]) forKey:kPlaceCheckinsCountDictKey];
                [placeDict s_setObject:@([venue[@"verified"] boolValue]) forKey:kPlaceVerifiedDictKey];
                if (address)
                {
                    [placeDict s_setObject:address forKey:kPlaceAddressDictKey];
                }
                [resultDictionary setObject:@[placeDict] forKey:kPostPlacesListKey];
                
                //User Info
                NSDictionary* authorDict = [recentDict objectForKey:@"user"];
                NSString* firstName = [authorDict objectForKey:@"firstName"];
                NSString* lastName = [authorDict objectForKey:@"lastName"];
                NSString* authorName = nil;
                
                if (firstName && lastName)
                {
                    authorName = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                }
                else if (firstName)
                {
                    authorName = firstName;
                }
                else
                {
                    authorName = lastName;
                }

                NSString* authorID = [authorDict objectForKey:@"id"];
                NSDictionary* photoDict = [authorDict objectForKey:@"photo"];
                NSString* photoPrefix = [photoDict objectForKey:@"prefix"];
                NSString* photoSuffix = [photoDict objectForKey:@"suffix"];
                NSString* userPicture = [NSString stringWithFormat:@"%@64x64%@",photoPrefix,photoSuffix];
                [authorResultDict s_setObject:authorName forKey:kPostAuthorNameDictKey];
                [authorResultDict s_setObject:authorID forKey:kPostAuthorIDDictKey];
                [authorResultDict s_setObject:userPicture forKey:kPostAuthorAvaURLDictKey];
                [authorResultDict s_setObject:[FoursquareRequest profileURLWithID:authorID] forKey:kPostAuthorProfileURLDictKey];
                
                [resultDictionary s_setObject:authorResultDict forKey:kPostAuthorDictKey];
                
                if (authorID && recentDict[@"id"])
                {
                    NSString *link = @"https://foursquare.com/user";
                    link = [NSString stringWithFormat:@"%@/%@/%@/%@", link, authorID, @"checkin", recentDict[@"id"]];
                    resultDictionary[kPostLinkOnWebKey] = link;
                }
                
                NSArray* photosArray = [self getVenuePhotosWithObjectID:[venue objectForKey:@"id"] andToken:token];
                NSMutableArray* mediaResultArray = [[NSMutableArray alloc] init];
                for(NSDictionary* photoURL in photosArray)
                {
                    NSMutableDictionary* mediaResultDict = [[NSMutableDictionary alloc] init];
                    [mediaResultDict s_setObject:photoURL forKey:kPostMediaURLDictKey];
                    [mediaResultDict s_setObject:@"image" forKey:kPostMediaTypeDictKey];
                    [mediaResultArray addObject:mediaResultDict];
                }
                
                [resultDictionary s_setObject:mediaResultArray forKey:kPostMediaSetDictKey];
                
                // comments
                NSDictionary* commentsDict = [recentDict objectForKey:@"comments"];
                NSNumber* countOfComments = [NSNumber numberWithInt:0];
                if ([commentsDict objectForKey:@"items"])
                {
                    NSMutableArray* allComments = [[NSMutableArray alloc] init];
                    NSArray* commentsArray = [commentsDict objectForKey:@"items"];
                    for(NSDictionary* comment in commentsArray)
                    {
                        NSMutableDictionary *commentResult = [[NSMutableDictionary alloc] init];
                        NSMutableDictionary *authorComment = [[NSMutableDictionary alloc] init];
                        NSString* commentID = [comment objectForKey:@"id"];
                        NSString* textComment = [comment objectForKey:@"text"];
                        NSString* commentData = [comment objectForKey:@"createdAt"];
                        NSDate* dateAddingComment = [NSDate dateWithTimeIntervalSince1970:[commentData longLongValue]];
                        [commentResult s_setObject:commentID forKey:kPostCommentIDDictKey];
                        [commentResult s_setObject:textComment forKey:kPostCommentTextDictKey];
                        [commentResult s_setObject:dateAddingComment forKey:kPostCommentDateDictKey];
                        NSDictionary* authorInfo = [comment objectForKey:@"user"];
                        NSString* authorID = [authorInfo objectForKey:@"id"];
                        NSString* firstName = @"";
                        NSString* lastName = @"";
                        if ([authorInfo objectForKey:@"firstName"])
                            firstName = [authorInfo objectForKey:@"firstName"];
                        if ([authorInfo objectForKey:@"lastName"])
                            lastName = [authorInfo objectForKey:@"lastName"];
                        NSString* name = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                        if ([authorInfo objectForKey:@"photo"])
                        {
                            NSDictionary* photoAuthorDic = [authorInfo objectForKey:@"photo"];
                            NSString* prefix = [photoAuthorDic objectForKey:@"prefix"];
                            NSString* suffix = [photoAuthorDic objectForKey:@"suffix"];
                            NSString* photoAuthorURL = [NSString stringWithFormat:@"%@64x64%@",prefix,suffix];
                            [authorComment s_setObject:photoAuthorURL forKey:kPostCommentAuthorAvaURLDictKey];
                        }
                        [authorComment s_setObject:authorID forKey:kPostCommentAuthorIDDictKey];
                        [authorComment s_setObject:name forKey:kPostCommentAuthorNameDictKey];
                        [authorComment s_setObject:[FoursquareRequest profileURLWithID:authorID] forKey:kPostAuthorProfileURLDictKey];
                        
                        [commentResult s_setObject:authorComment forKey:kPostCommentAuthorDictKey];
                        
                        [allComments addObject:commentResult];
                        
                        [resultDictionary s_setObject:allComments forKey:kPostCommentsDictKey];
                    }
                    countOfComments = [NSNumber numberWithInt:commentsArray.count];
                }
                [resultDictionary s_setObject:countOfComments forKey:kPostCommentsCountDictKey];
                
                NSNumber* likesCount = [NSNumber numberWithInt:0];
                if ([recentDict objectForKey:@"likes"])
                {
                    NSDictionary* likes = [recentDict objectForKey:@"likes"];
                    likesCount = [likes objectForKey:@"count"];
                }
                
                [resultDictionary s_setObject:likesCount forKey:kPostLikesCountDictKey];
                
                [resultArray addObject:resultDictionary];
            }
        }
    }
    
    return resultArray;
}

-(BOOL)isPostLikedMe:(NSString*)postID withToken:(NSString*)token andMyID:(NSString*)myID
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.foursquare.com/v2/checkins/%@/likes?oauth_token=%@&v=%@",postID,token,version]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            if ([json objectForKey:@"response"])
            {
                NSDictionary* response = [json objectForKey:@"response"];
                NSNumber *isLiked = [response objectForKey:@"like"];
                if(isLiked.boolValue)
                    return YES;
            }
        }
    }
    return NO;
}

-(BOOL)setLikeOnObjectID:(NSString*)objectID withToken:(NSString*)token
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.foursquare.com/v2/checkins/%@/like?oauth_token=%@&v=%@",objectID,token,version]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"set=%@",@"1"] dataUsingEncoding:NSUTF8StringEncoding]];
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
                if(code.integerValue==200)
                    return YES;
            }
        }
    }
    return NO;
}

-(BOOL)setUnlikeOnObjectID:(NSString*)objectID withToken:(NSString*)token
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.foursquare.com/v2/checkins/%@/like?oauth_token=%@&v=%@",objectID,token,version]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"set=%@",@"0"] dataUsingEncoding:NSUTF8StringEncoding]];
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
                if(code.integerValue==200)
                    return YES;
            }
        }
    }
    return NO;
}

-(NSDictionary*)addCommentOnObjectID:(NSString*)objectID withToken:(NSString*)token andMessage:(NSString*)message
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.foursquare.com/v2/checkins/%@/addcomment?oauth_token=%@&v=%@",objectID,token,version]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
                if(code.integerValue==200)
                {
                    /*
                    
                    NSDictionary* info = [NSDictionary dictionaryWithObject: forKey:@"id"];
                     */
                    NSDictionary* response = [json objectForKey:@"response"];
                    NSDictionary* comment = [response objectForKey:@"comment"];
                    NSMutableDictionary* info = [[NSMutableDictionary alloc] init];
                    [info s_setObject:[NSDate date] forKey:kPostCommentDateDictKey];
                    [info s_setObject:[comment objectForKey:@"id"] forKey:kPostCommentIDDictKey];
                    [info s_setObject:message forKey:kPostCommentTextDictKey];
                    [info s_setObject:[NSNumber numberWithInt:0] forKey:kPostCommentLikesCountDictKey];
                    return info;
                }
            }
        }
    }
    return nil;
}

-(NSError*)addStatusWithToken:(NSString*)token andMessage:(NSString *)message location:(WDDLocation *)location andImage:(UIImage *)photo
{
    NSString *lat = [NSNumber numberWithDouble:location.latidude].stringValue;
    NSString *lon = [NSNumber numberWithDouble:location.longitude].stringValue;
    
    NSString* venueID = location.foursquareID;
    if (!venueID)
    {
        venueID = [self searchVenuesesWithToken:token andLatitude:lat longitude:lon];
    }
    if(venueID)
    {
        if(!message||[message isEqualToString:@""])
        {
            if(photo)
            {
                if([self addPhoto:photo withToken:token andVenueID:venueID])
                {
                    return nil;
                }
                
                NSInteger code = 101;
                NSString* errorDomain = @"woodlDomain";
                NSArray *objArray = [NSArray arrayWithObjects:@"post not completed", @"no message or photo", nil];
                NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
                NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
                return error;
            }
        }
        else
        {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.foursquare.com/v2/checkins/add?oauth_token=%@&venueId=%@&v=%@",token,venueID,version]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
            [request setHTTPMethod:@"POST"];
            [request setHTTPBody:[[NSString stringWithFormat:@"shout=%@",message] dataUsingEncoding:NSUTF8StringEncoding]];
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
                        if(code.integerValue==200)
                        {
                            if(photo)
                            {
                                [self addPhoto:photo withToken:token andVenueID:venueID];
                            }
                            return nil;
                        }
                    }
                }
            }
        }
    }
    else
    {
        
        NSInteger code = 100;
        NSString* errorDomain = @"woodlDomain";
        NSArray *objArray = [NSArray arrayWithObjects:@"post not completed", @"no venueses nearly", nil];
        NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
        NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
        return error;
    }

    NSInteger code = 101;
    NSString* errorDomain = @"woodlDomain";
    NSArray *objArray = [NSArray arrayWithObjects:@"post not completed", @"unknown error", nil];
    NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey,NSLocalizedFailureReasonErrorKey, nil];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
    NSError* error = [NSError errorWithDomain:errorDomain code:code userInfo:userInfo];
    return error;
}

-(BOOL)addPhoto:(UIImage*)photo withToken:(NSString*)token andVenueID:(NSString*)venueID
{
    NSData *imageData = UIImageJPEGRepresentation(photo,1.0);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.foursquare.com/v2/photos/add?oauth_token=%@&venueId=%@&v=%@",token,venueID,version]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"0xKhTmLbOuNdArY";
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary, nil];
	[request addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    NSData *stringData = [@"Content-Disposition: form-data;\
                          name=\"userfile\";\
                          filename=\"photo.jpg\"\r\n"
                          dataUsingEncoding:NSUTF8StringEncoding];
	[body appendData:stringData];
	[body appendData:[@"Content-Type: image/jpeg\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	[body appendData:imageData];
	[body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:body];
    
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
                if(code.integerValue==200)
                {
                    return YES;
                }
            }
        }
    }
    
    return NO;
}

-(NSString*)searchVenuesesWithToken:(NSString*)token andLatitude:(NSString*)lat longitude:(NSString*)lon
{
    NSString* latitude = lat;
    NSString* longitude = lon;
    if(lat.length>8)
    {
        latitude = [lat substringToIndex:8];
    }
    if(lon.length>8)
    {
        longitude = [lon substringToIndex:8];
    }
    
    NSString* ll = [NSString stringWithFormat:@"%@,%@",latitude,longitude];
    NSString* venueID = nil;
    if(![lat isEqualToString:@"0"]&&![lon isEqualToString:@"0"])
    {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.foursquare.com/v2/venues/search?oauth_token=%@&v=%@&ll=%@&radius=%i&limit=5",token,version,ll,kRadiusCheckin]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
        
        [request setHTTPMethod:@"GET"];
        //[request setHTTPBody:[[NSString stringWithFormat:@"ll=%@",ll] dataUsingEncoding:NSUTF8StringEncoding]];
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
                if([json objectForKey:@"response"])
                {
                    NSDictionary* response = [json objectForKey:@"response"];
                    NSArray* venues = [response objectForKey:@"venues"];
                    NSInteger minDistance = kRadiusCheckin;
                    for(NSDictionary* venue in venues)
                    {
                        NSDictionary* location = [venue objectForKey:@"location"];
                        NSNumber* distance = [location objectForKey:@"distance"];
                        if(distance.intValue<minDistance)
                        {
                            minDistance = distance.intValue;
                            venueID = [venue objectForKey:@"id"];
                        }
                    }
                }
            }
        }
    }
    return venueID;
}

-(NSArray*)getVenuePhotosWithObjectID:(NSString*)objectID andToken:(NSString*)token
{
    NSMutableArray* photos = [[NSMutableArray alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.foursquare.com/v2/venues/%@/photos?oauth_token=%@&v=%@&limit=5",objectID,token,version]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            if ([json objectForKey:@"response"])
            {
                NSDictionary* response = [json objectForKey:@"response"];
                if ([response objectForKey:@"photos"])
                {
                    NSDictionary* photosDict = [response objectForKey:@"photos"];
                    NSArray* items = [photosDict objectForKey:@"items"];
                    for(NSDictionary* photo in items)
                    {
                        NSString* prefix = [photo objectForKey:@"prefix"];
                        NSString* suffix = [photo objectForKey:@"suffix"];
                        NSString* photoURL = [NSString stringWithFormat:@"%@width1200%@",prefix,suffix];
                        [photos addObject:photoURL];
                    }
                }
            }
        }
    }
    return photos;
}

-(NSArray*)getCommentsFromCheckinID:(NSString*)checkinID andAccessToken:(NSString*)accessToken
{
    NSMutableArray* allComments = [[NSMutableArray alloc] init];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.foursquare.com/v2/checkins/recent?oauth_token=%@&v=%@",accessToken,version]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            NSDictionary* response = [json objectForKey:@"response"];
            NSArray* recent = [response objectForKey:@"recent"];
            for(NSDictionary* recentDict in recent)
            {
                NSString* postID = [recentDict objectForKey:@"id"];
                if([postID isEqualToString:checkinID])
                {
                    NSDictionary* commentsDict = [recentDict objectForKey:@"comments"];
                    if ([commentsDict objectForKey:@"items"])
                    {
                        NSArray* commentsArray = [commentsDict objectForKey:@"items"];
                        for(NSDictionary* comment in commentsArray)
                        {
                            NSMutableDictionary *commentResult = [[NSMutableDictionary alloc] init];
                            NSMutableDictionary *authorComment = [[NSMutableDictionary alloc] init];
                            NSString* commentID = [comment objectForKey:@"id"];
                            NSString* textComment = [comment objectForKey:@"text"];
                            NSString* commentData = [comment objectForKey:@"createdAt"];
                            NSDate* dateAddingComment = [NSDate dateWithTimeIntervalSince1970:[commentData longLongValue]];
                            [commentResult s_setObject:commentID forKey:kPostCommentIDDictKey];
                            [commentResult s_setObject:textComment forKey:kPostCommentTextDictKey];
                            [commentResult s_setObject:dateAddingComment forKey:kPostCommentDateDictKey];
                            NSDictionary* authorInfo = [comment objectForKey:@"user"];
                            NSString* authorID = [authorInfo objectForKey:@"id"];
                            NSString* firstName = @"";
                            NSString* lastName = @"";
                            if ([authorInfo objectForKey:@"firstName"])
                                firstName = [authorInfo objectForKey:@"firstName"];
                            if ([authorInfo objectForKey:@"lastName"])
                                lastName = [authorInfo objectForKey:@"lastName"];
                            NSString* name = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                            if ([authorInfo objectForKey:@"photo"])
                            {
                                NSDictionary* photoAuthorDic = [authorInfo objectForKey:@"photo"];
                                NSString* prefix = [photoAuthorDic objectForKey:@"prefix"];
                                NSString* suffix = [photoAuthorDic objectForKey:@"suffix"];
                                NSString* photoAuthorURL = [NSString stringWithFormat:@"%@64x64%@",prefix,suffix];
                                [authorComment s_setObject:photoAuthorURL forKey:kPostCommentAuthorAvaURLDictKey];
                            }
                            [authorComment s_setObject:authorID forKey:kPostCommentAuthorIDDictKey];
                            [authorComment s_setObject:name forKey:kPostCommentAuthorNameDictKey];
                            
                            [commentResult s_setObject:authorComment forKey:kPostCommentAuthorDictKey];
                            
                            [allComments addObject:commentResult];
                        }
                    }
                }
            }
        }
    }
    
    return allComments;
}

- (NSArray*)getFriendsWithToken:(NSString*)token
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat: @"https://api.foursquare.com/v2/users/self/friends?oauth_token=%@&v=%@",token,version]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kInternetIntervalTimeout];
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
            NSDictionary* response = [json objectForKey:@"response"];
            
            if(response)
            {
                NSDictionary* friends = [response objectForKey:@"friends"];
                if(friends)
                {
                    NSArray* items = [friends objectForKey:@"items"];
                    for(NSDictionary* item in items)
                    {
                        NSMutableDictionary* resultDictionary = [[NSMutableDictionary alloc] init];
                        [resultDictionary s_setObject:[item objectForKey:@"id"] forKey:kFriendID];
                        [resultDictionary s_setObject:[[self class] profileURLWithID:[item objectForKey:@"id"]] forKey:kFriendLink];
                        
                        NSString* firstName = [item objectForKey:@"firstName"];
                        NSString* lastName = [item objectForKey:@"lastName"];
                        
                        if(!firstName)
                            firstName = @"";
                        if(!lastName)
                            lastName = @"";
                        
                        NSString* name = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
                        [resultDictionary s_setObject:name forKey:kFriendName];
                        
                        NSDictionary* photo = [item objectForKey:@"photo"];
                        if(photo)
                        {
                            NSString* photoURL = [NSString stringWithFormat:@"%@300x300%@",[photo objectForKey:@"prefix"],[photo objectForKey:@"suffix"]];
                            [resultDictionary s_setObject:photoURL forKey:kFriendPicture];
                        }
                        [resultArray addObject:resultDictionary];
                    }
                }
            }
        }
    }
    
    return resultArray;
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
        profile = [[WDDDataBase sharedDatabase] addNewItemWithEntityName:NSStringFromClass([FoursquareOthersProfile class])];
        profile.userID = userId;
    }
    
    NSString *firstName = userInfo[@"firstName"];
    NSString *lastName = userInfo[@"lastName"];
    NSString *name = nil;
    if (firstName.length && lastName.length)
    {
        name = [[firstName stringByAppendingString:@" "] stringByAppendingString:lastName];
    }
    else if (firstName.length)
    {
        name = firstName;
    }
    else
    {
        name = lastName;
    }
    
    NSString* avatarURL = nil;
    if (userInfo[@"photo"])
    {
        avatarURL = [NSString stringWithFormat:@"%@64x64%@", userInfo[@"photo"][@"prefix"], userInfo[@"photo"][@"suffix"]];
    }
    
    profile.name = name;
    profile.avatarRemoteURL = avatarURL;
    profile.profileURL = [FoursquareRequest profileURLWithID:userId];
    
    return profile;
}

- (BOOL)updateLikesAndFavoritesForPostWithID:(NSString *)postId accessToken:(NSString *)accessToken
{
    if (!postId)
    {
        NSAssert(postId, @"postId can't be nil");
        return NO;
    }
    
    NSString *requestString = [NSString stringWithFormat:@"https://api.foursquare.com/v2/checkins/%@?oauth_token=%@&v=%@", postId, accessToken, version];
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
            NSArray* users = [json[@"response"][@"checkin"][@"likes"][@"groups"] firstObject][@"items"];
            id likesCount = json[@"response"][@"checkin"][@"likes"][@"count"];
            post.likesCount = @([likesCount integerValue]);

            for (NSDictionary *userInfo in users)
            {
                UserProfile *profile = [self userProfileWithDescription:userInfo];
                [profile addLikedPostsObject:post];
            }
            
            NSDictionary* commentsDict = json[@"response"][@"checkin"][@"comments"];
            if ([commentsDict objectForKey:@"items"])
            {
                NSArray* commentsArray = [commentsDict objectForKey:@"items"];
                
                NSFetchRequest *commentRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Comment class])];
                
                for(NSDictionary* commentInfo in commentsArray)
                {
                    NSString* commentID = [[commentInfo objectForKey:@"id"] stringValue];
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
                    
                    id commentTimestamp = commentInfo[@"createdAt"];
                    
                    comment.commentID = commentID;
                    comment.text = commentInfo[@"text"];
                    comment.date = [NSDate dateWithTimeIntervalSince1970:[commentTimestamp longLongValue]];

                    NSDictionary* authorInfo = commentInfo[@"user"];
                    comment.author = [self userProfileWithDescription:authorInfo];
                    [post addCommentsObject:comment];
                }
                
                post.commentsCount = @(commentsArray.count);
            }
            post.updateTime = [NSDate date];
            
            [[WDDDataBase sharedDatabase] save];
            return YES;
        }
    }
    
    return NO;
}

#pragma mark - Help methods
+ (NSString *)profileURLWithID:(NSString *)profileID
{
    return [[kFoursquareHTTPSBaseURLString stringByAppendingPathComponent:kFoursquareUserPathComponent] stringByAppendingPathComponent:profileID];
}

- (BOOL)getUsersWhosLikedPostWithID:(NSString *)postId accessToken:(NSString *)accessToken
{
    if (!postId)
    {
        NSAssert(postId, @"postId can't be nil");
        return NO;
    }
    
    NSString *requestString = [NSString stringWithFormat:@"https://api.foursquare.com/v2/checkins/%@/likes?oauth_token=%@&v=%@", postId, accessToken, version];
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
            NSArray* users = [json[@"response"][@"likes"][@"groups"] firstObject][@"items"];
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

#pragma mark - Static methods
#pragma mark 

+ (void)requestNearestPlacesInBackgroundForLatitude:(CLLocationDegrees)latitude
                                          longitude:(CLLocationDegrees)longitude
                                           accuracy:(CLLocationAccuracy)accuracy
                                             intent:(NSString*)intent
                                     withCompletion:(FoursquareRequestCompletionBlock)completion;
{
    [self requestNearestPlacesInBackgroundForLatitude:latitude longitude:longitude accuracy:accuracy intent:intent searchString:nil withCompletion:completion];
}

+ (void)requestNearestPlacesInBackgroundForLatitude:(CLLocationDegrees)latitude
                                          longitude:(CLLocationDegrees)longitude
                                           accuracy:(CLLocationAccuracy)accuracy
                                             intent:(NSString*)intent
                                       searchString:(NSString*)searchString
                                     withCompletion:(FoursquareRequestCompletionBlock)completion;
{
    FoursquareRequestCompletionBlock complBlk = [completion copy];
    
    void(^getPlacesBlock)() = ^{
        
        NSError *error;
        NSArray *result = [self getListOfNearestPlacesForLatitude:latitude
                                                        longitude:longitude
                                                         accuracy:(CLLocationAccuracy)accuracy
                                                           intent:(NSString*)intent
                                                     searchString:searchString
                                                            error:&error];
        
        if (complBlk)
        {
            complBlk(result, error);
        }
    };
    
    if ([[NSThread currentThread] isEqual:[NSThread mainThread]])
    {
        dispatch_queue_t getPlacesQueue = dispatch_queue_create("Get Foursquare places", NULL);
        dispatch_async(getPlacesQueue, getPlacesBlock);
    }
    else
    {
        getPlacesBlock();
    }
}

+ (NSArray *)getListOfNearestPlacesForLatitude:(CLLocationDegrees)latitude
                                     longitude:(CLLocationDegrees)longitude
                                      accuracy:(CLLocationAccuracy)accuracy
                                        intent:(NSString*)intent
                                  searchString:(NSString*)searchString
                                         error:(NSError **)error
{
    NSMutableArray *nearestPlaces;
    
    NSString *requsetURLString;
    NSString *baseString = @"https://api.foursquare.com/v2/venues/search?";
    NSString *ll = [NSString stringWithFormat:@"ll=%f,%f",latitude,longitude];
    requsetURLString = [baseString stringByAppendingString:ll];
    
    NSArray *socialNetworks = [[[WDDDataBase sharedDatabase] fetchSocialNetworksAscendingWithType:kSocialNetworkFoursquare] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"accessToken != nil"]];
    
    if (socialNetworks.count)
    {
        NSString *accessToken = [NSString stringWithFormat:@"&oauth_token=%@", [socialNetworks.firstObject accessToken]];
        requsetURLString = [requsetURLString stringByAppendingString:accessToken];
    }
    else
    {
        NSString *clientID = [NSString stringWithFormat:@"&client_id=%@", kFourSquareClientID];
        requsetURLString = [requsetURLString stringByAppendingString:clientID];
        
        NSString *clientSecret = [NSString stringWithFormat:@"&client_secret=%@", kFourSquareSecret];
        requsetURLString = [requsetURLString stringByAppendingString:clientSecret];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"YYYYmmdd";
    NSString *v = [NSString stringWithFormat:@"&v=%@", [dateFormatter stringFromDate:[NSDate date]]];
    requsetURLString = [requsetURLString stringByAppendingString:v];
    requsetURLString = [requsetURLString stringByAppendingFormat:@"&intent=%@", intent];
    requsetURLString = [requsetURLString stringByAppendingString:@"&limit=50"];
    requsetURLString = [requsetURLString stringByAppendingFormat:@"&radius=%d", (int)(3 * (accuracy > 0 ? accuracy : 50))];
    
    if (searchString) requsetURLString = [requsetURLString stringByAppendingFormat:@"&query=%@", searchString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[requsetURLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:kInternetIntervalTimeout];
    [request setHTTPMethod:@"GET"];
    NSURLResponse *response;
    
    DLog(@"request %@", request);
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request
                                         returningResponse:&response
                                                     error:error];
    if (data && !(*error))
    {
        NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data
                                                                     options:0
                                                                       error:error];
        NSArray *placesFromResponse = responseDict[@"response"][@"venues"];
        
        for (NSDictionary *placeDict in placesFromResponse)
        {
            if (!nearestPlaces)
            {
                nearestPlaces = [[NSMutableArray alloc] initWithCapacity:placesFromResponse.count];
            }
            
            WDDLocation *location = [[WDDLocation alloc] init];
            
            location.name = placeDict[@"name"];
            location.foursquareID = placeDict[@"id"];
            [location setLocationWithLatitude:[(NSNumber *)placeDict[@"location"][@"lat"] doubleValue]
                                    longitude:[(NSNumber *)placeDict[@"location"][@"lng"] doubleValue]];
            
            [nearestPlaces addObject:location];
        }
    }
    
    return [nearestPlaces sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                                      ascending:YES
                                                                                       selector:@selector(localizedCompare:)]]];
}

@end
