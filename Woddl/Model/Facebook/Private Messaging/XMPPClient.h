//
//  XMPPClient.h
//  Woddl
//
//  Created by Roman Tsymbalyuk on 1/17/13.
//
//

#import <Foundation/Foundation.h>
#import "XMPPFramework.h"

//#import <XMPPFramework/XMPPRosterCoreDataStorage.h>
//#import <XMPPFramework/XMPPvCardCoreDataStorage.h>
//#import <XMPPFramework/XMPPCapabilitiesCoreDataStorage.h>
//#import <XMPPFramework/XMPPReconnect.h>
//#import <XMPPFramework/XMPPMessageArchivingCoreDataStorage.h>

@class SocialNetwork;
@class XMPPvCardStorage;
@class XMPPRosterCoreDataStorage;

@interface XMPPClient : NSObject <XMPPStreamDelegate>

@property (nonatomic, strong) SocialNetwork *socialNetworkItem;

@property (nonatomic, strong) XMPPStream *xmppStream;
@property (nonatomic, strong) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong) XMPPRoster *xmppRoster;

@property (nonatomic, strong) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong) XMPPvCardCoreDataStorage *xmppvCardStorage;
@property (nonatomic, strong) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
@property (nonatomic, strong) XMPPMessageArchivingCoreDataStorage *xmppMessageArchivingStorage;
@property (nonatomic, strong) XMPPMessageArchiving *xmppMessageArchiving;

@property (nonatomic) BOOL allowSelfSignedCertificates;
@property (nonatomic) BOOL allowSSLHostNameMismatch;

@property (nonatomic) BOOL isXmppConnected;

@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext_roster;

@property (nonatomic, getter = isConnected) BOOL connected;

- (id)initWithSocialNetwork:(SocialNetwork *)socialNetwork;

- (void)sendMessage:(NSString*)message
              toJid:(XMPPJID*)jid;
- (void)fetchInbox;

- (BOOL)connect;

- (void)disconnect;

- (void)goOnline;

- (void)goOffline;

//TODO: get previous messages for conversation. Need option like a conversation id or something that can identifing conversation.
- (NSArray *) getPreviousMessages; //

@end
