//
//  PrivateMessageObject.m
//  Woddl
//
//  Created by Roman Tsymbalyuk on 1/31/13.
//
//

#import "PrivateMessageObject.h"

@implementation PrivateMessageObject

@synthesize client =_client;
@synthesize jid = _jid;
@synthesize messageStr = _messageStr;
@synthesize incoming = _incoming;


- (id)initWithXMPPClien:(XMPPClient *)client from:(XMPPJID *) xmppjid messageText:(NSString *)messageStr incoming:(BOOL)incoming{
    self = [super init];
    if (self){
        self.client = client;
        self.jid = xmppjid;
        self.messageStr = messageStr;
        self.incoming = incoming;
    }
    return self;
}

@end
