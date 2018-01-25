//
//  XMPPClientDelegate.h
//  Woddl
//
//  Created by Roman Tsymbalyuk on 1/21/13.
//
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"

@class XMPPClient;
@class XMPPMessage;

@protocol XMPPClientDelegate <NSObject>

-(void)xmppClient:(XMPPClient *)client goInOfflineSuccessful:(BOOL)s;

-(void)xmppClient:(XMPPClient *)client userGoInOnlineSuccessful:(BOOL)s;

-(void)xmppClient:(XMPPClient *)client getPreviousMessages:(NSArray *)messages;

-(void)xmppClient:(XMPPClient *)client sendMessageSuccessful:(BOOL)s;

-(void)xmppClient:(XMPPClient *)client didReceiveNewMessage:(XMPPMessage *)aMessage;

@end
