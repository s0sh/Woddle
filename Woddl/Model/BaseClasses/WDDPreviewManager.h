//
//  WDDPreviewManager.h
//  Woddl
//
//  Created by Oleg Komaristov on 12/16/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SocialNetwork;

typedef void (^LinkPreviewPrepared)(NSURL *linkURL, UIImage *preview);

@interface WDDPreviewManager : NSObject

+ (instancetype)sharedManager;

- (void)preparePreviewForURL:(NSURL *)url
            forSocialNetwork:(SocialNetwork *)socialNetwork
                      result:(LinkPreviewPrepared)resultBlock;

@end
