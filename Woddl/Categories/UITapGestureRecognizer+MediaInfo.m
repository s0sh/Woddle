//
//  UITapGestureRecognizer+MediaInfo.m
//  Woddl
//
//  Created by Oleg Komaristov on 16.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "UITapGestureRecognizer+MediaInfo.h"
#import <objc/runtime.h>

static NSString * const kMediaURLKey = @"WoddlMediaURLKey";
const void *kMediaURL = &kMediaURLKey;

static NSString * const kMediaTypeKey = @"WoddlMediaURLKey";
const void *kType = &kMediaTypeKey;

static NSString * const kPreviewURLKey = @"WoddlPreviewURLKey";
const void *kPreviewURL = &kPreviewURLKey;

@implementation UITapGestureRecognizer (MediaInfo)

- (NSURL *)previewURL
{
    return objc_getAssociatedObject(self, kPreviewURL);
}

- (void)setPreviewURL:(NSURL *)previewURL
{
    objc_setAssociatedObject(self, kPreviewURL, previewURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSURL *)mediaURL
{
    return objc_getAssociatedObject(self, kMediaURL);
}

- (void)setMediaURL:(NSURL *)mediaURL
{
    objc_setAssociatedObject(self, kMediaURL, mediaURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)mediaType
{
    return objc_getAssociatedObject(self, kType);
}

- (void)setMediaType:(NSNumber *)mediaType
{
    objc_setAssociatedObject(self, kType, mediaType, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
