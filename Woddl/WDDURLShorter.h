//
//  WDDURLShorter.h
//  Woddl
//
//  Created by Oleg Komaristov on 2/18/14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ComplitionBlock)(void);

@interface WDDURLShorter : NSObject

+ (instancetype)defaultShorter;

- (void)registerAllURLsPorocessedBlock:(ComplitionBlock)completeBlock;
- (void)unregisterAllURLsProcessedBlock;

- (NSURL *)cachedLinkForURL:(NSURL *)sourceURL;
- (void)getLinkForURL:(NSURL *)sourceURL withCallback:(void(^)(NSURL *resultURL))callback;

- (NSURL *)fullLinkForURL:(NSURL *)shortURL;

@end
