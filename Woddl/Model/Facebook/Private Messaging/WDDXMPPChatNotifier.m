//
//  WDDXMPPChatNotifier.m
//  Woddl
//
//  Created by Petro Korenev on 12/4/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDXMPPChatNotifier.h"
#import "PrivateMessagesModel.h"
#import "XMPPClient.h"
#import "XMPPUserCoreDataStorageObject.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPCoreDataStorageProtected.h"

@implementation WDDXMPPChatNotifier

XMPPJID *currentChat;
NSMutableDictionary *lastPresentedLocalNotifications;

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    [[self class] postLocalNotificationForStream:xmppStream message:message];
}

+ (void)load
{
    lastPresentedLocalNotifications = [[NSMutableDictionary alloc] init];
}

+ (void)postLocalNotificationForStream:(XMPPStream*)stream message:(XMPPMessage*)message
{
    if ([message isChatMessageWithBody] && ![message.from.bare isEqualToString:currentChat.bare])
    {
        NSDictionary *lastPresentedLocalNotificationsLocal = [lastPresentedLocalNotifications copy];
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self incrementUnreadCouterForUserWithMessage:message];
                       });
    
        if (lastPresentedLocalNotificationsLocal[message.from.bare]) return;
        
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        
        NSString *displayName = [[message elementForName:@"displayName"] stringValue];
        
        localNotification.alertBody = [NSString stringWithFormat:@"You have a new message%@", displayName ? [NSString stringWithFormat:@" from %@", displayName] : @""];
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        
        lastPresentedLocalNotifications[message.from.bare] = localNotification;
        
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_current_queue(), ^(void){
            [lastPresentedLocalNotifications removeObjectForKey:message.from.bare];
        });
    }
}

+ (void)incrementUnreadCouterForUserWithMessage:(XMPPMessage *)message
{
    XMPPClient *client = [[PrivateMessagesModel sharedModel] clientByBare:message.to.bare];
    if (!client)
    {
        return ;
    }
    
    XMPPRosterCoreDataStorage *storage = client.xmppRosterStorage;
    [storage executeBlock:^{
        NSFetchRequest *contactRequest = [[NSFetchRequest alloc] initWithEntityName:@"XMPPUserCoreDataStorageObject"];
        contactRequest.predicate = [NSPredicate predicateWithFormat:@"jidStr LIKE[cd] %@", message.fromStr];
        contactRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES]];
        
        NSError *error;
        NSArray *clients = [client.managedObjectContext_roster executeFetchRequest:contactRequest error:&error];
        if (!error)
        {
            for (XMPPUserCoreDataStorageObject *user in clients)
            {
                NSInteger unreadMessagesCount = [user.unreadMessages integerValue];
                unreadMessagesCount++;
                user.unreadMessages = [NSNumber numberWithInteger:unreadMessagesCount];
            }
            NSError *error;
            [client.managedObjectContext_roster save:&error];
            if (error)
            {
#ifdef DEBUG
                DLog(@"Error: %@", [error localizedDescription]);
#endif
            }
        }
    }];
}

+ (void)setCurrentChat:(XMPPJID *)chat
{
    currentChat = chat;
}

@end
