//
//  PrivateMessagesStorageProtocol.h
//  Woddl
//
//  Created by Roman Tsymbalyuk on 1/31/13.
//
//

#import <Foundation/Foundation.h>

@class XMPPStream;
@class PrivateMessageObject;

@protocol PrivateMessagesStorageProtocol <NSObject>

@optional

-(void) gotMessages:(NSArray *)messages;
-(void) gotMessage:(PrivateMessageObject *)message;


@end
