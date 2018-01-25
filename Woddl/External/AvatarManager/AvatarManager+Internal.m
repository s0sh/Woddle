//
//  AvatarManager+Internal.m
//  Woddl
//
//  Created by Oleg Komaristov on 26.02.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "AvatarManager+Internal.h"
#import "AvatarManagerConsts.h"

#import "AvatarLoadOperation.h"
#import "WDDWeakObject.h"

@implementation AvatarManager (Internal)

- (void)registerImage:(UIImage *)image forURL:(NSURL *)url
{
    [UIImageJPEGRepresentation(image, 0.8) writeToFile:[self pathForURL:url] atomically:YES];
    
    @synchronized(self.imagesCache)
    {
        [self.imagesCache setObject:image forKey:@(url.hash)];
    }
}

- (void)loadingOperationFinished:(AvatarLoadOperation *)operation
{
    @synchronized(self.operations)
    {
        [self.operations removeObjectForKey:@(operation.avatarURL.hash)];
    }
}

- (UIImageView *)imageViewAssociatedWithURL:(NSURL *)url
{
    return [(WDDWeakObject *)self.imageViews[@(url.hash)] object];
}

- (void)registerImageView:(UIImageView *)imageView forURL:(NSURL *)url
{
    @synchronized(self.imageViews)
    {
        @synchronized(self.imageViews)
        {
            [self.imageViews setObject:[WDDWeakObject weekObjectWithObject:imageView]
                                forKey:@(url.hash)];
        }
        ((AvatarLoadOperation *)self.operations[@(url.hash)]).queuePriority += 1;
    }
}

- (void)unregisterImageView:(UIImageView *)imageView
{
    @synchronized(self.imageViews)
    {
        __block id keyToRemove = nil;
        
        [self.imageViews enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            
            if ([[obj object] isEqual:imageView])
            {
                keyToRemove = key;
                *stop = YES;
            }
        }];
        
        if (keyToRemove)
        {
            @synchronized(self.imageViews)
            {
                [self.imageViews removeObjectForKey:keyToRemove];
            }
            
            if (((AvatarLoadOperation *)self.operations[@([keyToRemove hash])]).queuePriority > 0)
            {
                ((AvatarLoadOperation *)self.operations[@([keyToRemove hash])]).queuePriority -= 1;
            }
        }
    }
}

#pragma mark - Utility methods

- (NSString *)pathForURL:(NSURL *)url
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    NSString *folderPath = [cacheDirectory stringByAppendingPathComponent:PathToImagesCache];
    
    BOOL isDirectory = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:PathToImagesCache isDirectory:&isDirectory] || !isDirectory)
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    
    return [folderPath stringByAppendingPathComponent:[@(url.hash).stringValue stringByAppendingPathExtension:@"jpeg"]];
}

#pragma mark - Getters/settets methods

- (void)setImagesCache:(NSMutableDictionary *)imagesCache
{
    [self setValue:imagesCache forKey:@"_imagesCache"];
}

- (NSMutableDictionary *)imagesCache
{
    return [self valueForKey:@"_imagesCache"];
}

- (void)setOperations:(NSMutableDictionary *)operations
{
    [self setValue:operations forKey:@"_operations"];
}

- (NSMutableDictionary *)operations
{
    return [self valueForKey:@"_operations"];
}

- (void)setImageViews:(NSMutableDictionary *)imageViews
{
    [self setValue:imageViews forKey:@"_imageViews"];
}

- (NSMutableDictionary *)imageViews
{
    return [self valueForKey:@"_imageViews"];
}

@end

