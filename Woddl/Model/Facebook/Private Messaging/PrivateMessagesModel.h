//
//  PrivateMessagesModel.h
//  Woddl
//
//  Created by Roman Tsymbalyuk on 1/16/13.
//
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"
//#import <XMPPFramework/XMPPRosterCoreDataStorage.h>
//#import <XMPPFramework/XMPPvCardCoreDataStorage.h>
//#import <XMPPFramework/XMPPCapabilitiesCoreDataStorage.h>

#import "XMPPClientDelegate.h"
#import "PrivateMessagesModelDelegate.h"

@class SocialNetwork;
@class XMPPClient;
@class PrivateMessagesStorage;


@interface PrivateMessagesModel : NSObject <XMPPRosterDelegate, XMPPClientDelegate, PrivateMessagesModelDelegate>

@property (nonatomic, retain) NSMutableArray *clients;

@property (nonatomic, retain) NSMutableDictionary *unreadOfflineMessages;
@property (nonatomic,retain) PrivateMessagesStorage *privateMessagesStorage;
@property (nonatomic) NSInteger countUnreadMessages;


+ (instancetype)sharedModel;

- (void)registerDelegate:(id<PrivateMessagesModelDelegate>)delegate;
- (void)unregisterDelegate:(id<PrivateMessagesModelDelegate>)delegate;

/*
 * get XMPPClient by XMPPStream bare value. Bare is user JID like <username@servername>
 */
- (XMPPClient *)clientByBare:(NSString *)bare;

- (BOOL)getOldMessagesForClient:(XMPPClient *)xmppClient andUser:(XMPPUserCoreDataStorageObject *)xmppUser;

- (NSInteger)getCountOfNewMessages;
- (void)removeXMPPClientForItem:(SocialNetwork *)anItem;

@end
