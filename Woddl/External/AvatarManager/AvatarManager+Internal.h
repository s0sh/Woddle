//
//  AvatarManager+Internal.h
//  Woddl
//
//  Created by Oleg Komaristov on 26.02.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "AvatarManager.h"

@class AvatarLoadOperation;

@interface AvatarManager (Internal)

@property (nonatomic, strong) NSMutableDictionary *imagesCache;
@property (nonatomic, strong) NSMutableDictionary *operations;
@property (nonatomic, strong) NSMutableDictionary *imageViews;

- (void)registerImage:(UIImage *)image forURL:(NSURL *)url;
- (void)loadingOperationFinished:(AvatarLoadOperation *)operation;

- (UIImageView *)imageViewAssociatedWithURL:(NSURL *)url;

- (void)registerImageView:(UIImageView *)imageView forURL:(NSURL *)url;
- (void)unregisterImageView:(UIImageView *)imageView;

- (NSString *)pathForURL:(NSURL *)url;

@end
