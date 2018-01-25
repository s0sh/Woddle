//
//  UIImageView+AvatarLoading.h
//  Woddl
//
//  Created by Oleg Komaristov on 26.02.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AvatarManagerTypes.h"

@interface UIImageView (AvatarLoading)

- (void)setAvatarWithURL:(NSURL *)avatarURL
               completed:(AvatarLoadedBlock)block;
- (void)setAvatarWithURL:(NSURL *)avatarURL;

@end
