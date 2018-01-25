//
//  FacebookUserInfo.m
//  Woddl
//
//  Created by Александр Бородулин on 16.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookGroupsInfo.h"
#import "NetworkRequest.h"
#import "Group.h"


#import "WDDDataBase.h"
#import "SocialNetwork.h"

@implementation FacebookGroupsInfo

-(NSArray*)getAllGroupsWithUserID:(NSString*)userID andToken:(NSString*)token
{
    NSMutableArray* allGroups = [[NSMutableArray alloc] init];
    
    [allGroups addObjectsFromArray:[self getUserGroupsWithID:userID andToken:token justAdmin:NO]];
    [allGroups addObjectsFromArray:[self getUserPagesWithID:userID andToken:token justAdmin:NO]];
    
    return allGroups;
}

- (NSArray *)getOwnAndAdmistrativeGroupsForUserID:(NSString *)userId token:(NSString *)token
{
    NSMutableArray* allGroups = [[NSMutableArray alloc] init];
    
    [allGroups addObjectsFromArray:[self getUserGroupsWithID:userId andToken:token justAdmin:YES]];
    [allGroups addObjectsFromArray:[self getUserPagesWithID:userId andToken:token justAdmin:YES]];
    
    return allGroups;
}

- (NSArray *)getUserPagesWithID:(NSString *)userID andToken:(NSString*)token justAdmin:(BOOL)justAdmin
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    NSString *requestString = nil;
    
    if (justAdmin)
    {
        requestString = [[NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT page_id FROM page_admin WHERE uid = me()&access_token=%@", token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    else
    {
        requestString = [[NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT page_id FROM page_fan WHERE uid = me()&access_token=%@", token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
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
            
            NSMutableSet *fanPages = [NSMutableSet new];
            if (![json[@"data"] isKindOfClass:[NSArray class]])
            {
                return nil;
            }
            
            for (NSDictionary *page in json[@"data"])
            {
                [fanPages addObject:page[@"page_id"]];
            }
            
            NSMutableSet *managedPages = nil;
            
            if (!justAdmin)
            {
                requestString = [[NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT page_id FROM page_admin WHERE uid = me()&access_token=%@", token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
                
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
                        
                        if ([json[@"data"] isKindOfClass:[NSArray class]])
                        {
                            managedPages = [NSMutableSet new];
                            for (NSDictionary *page in json[@"data"])
                            {
                                [managedPages addObject:page[@"page_id"]];
                                if (![fanPages containsObject:page[@"page_id"]])
                                {
                                    [fanPages addObject:page[@"page_id"]];
                                }
                            }
                        }
                    }
                }
            }
            
            for(id pageId in fanPages)
            {
                BOOL isAdmin = ( justAdmin ? : [managedPages containsObject:pageId] );
                NSMutableDictionary* groupResultDict = [[self getPageInfoWithID:pageId andToken:token] mutableCopy];
                [groupResultDict setObject:@(isAdmin) forKey:kGroupIsManagedByMeKey];
                if(groupResultDict)
                {
                    [resultArray addObject:groupResultDict];
                }
            }
        }
    }
    return resultArray;
}

- (NSArray *)getUserGroupsWithID:(NSString *) userID andToken:(NSString *)token justAdmin:(BOOL)justAdmin
{
    NSMutableArray* resultArray = [[NSMutableArray alloc] init];
    NSString *requestString = nil;
    
    if (justAdmin)
    {
        requestString = [[NSString stringWithFormat: @"https://graph.facebook.com/fql?q=SELECT gid FROM group_member WHERE uid = me() AND administrator = 1&access_token=%@", token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    else
    {
        requestString = [[NSString stringWithFormat: @"https://graph.facebook.com/fql?q=SELECT gid, administrator FROM group_member WHERE uid = me()&access_token=%@", token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
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
            
            NSArray* groups = [json objectForKey:@"data"];
            for(NSDictionary* group in groups)
            {
                NSMutableDictionary* groupResultDict = [[self getGroupInfoWithID:[group objectForKey:@"gid"] andToken:token] mutableCopy];
                [groupResultDict setObject:(justAdmin ? @YES : @([group[@"administrator"] integerValue]))
                                    forKey:kGroupIsManagedByMeKey];
                if(groupResultDict)
                {
                    [resultArray addObject:groupResultDict];
                }
            }
        }
    }
    return resultArray;
}

- (NSDictionary *)getPageInfoWithID:(NSString *)groupID andToken:(NSString *)token
{
    NSString *requestString = [[NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT page_id,name,page_url,pic,pic_big,pic_cover FROM page WHERE page_id = %@&access_token=%@", groupID, token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
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
            else
            {
                return [[self parsePages:json[@"data"]] firstObject];
            }
        }
    }
    
    return nil;
}

- (NSDictionary *)getGroupInfoWithID:(NSString *)groupID andToken:(NSString *)token
{
    NSString *requestString = [[NSString stringWithFormat:@"https://graph.facebook.com/fql?q=SELECT+description,icon68,gid,name,pic,pic_big,pic_cover,website+FROM+group+WHERE+gid='%@'&access_token=%@",groupID,token] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
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
            else
            {
                return [[self parseGroups:json[@"data"]] firstObject];
            }
        }
    }
    
    return nil;
}

- (void)invalidateSocialNetworkWithToken:(NSString *)accessToken
{
    SocialNetwork *network = [[WDDDataBase sharedDatabase] fetchObjectsWithEntityName:NSStringFromClass([SocialNetwork class])
                                                                        withPredicate:[NSPredicate predicateWithFormat:@"accessToken == %@ AND type == %d", accessToken, kSocialNetworkFacebook]
                                                                      sortDescriptors:nil].firstObject;
    network.accessToken = nil;
    network.activeState = @NO;
    [[WDDDataBase sharedDatabase] save];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[WDDDataBase sharedDatabase] save];
    });
}

- (NSArray*)parseGroups:(NSArray*)resultSet
{
    NSMutableArray *resultArray = [NSMutableArray new];
    
    for(NSDictionary* group in resultSet)
    {
        NSMutableDictionary *resultDictionary = [NSMutableDictionary new];
        [resultDictionary s_setObject:group[@"pic_big"] forKey:kGroupImageURLKey];
        NSString *stringGid = group[@"gid"];
        if ([group[@"gid"] isKindOfClass:[NSNumber class]])
        {
            stringGid = [(NSNumber*)stringGid stringValue];
        }
        NSString* site = [NSString stringWithFormat:@"www.facebook.com/groups/%@", stringGid];
        [resultDictionary s_setObject:site forKey:kGroupURLKey];
        [resultDictionary s_setObject:[group objectForKey:@"name"] forKey:kGroupNameKey];
        [resultDictionary s_setObject:stringGid forKey:kGroupIDKey];
        [resultDictionary s_setObject:[NSNumber numberWithInt:kGroupTypeGroup] forKey:kGroupTypeKey];
        
        [resultArray addObject:resultDictionary];
    }
    
    return resultArray;
}

- (NSArray*)parsePages:(NSArray*)resultSet
{
    NSMutableArray *resultArray = [NSMutableArray new];
    
    for(NSDictionary* page in resultSet)
    {
        NSMutableDictionary *resultDictionary = [NSMutableDictionary new];
        
        NSString *stringGid = page[@"page_id"];
        if ([page[@"page_id"] isKindOfClass:[NSNumber class]])
        {
            stringGid = [(NSNumber*)stringGid stringValue];
        }
        
        [resultDictionary s_setObject:stringGid forKey:kGroupIDKey];
        [resultDictionary s_setObject:[page objectForKey:@"name"] forKey:kGroupNameKey];
        [resultDictionary s_setObject:[page objectForKey:@"page_url"] forKey:kGroupURLKey];
        [resultDictionary s_setObject:[NSNumber numberWithInt:kGroupTypePage] forKey:kGroupTypeKey];
        
        [resultDictionary s_setObject:page[@"pic_big"] forKey:kGroupImageURLKey];
        
        [resultArray addObject:resultDictionary];
    }
    
    return resultArray;
}

@end
