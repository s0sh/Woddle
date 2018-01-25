//
//  UIImageView+AvatarLoading.m
//  Woddl
//
//  Created by Oleg Komaristov on 26.02.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "UIImageView+AvatarLoading.h"
#import "AvatarManager+Internal.h"

@implementation UIImageView (AvatarLoading)

- (void)setAvatarWithURL:(NSURL *)avatarURL
{
    [self setAvatarWithURL:avatarURL completed:nil];
}

- (void)setAvatarWithURL:(NSURL *)avatarURL
               completed:(AvatarLoadedBlock)block
{
    UIImage *chachedImage = [[AvatarManager sharedManager] imageFromInMemoryCacheForURL:avatarURL];
    self.image = chachedImage ? : [AvatarManager sharedManager].placeholderImage;
    
    __weak UIImageView *w_self = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [[AvatarManager sharedManager] unregisterImageView:w_self];
        
        ImageCacheType cacheType = [[AvatarManager sharedManager] isImageCachedForURL:avatarURL];
        __block UIImage *image = nil;
        
        if (cacheType != ICTypeNone)
        {
            image = [[AvatarManager sharedManager] imageForURL:avatarURL];
            
            if (image)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    w_self.image = image;
                });
            }
        }
        
        if (cacheType != ICTypeMemory)
        {
            [[AvatarManager sharedManager] loadAvatarForURL:avatarURL
                                            complitionBlock:block];
            [[AvatarManager sharedManager] registerImageView:w_self forURL:avatarURL];
        }
        
        
    });
    
}

@end
