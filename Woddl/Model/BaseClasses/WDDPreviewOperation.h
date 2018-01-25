//
//  WDDPreviewOperation.h
//  Woddl
//
//  Created by Oleg Komaristov on 12/17/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SocialNetwork;

@protocol WDDPreviewOperationDelegate  <NSObject>

- (void)previewPreparedForLink:(NSURL *)previewURL preview:(UIImage *)preview;

@end

@interface WDDPreviewOperation : NSOperation
@property (assign, nonatomic, getter = isAuthorizationRequired) BOOL authorizationRequired;

- (id)initWithURL:(NSURL *)url delegate:(id <WDDPreviewOperationDelegate>)delegate socialNetwork:(SocialNetwork *)socialNetwork;

@end
