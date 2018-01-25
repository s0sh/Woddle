//
//  XMPPClient.m
//  Woddl
//
//  Created by Roman Tsymbalyuk on 1/17/13.
//
//

#import "XMPPClient.h"
#import "SocialNetwork.h"
#import "FacebookSN.h"
#import "FacebookFetchInboxOperation.h"


#import "WDDXMPPChatNotifier.h"

#import "XMPPMessageDeliveryReceipts.h"

@interface XMPPClient ()

@property (nonatomic, readonly) NSString *XMPPRosterDBName;
@property (nonatomic, readonly) NSString *XMPPvCardDBName;
@property (nonatomic, readonly) NSString *XMPPMessageArchiveDBName;

@property (nonatomic, strong) WDDXMPPChatNotifier *chatNotifier;

@property (nonatomic, strong) XMPPMessageDeliveryReceipts *xmppMessageDeliveryReceipts;

@end

@implementation XMPPClient

#pragma mark - Private Part

- (id)initWithSocialNetwork:(SocialNetwork *)socialNetwork
{
    if (self = [super init])
    {
        self.socialNetworkItem = socialNetwork;
        self.xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithDatabaseFilename:self.XMPPRosterDBName storeOptions:nil];
        self.xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:self.xmppRosterStorage];
        self.xmppRoster.autoFetchRoster = YES;
        self.xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
        
        self.xmppvCardStorage = [[XMPPvCardCoreDataStorage alloc] initWithDatabaseFilename:self.XMPPvCardDBName storeOptions:nil];
        self.xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_xmppvCardStorage];
        
        self.xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_xmppvCardTempModule];
        
        self.xmppCapabilitiesStorage = [[XMPPCapabilitiesCoreDataStorage alloc] initWithInMemoryStore];
        self.xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:_xmppCapabilitiesStorage];
        
        self.xmppCapabilities.autoFetchHashedCapabilities = YES;
        self.xmppCapabilities.autoFetchNonHashedCapabilities = NO;
        
        self.xmppReconnect = [[XMPPReconnect alloc] init];
        self.chatNotifier = [[WDDXMPPChatNotifier alloc] init];
        
        self.xmppMessageArchivingStorage = [[XMPPMessageArchivingCoreDataStorage alloc] initWithDatabaseFilename:self.XMPPMessageArchiveDBName storeOptions:nil];
        self.xmppMessageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:self.xmppMessageArchivingStorage];
        
        NSAssert(_xmppStream == nil, @"Method setupStream invoked multiple times");
        self.xmppStream = [[XMPPStream alloc] initWithFacebookAppId:kFacebookAccessKey];
        
        self.connected = NO;
        
#if !TARGET_IPHONE_SIMULATOR
		{
			self.xmppStream.enableBackgroundingOnSocket = YES;
		}
#endif
        
        self.xmppMessageDeliveryReceipts = [[XMPPMessageDeliveryReceipts alloc] init];
        self.xmppMessageDeliveryReceipts.autoSendMessageDeliveryReceipts = YES;
        self.xmppMessageDeliveryReceipts.autoSendMessageDeliveryRequests = YES;
        
        [self.xmppReconnect               activate:self.xmppStream];
		[self.xmppRoster                  activate:self.xmppStream];
		[self.xmppvCardTempModule         activate:self.xmppStream];
		[self.xmppvCardAvatarModule       activate:self.xmppStream];
		[self.xmppCapabilities            activate:self.xmppStream];
        [self.xmppMessageArchiving        activate:self.xmppStream];
        [self.chatNotifier                activate:self.xmppStream];
        [self.xmppMessageDeliveryReceipts activate:self.xmppStream];
        
        [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
        
        self.allowSelfSignedCertificates = YES;
		self.allowSSLHostNameMismatch = YES;
    }
    
    return self;
}

- (NSString *)XMPPRosterDBName
{
    return [NSString stringWithFormat:@"fb_%@_XMPPRosterStorage.sqlite", self.socialNetworkItem.profile.userID];
}

