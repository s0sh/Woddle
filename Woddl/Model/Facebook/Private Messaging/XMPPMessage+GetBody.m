//
//  XMPPMessage+GetBody.m
//  Woddl
//
//  Created by Roman Tsymbalyuk on 1/31/13.
//
//

#import "XMPPMessage+GetBody.h"
#import "NSXMLElement+XMPP.h"


@implementation XMPPMessage (GetBody)

-(NSString *) getBodyStr{
    return [[self elementForName:@"body"] stringValue];
}

@end
