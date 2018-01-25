//
//  FacebookFetchInboxOperation.h
//  Woddl
//
//  Created by Petro Korenev on 12/2/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMPPClient;

@interface FacebookFetchInboxOperation : NSOperation

@property (nonatomic, strong) NSString      *token;
@property (nonatomic, strong) XMPPClient    *client;

- (id)initFacebookFetchInboxOperationWithToken:(NSString*)token client:(XMPPClient*)client;

@end