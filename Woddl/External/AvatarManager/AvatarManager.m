//
//  AvatarManager.m
//  Woddl
//
//  Created by Oleg Komaristov on 26.02.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "AvatarManager.h"
#import "AvatarManager+Internal.h"
#import "AvatarLoadOperation.h"

#import "UIImage+ResizeAdditions.h"
#import "WDDWeakObject.h"

#import <uidevice-extension/UIDevice-Hardware.h>

@interface AvatarManager () {

    NSMutableDictionary *_imagesCache;
    NSMutableDictionary *_operations;
    NSMutableDictionary *_imageViews;
}

@property (nonatomic, strong) NSOperationQueue *operationsQueue;

@end

@implementation AvatarManager

+ (instancetype)sharedManager
{
	static AvatarManager *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instance = [self new];
    });
    
    return instance;
}

- (instancetype)init
{
    if (self = [super init])
    {
        self.operationsQueue = [NSOperationQueue new];
        self.operationsQueue.maxConcurrentOperationCount = (([UIDevice currentDevice].cpuCount - 1) ? [UIDevice currentDevice].cpuCount - 1 : 1);
        
        self.operations = [NSMutableDictionary new];
        self.imagesCache = [NSMutableDictionary new];
        self.imageViews = [NSMutableDictionary new];
        
        self.placeholderImage = nil;
        self.sideSize = 32.f;
        self.cornerRadius = 4.f;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processLowMemoryNotification:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setPlaceholderImage:(UIImage *)placeholderImage
{
    _placeholderImage = [placeholderImage thumbnailImage:self.sideSize * [UIScreen mainScreen].scale
                                       transparentBorder:1.0f
                                            cornerRadius:self.cornerRadius
                                    interpolationQuality:kCGInterpolationDefault];
}

- (ImageCacheType)isImageCachedForURL:(NSURL *)url
{
    if (self.imagesCache[@(url.hash)])
    {
        return ICTypeMemory;
    }
    else if ([[NSFileManager defaultManager] fileExistsAtPath:[self pathForURL:url]])
    {
        return ICTypeSSD;
    }
    
    return ICTypeNone;
}

- (UIImage *)imageForURL:(NSURL *)url
{
    UIImage *image = self.imagesCache[@(url.hash)];
    if (!image)
    {
        image = [UIImage imageWithContentsOfFile:[self pathForURL:url]];
        if (image)
        {
            @synchronized(self.imagesCache)
            {
                [self.imagesCache setObject:image forKey:@(url.hash)];
            }
        }
    }
    
    return image;
}

- (UIImage *)imageFromInMemoryCacheForURL:(NSURL *)url
{
    return self.imagesCache[@(url.hash)];
}

- (void)loadAvatarForURL:(NSURL *)avatarURL complitionBlock:(AvatarLoadedBlock)loadedBlock
{
    @synchronized(self.operations)
    {
        if (!self.operations[@(avatarURL.hash)])
        {
            AvatarLoadOperation *operation = [AvatarLoadOperation operationWithURL:avatarURL
                                                                   complitionBlock:loadedBlock];
            if (operation)
            {
                [self.operationsQueue addOperation:operation];
                [self.operations setObject:operation forKey:@(avatarURL.hash)];
            }
        }
    }
}

#pragma mark - Memory management

- (void)processLowMemoryNotification:(NSNotification *)notification
{
    DLog(@"!!!-------------- MEMORY WARNING ------------!!!");
    DLog(@"--------------- Stats before clean: ---------------");
    DLog(@"Operatoins : %lu", (unsigned long)self.operations.count);
    DLog(@"Operatoins in queue : %lu", (unsigned long)self.operationsQueue.operationCount);
    DLog(@"Images in memory cache : %lu", (unsigned long)self.imagesCache.count);
    DLog(@"Image views wayting for load : %lu", (unsigned long)self.imageViews.count);
    
    @synchronized(self.imagesCache)
    {
        [self.imagesCache removeAllObjects];
        
        __block NSMutableDictionary *urls = [[NSMutableDictionary alloc] initWithCapacity:self.imageViews.count];
        @synchronized(self.operations)
        {
            NSMutableDictionary *operations = [[NSMutableDictionary alloc] initWithCapacity:self.operations.count];
            
            [self.operations enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                

                if ([(AvatarLoadOperation *)obj avatarURL])
                {
                    [urls setObject:[(AvatarLoadOperation *)obj avatarURL]
                             forKey:key];
                    
                    if ([(NSOperation *)obj isExecuting])
                    {
                        [operations setObject:obj forKey:key];
                    }
                }
            }];
            
            self.operations = operations;
        }
        @synchronized(self.imageViews)
        {
            NSMutableDictionary *imageViews = [[NSMutableDictionary alloc] initWithCapacity:self.imageViews.count];
            
            [self.imageViews enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                
                if([(WDDWeakObject *)obj object] && [[(WDDWeakObject *)obj object] superview])
                {
                    [imageViews setObject:obj forKey:key];
                }
            }];
            
            self.imageViews = imageViews;
        }
        
        [self.operationsQueue cancelAllOperations];
        
        [self.imageViews enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            NSURL *url = urls[key];
            if (url)
            {
                AvatarLoadOperation *operation = [AvatarLoadOperation operationWithURL:url];
                if (operation)
                {
                    [self.operations setObject:operation forKey:key];
                }
            }
        }];
        
        DLog(@"--------------- Stats after clean: ---------------");
        DLog(@"Operatoins : %lu", self.operations.count);
        DLog(@"Operatoins in queue : %lu", self.operationsQueue.operationCount);
        DLog(@"Images in memory cache : %lu", self.imagesCache.count);
        DLog(@"Image views wayting for load : %lu", self.imageViews.count);
    }
}

@end