//
//  WDDCookiesManager.m
//  Woddl
//
//  Created by Oleg Komaristov on 25.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDCookiesManager.h"

#import "WDDDataBase.h"

static NSString * const kCookiesListInfo = @"CookiesListKey";

@interface NSHTTPCookie (WDDCookiesManager) <NSCoding>

@end

@interface WDDCookiesManager ()

@property (nonatomic, strong) NSMutableDictionary *cookiesList;
@property (nonatomic, strong) NSString *activeCookie;

@end

@implementation WDDCookiesManager

+ (instancetype)sharedManager
{
    static WDDCookiesManager *cookiesManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cookiesManager = [WDDCookiesManager new];
    });
    
    return cookiesManager;
}

- (id)init
{
    if (self = [super init])
    {
        self.cookiesList = loadCookiesStorage();
        if (!self.cookiesList)
        {
            self.cookiesList = [NSMutableDictionary new];
        }
        self.activeCookie = nil;
        
        for (id cookie in  [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies)//[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@".facebook.com"]])
        {
            DLog(@"cookie info: %@", cookie);
        }
    }
    
    return self;
}

- (void)removeAllCookies
{
    NSMutableArray *cookies = [[NSMutableArray alloc] initWithCapacity:[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies.count];
    
    [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([[(NSHTTPCookie *)obj domain] rangeOfString:@"parse.com"].location == NSNotFound)
        {
            [cookies addObject:obj];
        }
    }];
    
    [cookies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:obj];
    }];
}

- (void)registerCookieForSocialNetwork:(SocialNetwork *)socialNetwork
{
    NSParameterAssert(socialNetwork.accessToken);
    
    NSString *socialNetworkDomain = domainForSocialNetworl(socialNetwork);
    if (!socialNetworkDomain)
    {
        NSException *unknownNetworkException = [[NSException alloc] initWithName:@"UnknownSocialNetwork"
                                                                          reason:@"Can't found domain for given social network"
                                                                        userInfo:nil];
        @throw unknownNetworkException;
    }
    
    __block BOOL found = NO;
    __block NSMutableArray *cookies = [NSMutableArray new];
    
    [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([[(NSHTTPCookie *)obj domain] rangeOfString:socialNetworkDomain].location != NSNotFound)
        {
            if ([(NSHTTPCookie *)obj expiresDate] &&
                abs([[(NSHTTPCookie *)obj expiresDate] timeIntervalSinceNow]) < 60*60*8)
            {
                return;
            }
            
            [cookies addObject:obj];
            found = YES;
        }
    }];
    
    if (found)
    {
        [self.cookiesList setObject:cookies forKey:keyForSocialNetwork(socialNetwork)];
        saveCookiesStorage(self.cookiesList);

        [cookies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:obj];
        }];
    }
    else
    {
        DLog(@"Can't found cookie for registration");
    }
}

- (BOOL)activateCookieForSocialNetwork:(SocialNetwork *)socialNetwork
{
    if (!socialNetwork.accessToken)
    {
        return NO;
    }
    
    // remove cookies for other accounts of same social network
    NSArray *socialNetworks = [[WDDDataBase sharedDatabase] fetchSocialNetworksAscendingWithType:socialNetwork.type.integerValue];
    [socialNetworks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if (![obj isEqual:socialNetwork])
        {
            NSArray *cookies = [self.cookiesList objectForKey:keyForSocialNetwork(obj)];
            [cookies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:obj];
            }];
        }
    }];
    
    __block BOOL isExpired = NO;
    NSArray *cookies = [self.cookiesList objectForKey:keyForSocialNetwork(socialNetwork)];
    [cookies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([[(NSHTTPCookie *)obj expiresDate] compare:[NSDate date]] == NSOrderedAscending)
        {
            isExpired = YES;
        }
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:obj];
    }];
    
    if (isExpired) // remove expired cookies and inform caller
    {
        [self.cookiesList removeObjectForKey:keyForSocialNetwork(socialNetwork)];
        saveCookiesStorage(self.cookiesList);
    }
    
    return (0 != cookies.count && !isExpired);
}

static NSString * keyForSocialNetwork(SocialNetwork *network)
{
    return [NSString stringWithFormat:@"%lu", (unsigned long)[network.accessToken hash]];
}

static NSString * domainForSocialNetworl(SocialNetwork *network)
{
    switch (network.type.integerValue)
    {
        case kSocialNetworkFacebook:
            return @"facebook.com";
        break;
            
        case kSocialNetworkTwitter:
            return @"twitter.com";
        break;
            
        case kSocialNetworkLinkedIN:
            return @"linkedin.com";
        break;
        
        case kSocialNetworkGooglePlus:
            return @"google.com";
        break;
            
        case kSocialNetworkInstagram:
            return @"instagram.com";
        break;
            
        case kSocialNetworkFoursquare:
            return @"foursquare.com";
        break;
    }
    
    return nil;
}

static void saveCookiesStorage(NSDictionary *storage)
{
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:storage];
    [[NSUserDefaults standardUserDefaults] setObject:data
                                              forKey:kCookiesListInfo];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

static NSMutableDictionary *loadCookiesStorage()
{
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:kCookiesListInfo];
    return [[NSKeyedUnarchiver unarchiveObjectWithData:data] mutableCopy];
}

@end

@implementation NSHTTPCookie (WDDCookiesManager)

-(id)initWithCoder:(NSCoder *)aDecoder
{
    NSDictionary* cookieProperties = [aDecoder decodeObjectForKey:@"cookieProperties"];
    if (![cookieProperties isKindOfClass:[NSDictionary class]]) {
        // cookies are always immutable, so there's no point to return anything here if its properties cannot be found.
        return nil;
    }
    self = [self initWithProperties:cookieProperties];
    return self;
}


-(void) encodeWithCoder:(NSCoder *)aCoder
{
    NSDictionary* cookieProperties = self.properties;
    if (cookieProperties) {
        [aCoder encodeObject:cookieProperties forKey:@"cookieProperties"];
    }
}

@end
