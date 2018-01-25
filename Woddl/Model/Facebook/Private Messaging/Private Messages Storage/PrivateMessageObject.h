//
//  PrivateMessageObject.h
//  Woddl
//
//  Created by Roman Tsymbalyuk on 1/31/13.
//
//

#import <Foundation/Foundation.h>


@class XMPPClient;
@class XMPPJID;

@interface PrivateMessageObject : NSObject 

@property (nonatomic,retain) XMPPClient *client;
@property (nonatomic,retain) XMPPJID *jid;
@property (nonatomic,retain) NSString *messageStr;
@property (nonatomic, getter = isIncoming) BOOL incoming;

- (id)initWithXMPPClien:(XMPPClient *)client from:(XMPPJID *) xmppjid messageText:(NSString *)messageStr incoming:(BOOL)incoming;
@end
