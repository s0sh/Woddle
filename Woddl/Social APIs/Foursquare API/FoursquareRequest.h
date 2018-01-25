//
//  FoursquareRequest.h
//  Woddl
//
//  Created by Александр Бородулин on 07.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkRequest.h"
#import "WDDLocation.h"

typedef void(^FoursquareRequestCompletionBlock)(id results, NSError *error);

@interface FoursquareRequest : NetworkRequest
-(NSArray*)getPostsWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count;
-(BOOL)isPostLikedMe:(NSString*)postID withToken:(NSString*)token andMyID:(NSString*)myID;
-(BOOL)setLikeOnObjectID:(NSString*)objectID withToken:(NSString*)token;
-(BOOL)setUnlikeOnObjectID:(NSString*)objectID withToken:(NSString*)token;
-(NSDictionary*)addCommentOnObjectID:(NSString*)objectID withToken:(NSString*)token andMessage:(NSString*)message;
-(NSError*)addStatusWithToken:(NSString*)token andMessage:(NSString*)message location:(WDDLocation *)location andImage:(UIImage*)photo;
-(NSArray*)getCommentsFromCheckinID:(NSString*)checkinID andAccessToken:(NSString*)accessToken;

-(NSArray*)getFriendsWithToken:(NSString*)token;

+ (void)requestNearestPlacesInBackgroundForLatitude:(CLLocationDegrees)latitude
                                          longitude:(CLLocationDegrees)longitude
                                           accuracy:(CLLocationAccuracy)accuracy
                                             intent:(NSString*)intent
                                     withCompletion:(FoursquareRequestCompletionBlock)completion;

+ (void)requestNearestPlacesInBackgroundForLatitude:(CLLocationDegrees)latitude
                                          longitude:(CLLocationDegrees)longitude
                                           accuracy:(CLLocationAccuracy)accuracy
                                             intent:(NSString*)intent
                                       searchString:(NSString*)searchString
                                     withCompletion:(FoursquareRequestCompletionBlock)completion;


+ (NSString *)profileURLWithID:(NSString *)profileID;

@end
