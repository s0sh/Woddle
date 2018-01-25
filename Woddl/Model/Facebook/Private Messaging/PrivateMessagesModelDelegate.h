//
//  PrivateMessagesModelDelegate.h
//  Woddl
//
//  Created by Roman Tsymbalyuk on 1/21/13.
//
//

#import <Foundation/Foundation.h>

@protocol PrivateMessagesModelDelegate <NSObject>

@optional

- (void)xmppClient:(XMPPClient *)client didReceiveNewMessage:(XMPPMessage *)aMessage;

- (void)xmppClientAdded:(XMPPClient *)client;
- (void)xmppClientWillBeRemoved:(XMPPClient *)client;


@end
