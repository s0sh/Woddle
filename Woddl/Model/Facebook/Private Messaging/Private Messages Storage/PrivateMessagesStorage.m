//
//  PrivateMessagesStorage.m
//  Woddl
//
//  Created by Roman Tsymbalyuk on 1/31/13.
//
//

#import "PrivateMessagesStorage.h"
#import "PrivateMessageObject.h"
#import "XMPPClient.h"

@interface PrivateMessagesStorage () {

}
@property (nonatomic,retain) NSMutableArray * array;

@end


@implementation PrivateMessagesStorage

@synthesize array=_array;
@synthesize delegate = _delegate;

- (id)init
{
    if (self = [super init])
    {
        _array = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    self.array = nil;
}

//////////////////////////////////////////////////////////////////////////////
#pragma mark - public methods
//////////////////////////////////////////////////////////////////////////////

- (NSArray *)getConversationBetween:(XMPPClient *)aClient jid:(XMPPJID *)aJid
{
    NSMutableArray * conversation = [[NSMutableArray alloc]init];
    for (PrivateMessageObject * messageObject in _array)
    {
        if ([messageObject.client.xmppStream isEqual:aClient.xmppStream] && [messageObject.jid isEqual:aJid])
        {
            [conversation addObject:messageObject];
        }
    }
    return conversation;
}

- (void)addMessageIntoTheStorage:(PrivateMessageObject *)message{
    
    [_array addObject:message];
    if ([_delegate respondsToSelector:@selector(gotMessage:)]){
        [_delegate gotMessage:message];
    }
}

- (void)addMessagesIntoTheStorage:(NSArray *)messages
{
    if ([messages count]!=0)
    {
        NSInteger c = 0;
        NSMutableIndexSet *iSet = [[NSMutableIndexSet alloc]init];
    
        for (PrivateMessageObject *message in _array)
        {
            if ([[[messages objectAtIndex:0] jid] isEqualToJID:message.jid])
            {
                [iSet addIndex:c];
                c++;
            }
        }
        [_array removeObjectsAtIndexes:iSet];
        [_array addObjectsFromArray:messages];
    
        if ([_delegate respondsToSelector:@selector(gotMessages:)]){
            [_delegate gotMessages:messages];
        }
    }
}

- (void)removeAllMessagesBetween:(XMPPClient *)aClient jid:(XMPPJID *)aJid
{
    NSMutableArray *messForDelete = [[NSMutableArray alloc]init];
    
    for (PrivateMessageObject *message in _array) {
        if (message.client == aClient && message.jid == aJid) {
            [messForDelete addObject:message];
        }
    }
    
    [_array removeObjectsInArray:messForDelete];
}

@end
