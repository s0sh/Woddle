//
//  AvatarManager.h
//  Woddl
//
//  Created by Oleg Komaristov on 26.02.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "AvatarManagerTypes.h"

typedef enum tagImageCacheType
{
    ICTypeNone,
    ICTypeMemory,
    ICTypeSSD
    
} ImageCacheType;

@interface AvatarManager : NSObject

@property (nonatomic, assign) CGFloat sideSize;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, strong) UIImage *placeholderImage;

+ (instancetype)sharedManager;

- (ImageCacheType)isImageCachedForURL:(NSURL *)url;
- (UIImage *)imageForURL:(NSURL *)url;
- (UIImage *)imageFromInMemoryCacheForURL:(NSURL *)url;

- (void)loadAvatarForURL:(NSURL *)avatarURL complitionBlock:(AvatarLoadedBlock)loadedBlock;

@end