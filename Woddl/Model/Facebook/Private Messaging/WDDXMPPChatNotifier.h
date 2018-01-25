//
//  WDDXMPPChatNotifier.h
//  Woddl
//
//  Created by Petro Korenev on 12/4/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "XMPPFramework.h"
//#import <XMPPFramework/XMPPFramework.h>
#import "XMPPModule.h"

@interface WDDXMPPChatNotifier : XMPPModule <XMPPStreamDelegate>

+ (void)setCurrentChat:(XMPPJID*)chat;

@end
