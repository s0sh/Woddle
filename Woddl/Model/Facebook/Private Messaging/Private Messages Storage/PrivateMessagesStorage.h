//
//  PrivateMessagesStorage.h
//  Woddl
//
//  Created by Roman Tsymbalyuk on 1/31/13.
//
//

#import <Foundation/Foundation.h>
#import "PrivateMessagesStorageProtocol.h"

@class XMPPClient;
@class XMPPJID;
@class PrivateMessageObject;

@interface PrivateMessagesStorage : NSObject <PrivateMessagesStorageProtocol> {
    id <PrivateMessagesStorageProtocol> delegate;
}

@property (nonatomic,retain) id <PrivateMessagesStorageProtocol> delegate;

//get common conversation between users;
- (NSArray *)getConversationBetween:(XMPPClient *)aClient jid:(XMPPJID *)aJid;

//use it for adding each new incomming message into the store
- (void)addMessageIntoTheStorage:(PrivateMessageObject *)message;
- (void)addMessagesIntoTheStorage:(NSArray *)messages;
- (void)removeAllMessagesBetween:(XMPPClient *) aClient jid:(XMPPJID *) aJid;

@end