- (NSString *)XMPPvCardDBName
{
    return [NSString stringWithFormat:@"fb_%@_XMPPVCardStorage.sqlite", self.socialNetworkItem.profile.userID];
}

- (NSString *)XMPPMessageArchiveDBName
{
    return [NSString stringWithFormat:@"fb_%@_XMPPMessageStorage.sqlite", self.socialNetworkItem.profile.userID];
}

- (void)dealloc {

	[_xmppStream removeDelegate:self];
	[_xmppRoster removeDelegate:self];

	[_xmppReconnect         deactivate];
	[_xmppRoster            deactivate];
	[_xmppvCardTempModule   deactivate];
	[_xmppvCardAvatarModule deactivate];
	[_xmppCapabilities      deactivate];
    [_xmppMessageArchiving  deactivate];
    [_chatNotifier          deactivate];

	[_xmppStream disconnect];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket {
	DLog(@"XMPPStream socket did connected 1");
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings {
    DLog(@"XMPPStream socket will sercure with settings");
	if(self.allowSelfSignedCertificates)
    {
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}

	if(self.allowSSLHostNameMismatch)
    {
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
    else
    {
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).

		NSString *expectedCertName = nil;

		NSString *serverDomain = self.xmppStream.hostName;
		NSString *virtualDomain = [self.xmppStream.myJID domain];

		if([serverDomain isEqualToString:@"talk.google.com"])
        {
			if([virtualDomain isEqualToString:@"gmail.com"])
            {
				expectedCertName = virtualDomain;
			}
            else
            {
				expectedCertName = serverDomain;
			}
		}
        else if(serverDomain == nil)
        {
			expectedCertName = virtualDomain;
		}
        else
        {
			expectedCertName = serverDomain;
		}

		if(expectedCertName)
        {
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender {
    DLog(@"XMPPStream socket did secure");
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    DLog(@"XMPPStream socket did connected 2");
	
    if(![self.xmppStream isSecure])
    {
		NSError *error = nil;
		BOOL result = [self.xmppStream secureConnection:&error];
		if(result == NO)
        {
		}
	}
    else
    {
		NSError *error = nil;
		BOOL result = [_xmppStream authenticateWithFacebookAccessToken:self.socialNetworkItem.accessToken error:&error];
        
		if(result == NO)
        {
            // TODO : Add error processing
		}
	}
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    DLog(@"XMPPStream socket did athenticate");
    
    sender.myJID = [XMPPJID jidWithString:sender.myJID.bare resource:@"Woddl"];
    
	[self goOnline];
//    [self fetchInbox];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error {
    DLog(@"Authenticate Error: %@", error);
}

- (XMPPMessage*)xmppStream:(XMPPStream*)stream willReceiveMessage:(XMPPMessage *)aMessage
{
    if ([aMessage isChatMessageWithBody])
    {
        XMPPMessage *message = [aMessage copy];
        XMPPUserCoreDataStorageObject *user =
        [self.xmppRosterStorage userForJID:message.from.bareJID
                                xmppStream:self.xmppStream
                      managedObjectContext:[self.xmppRosterStorage mainThreadManagedObjectContext]];
        
        NSString *displayName = user.displayName;
        
        if (displayName)
        {
            NSXMLElement *displayNameElement = [NSXMLElement elementWithName:@"displayName" stringValue:displayName];
            [message addChild:displayNameElement];
        }
        return message;
    }
    return aMessage;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error {
    DLog(@"XMPPStream did receive error: %@", error);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
//	if(!isXmppConnected) {
		DLog(@"Unable to connect to server. Check xmppStream.hostName . Error: %@", [error debugDescription]);
//	}
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// TODO: Need decide how to handle changes in roster// mey be should be implemented other roster's protocols
- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence {
//	XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[presence from]
//	                                                         xmppStream:xmppStream
//	                                               managedObjectContext:[self managedObjectContext_roster]];
//
//	NSString *displayName = [user displayName];accessToken
//	NSString *jidStrBare = [presence fromStr];
//	NSString *body = nil;
//
//	if (![displayName isEqualToString:jidStrBare])
//	{
//		body = [NSString stringWithFormat:@"Buddy request from %@ <%@>", displayName, jidStrBare];
//	}
//	else
//	{
//		body = [NSString stringWithFormat:@"Buddy request from %@", displayName];
//	}
//
//
//	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
//	{
//		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
//		                                                    message:body
//		                                                   delegate:nil
//		                                          cancelButtonTitle:@"Not implemented"
//		                                          otherButtonTitles:nil];
//		[alertView show];
//	}
//	else
//	{
//		// We are not active, so use a local notification instead
//		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
//		localNotification.alertAction = @"Not implemented";
//		localNotification.alertBody = body;
//
//		[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
//	}
//
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Offnline/Offline
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// It's easy to create XML elments to send and to read received XML elements.
// You have the entire NSXMLElement and NSXMLNode API's.
//
// In addition to this, the NSXMLElement+XMPP category provides some very handy methods for working with XMPP.
//
// On the iPhone, Apple chose not to include the full NSXML suite.
// No problem - we use the KissXML library as a drop in replacement.
//
// For more information on working with XML elements, see the Wiki article:
// http://code.google.com/p/xmppframework/wiki/WorkingWithElements

- (void)goOnline {
    
    [self connect];
    
	XMPPPresence *presence = [XMPPPresence presence];         // type="available" is implicit
	[self.xmppStream sendElement:presence];
    DLog(@"XMPPClient is online");
    self.connected = YES;
}

- (void)goOffline {
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	[self.xmppStream sendElement:presence];
    DLog(@"XMPPClient is offline");
    self.connected = NO;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connect/disconnect
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL)connect
{
	if (![self.xmppStream isDisconnected])
    {
		return YES;
	}

	NSError *error = nil;
	if (![_xmppStream connectWithTimeout:30.f error:&error])
    {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"lskError", @"Error")
															message:NSLocalizedString(@"lskCantConnectToXMPPServer", @"Can't connect to XMPP server")
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"lskOK", @"OK")
												  otherButtonTitles:nil];
		[alertView show];
		DLog(@"Error connecting: %@", error);

		return NO;
	}    
    
	return YES;
}

- (void)disconnect
{
	[self goOffline];
	[self.xmppStream disconnect];
}

- (void)sendMessage:(NSString*)message
              toJid:(XMPPJID*)jid
{
    XMPPMessage *msg = [XMPPMessage messageWithType:@"chat" to:jid];
    //[msg addAttributeWithName:@"xmlns" stringValue:@"jabber:client"];
    //[msg addAttributeWithName:@"from" stringValue:self.xmppStream.myJID.full];
    
    [msg addBody:message];
    /*
    DDXMLNode *activeAttribute = [DDXMLNode attributeWithName:@"xmlns" stringValue:@"http://jabber.org/protocol/chatstates"];
    DDXMLNode *activeNode = [DDXMLNode elementWithName:@"active"
                                              children:nil
                                            attributes:@[activeAttribute]];
    
    [msg addChild:activeNode];
     */
    [self.xmppStream sendElement:msg];
}

- (void)fetchInbox
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSString *key = self.xmppStream.myJID.bare;
    
    FacebookFetchInboxOperation *operation =
    [[FacebookFetchInboxOperation alloc] initFacebookFetchInboxOperationWithToken:self.socialNetworkItem.accessToken
                                                                           client:self];
    operation.completionBlock = ^(void)
    {
        [defaults setBool:YES forKey:key];
    };
    
    [[[self.socialNetworkItem class] operationQueue] addOperation:operation];
}

//TODO:Implement this for messages history
- (NSArray *)getPreviousMessages
{
    return [[NSMutableArray alloc] init];
}

- (NSManagedObjectContext *)managedObjectContext_roster
{
    return self.xmppRosterStorage.mainThreadManagedObjectContext;
}

@end

