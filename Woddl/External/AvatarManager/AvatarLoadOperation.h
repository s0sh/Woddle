//
//  AvatarLoadOperation.h
//  Woddl
//
//  Created by Oleg Komaristov on 26.02.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AvatarManagerTypes.h"

@interface AvatarLoadOperation : NSOperation

@property (nonatomic, readonly) NSURL *avatarURL;
@property (nonatomic, readonly) UIImageView *imageView;

+ (instancetype)operationWithURL:(NSURL *)avatarURL;
+ (instancetype)operationWithURL:(NSURL *)avatarURL complitionBlock:(AvatarLoadedBlock)loadedBlock;

@end
