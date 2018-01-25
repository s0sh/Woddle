//
//  WDDPreviewManager.m
//  Woddl
//
//  Created by Oleg Komaristov on 12/16/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDPreviewManager.h"
#import "WDDPreviewOperation.h"
#import "SocialNetwork.h"

@interface WDDPreviewManager () <WDDPreviewOperationDelegate>

@property (nonatomic, strong) NSOperationQueue *previewOperations;
@property (nonatomic, strong) NSMutableDictionary *complitionBlocks;

@end

@implementation WDDPreviewManager

+ (instancetype)sharedManager
{
    static WDDPreviewManager *sharedManager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedManager = [WDDPreviewManager new];
    });
    
    return sharedManager;
}

- (id)init
{
    if (self = [super init])
    {
        self.previewOperations = [[NSOperationQueue alloc] init];
        self.previewOperations.maxConcurrentOperationCount = 1;
        self.complitionBlocks = [NSMutableDictionary new];
    }
    
    return self;
}

- (void)preparePreviewForURL:(NSURL *)url
            forSocialNetwork:(SocialNetwork *)socialNetwork
                      result:(LinkPreviewPrepared)resultBlock
{
    [self.complitionBlocks setObject:[resultBlock copy] forKey:url];
    WDDPreviewOperation *operation = [[WDDPreviewOperation alloc] initWithURL:url delegate:self socialNetwork:socialNetwork];
    operation.authorizationRequired = [self isAuthorizationRequiredForURL:url forSocialNetwork:socialNetwork];
    [self.previewOperations addOperation:operation];
}

- (BOOL)isAuthorizationRequiredForURL:(NSURL *)url forSocialNetwork:(SocialNetwork *)socialNetwork
{
    BOOL shourdAuthorizate = NO;
    if (socialNetwork.type.integerValue == kSocialNetworkFacebook)
    {
        if ([url.absoluteString hasPrefix:@"https://www.facebook.com"])
        {
            shourdAuthorizate = YES;
        }
    }
    return shourdAuthorizate;
}

#pragma mark - WDDPreviewOperationDelegate protocol implementatino

- (void)previewPreparedForLink:(NSURL *)previewURL preview:(UIImage *)preview
{
    LinkPreviewPrepared resultBlock = [self.complitionBlocks objectForKey:previewURL];
    if (resultBlock)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
                resultBlock(previewURL, preview);
        });
        [self.complitionBlocks removeObjectForKey:previewURL];
    }
}

@end
