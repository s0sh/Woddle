//
//  PrivateMessagesModel.m
//  Woddl
//
//  Created by Roman Tsymbalyuk on 1/16/13.
//
//

#import "PrivateMessagesModel.h"
#import "XMPPFramework.h"
#import "XMPPClient.h"
#import "PrivateMessagesStorage.h"
#import "PrivateMessageObject.h"
#import "XMPPMessage+GetBody.h"

#import "SocialNetwork.h"
#import "FacebookSN.h"
#import "WDDDataBase.h"

#import "WDDWeakObject.h"

@interface PrivateMessagesModel () <NSFetchedResultsControllerDelegate>
{
    dispatch_queue_t rosterDelegateQueue;
}

@property (nonatomic) BOOL allowSelfSignedCertificates;
@property (nonatomic) BOOL allowSSLHostNameMismatch;

@property (nonatomic, strong) NSFetchedResultsController *socialNetworks;
@property (nonatomic, strong) NSMutableArray *delegates;

- (void)addXMPPClientForItem:(SocialNetwork *)anItem;
- (void)removeXMPPClientForItem:(SocialNetwork *)anItem;

@end


@implementation PrivateMessagesModel


#pragma mark - Private part

+ (instancetype)sharedModel
{
    static PrivateMessagesModel *sharedModel = nil;

    static dispatch_once_t instaceModelToken;
    dispatch_once(&instaceModelToken, ^{
        
        sharedModel = [[PrivateMessagesModel alloc] init];
    });

    return sharedModel;
}

- (id)init
{
	if ([super init])
    {
        _clients = [[NSMutableArray alloc] init];
        rosterDelegateQueue = dispatch_queue_create("roster delegate queue", DISPATCH_QUEUE_CONCURRENT);
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([FacebookSN class])];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"SELF.isChatEnabled == %@ AND SELF.activeState == %@", @YES, @YES];
        fetchRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES]];
        self.socialNetworks = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                  managedObjectContext:[WDDDataBase sharedDatabase].managedObjectContext
                                                                    sectionNameKeyPath:nil
                                                                             cacheName:nil];
        self.socialNetworks.delegate = self;
        NSError *fetchError = nil;
        [self.socialNetworks performFetch:&fetchError];
        
        if (fetchError)
        {
            DLog(@"Can't fetch FB accounts list: %@", fetchError);
        }
        
		for(SocialNetwork *item in self.socialNetworks.fetchedObjects)
        {
            [self addXMPPClientForItem:item];
		}
        
        self.countUnreadMessages = 0;
        
        _privateMessagesStorage = [[PrivateMessagesStorage alloc] init];
        self.unreadOfflineMessages = [[NSMutableDictionary alloc] init];
        
        self.delegates = [[NSMutableArray alloc] initWithCapacity:10];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(socialNetworkItemDidChangeStatus:)
													 name:@"socialNetworkItemDidChangeStatus"
												   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationWillTerminate:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
	}
    
	return self;
}

#pragma mark - NSNotification Handler

-(void)socialNetworkItemDidChangeStatus:(NSNotification *)notification{
//    NSDictionary *userInfo = notification.userInfo;
//    NSDictionary *userInfo = [[NSDictionary alloc] initWithDictionary:notification.object];
    
//    SocialNetworkItem * i = [userInfo objectForKey:@"item"];
//    
//    for (XMPPClient *client in _clients)
//    {
//        if ([[client socialNetworkItem] isEqual:i])
//        {
//            ([i isActive] && [i isIMOnline])?[client goOnline]:[client disconnect]; // set xmppclient online/offline regarding to item
//        }
//    }
}

#pragma mark - Manage XMPP Clients

- (void)addXMPPClientForItem:(SocialNetwork *)anItem
{
    if ([anItem.type isEqual:@(kSocialNetworkFacebook)])
    {
        XMPPClient *client = [[XMPPClient alloc] initWithSocialNetwork:anItem];
        
        [client.xmppRoster addDelegate:self delegateQueue:rosterDelegateQueue];
        [_clients addObject:client];
        
        for (WDDWeakObject *delegateObj in self.delegates)
        {
            if ([delegateObj.object respondsToSelector:@selector(xmppClientAdded:)])
            {
                [(id<PrivateMessagesModelDelegate>)delegateObj.object xmppClientAdded:client];
            }
        }
        
        if (anItem.activeState.boolValue)
        {
            [client goOnline];
            _countUnreadMessages += [self getCountOfUnreadMessagesForXmppClient:client];
        }
    }
}


- (void)removeXMPPClientForItem:(SocialNetwork *)anItem
{
    __block XMPPClient * theClient=nil;
    
    [_clients enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([((XMPPClient *)obj).socialNetworkItem isEqual:anItem])
        {
            theClient = obj;
            *stop = YES;
        }
    }];
    
    if (theClient)
    {
        for (WDDWeakObject *delegateObj in self.delegates)
        {
            if ([delegateObj.object respondsToSelector:@selector(xmppClientWillBeRemoved:)])
            {
                [(id<PrivateMessagesModelDelegate>)delegateObj.object xmppClientWillBeRemoved:theClient];
            }
        }
        
        [theClient disconnect];
        [_clients removeObject:theClient];
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - XMPPClientDelegate section
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(void)xmppClient:(XMPPClient *)client goInOfflineSuccessful:(BOOL)s
{
    [self saveUnreadCountForClient:client];
}

-(void)xmppClient:(XMPPClient *)client userGoInOnlineSuccessful:(BOOL)s
{
    
}

-(void)xmppClient:(XMPPClient *)client getPreviousMessages:(NSArray *)messages
{
    
}

-(void)xmppClient:(XMPPClient *)client sendMessageSuccessful:(BOOL)s
{
    
}

- (void)xmppClient:(XMPPClient *)client didReceiveNewMessage:(XMPPMessage *)aMessage
{
    @synchronized(self)
    {
        DLog(@"Received messages: %@ from XMPPClient: %@", aMessage, client);

        for (WDDWeakObject *delegateObj in self.delegates)
        {
            if ([delegateObj.object respondsToSelector:@selector(xmppClient:didReceiveNewMessage:)])
            {
                [(id<PrivateMessagesModelDelegate>)delegateObj.object xmppClient:client didReceiveNewMessage:aMessage];
            }
        }
        
//        if (aMessage.isChatMessageWithBody)
//        {
//            PrivateMessageObject * messageObject = [[PrivateMessageObject alloc] initWithXMPPClien:client from:aMessage.from messageText:aMessage.getBodyStr incoming:YES];
//            [_privateMessagesStorage addMessageIntoTheStorage:messageObject];
//            
//            if ([_mainView respondsToSelector:@selector(xmppClient:didReceiveNewMessage:)])
//            {
//                [_mainView xmppClient:client didReceiveNewMessage:aMessage];
//            }
//        }
    }
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma makr -
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//Bare JID -XXXXXXXXXX@chat.facebook.com
- (XMPPClient *)clientByBare:(NSString *)aBare{
    XMPPClient * xmppClient = nil;
    for (XMPPClient * client in _clients){
        NSString *userJID = client.xmppStream.myJID.bare; // get stream bare
        if ([userJID isEqualToString:aBare]){
            xmppClient = client;
        }
    }   
    return xmppClient;
}

#pragma mark -

- (BOOL)getOldMessagesForClient:(XMPPClient *)xmppClient andUser:(XMPPUserCoreDataStorageObject *)xmppUser {
    NSString *fid = [xmppUser.jid.user substringFromIndex:1];
    
    DLog(@"loading chat history for %@", fid);
    
    
    NSString *query = [NSString stringWithFormat:@"SELECT thread_id, body, author_id, created_time FROM message WHERE thread_id IN (SELECT thread_id FROM message WHERE  thread_id IN (SELECT thread_id FROM thread WHERE folder_id = 0) AND author_id = %@ ORDER BY created_time ASC) ORDER BY created_time ASC",fid];
    
    NSString *fql = [query stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];                                  // encode into ascii
    
    NSString *requestString = [NSString stringWithFormat:@"https://graph.facebook.com/fql?q=%@&access_token=%@", fql, xmppClient.socialNetworkItem.accessToken];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:requestString]];
    
    NSHTTPURLResponse *aresponse;
    NSError *error = nil;
    
    NSData *requestData = [NSURLConnection sendSynchronousRequest:request returningResponse:&aresponse error:&error];
    NSDictionary *resp = [NSJSONSerialization JSONObjectWithData:requestData
                                                                       options:0
                                                                         error:&error];
    
    if(error) {
        DLog(@"Error from JSONDecoder: %@", error);
    } else {
        
        if ([resp objectForKey:@"error"]){
            DLog(@"Error: %@", [resp objectForKey:@"error"]);
        }
        
        [_privateMessagesStorage removeAllMessagesBetween:xmppClient jid:xmppUser.jid];
        NSMutableArray *messages = [[NSMutableArray alloc]init];
        
        for(NSDictionary *dict in [resp objectForKey : @"data"]) {
            
            BOOL incom = ([[NSString stringWithFormat:@"%@",[dict valueForKey:@"author_id"]] isEqualToString:fid])?YES:NO;
            
            PrivateMessageObject *message = [[PrivateMessageObject alloc] initWithXMPPClien:xmppClient from:xmppUser.jid messageText:[dict objectForKey:@"body"] incoming:incom];
            [messages addObject:message];
        }
        [_privateMessagesStorage addMessagesIntoTheStorage:messages];
        
        return YES;
    }
    return NO;
}

- (NSInteger)getCountOfNewMessages{
    NSInteger count = 0;
    
//    for (XMPPClient * client in _clients){
//        if (client.socialNetworkItem.isIMOnline && client.socialNetworkItem.isActive)
//        {
//            count+=[self getCountOfUnreadMessagesForXmppClient:client];
//        }
//    }
    
    return count;
}

-(NSInteger)getCountOfUnreadMessagesForXmppClient:(XMPPClient *)xmppClient {
    
    NSInteger unreadMessagesCountForClient = 0;
    
    
    NSString *query = [NSString stringWithFormat:@"SELECT thread_id, subject, originator, unread, unseen FROM thread WHERE folder_id = 0 and unread != 0"];
    
    NSString *fql = [query stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];                                  // encode into ascii
    
    NSString *requestString = [NSString stringWithFormat:@"https://graph.facebook.com/fql?q=%@&access_token=%@", fql, xmppClient.socialNetworkItem.accessToken];
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:requestString]];
    
    NSHTTPURLResponse *aresponse;
    NSError *error = nil;
    
    NSData *requestData = [NSURLConnection sendSynchronousRequest:request returningResponse:&aresponse error:&error];
    
    if (!requestData) return 0;
    
    NSDictionary *deserializedData = [NSJSONSerialization JSONObjectWithData:requestData
                                                                     options:0
                                                                       error:&error];
    
    NSDictionary *responseError = [deserializedData objectForKey:@"error"];// check if facebook returned error.
    
    if(error || responseError) {
        DLog(@"Error from JSONDecoder: %@ , %@", error, responseError);
    } else {
        
        for (NSDictionary *dict in [deserializedData objectForKey:@"data"]) {
            
            NSInteger unreadMessagesInThreadCount = [[dict objectForKey:@"unread"] integerValue];
            
            unreadMessagesCountForClient+=unreadMessagesInThreadCount;
            
            NSString *messageAuthorID = [dict objectForKey:@"originator"];
            NSString *jidString = [NSString stringWithFormat:@"-%@@chat.facebook.com", messageAuthorID];
            
            [_unreadOfflineMessages setObject:[NSNumber numberWithInteger:unreadMessagesInThreadCount] forKey:jidString];
            
        }
    }
    return unreadMessagesCountForClient;
}


#pragma mark - NSFetchedResultsControllerDelegate protocol implementation

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            [self addXMPPClientForItem:anObject];
        break;
            
        case NSFetchedResultsChangeDelete:
            [self removeXMPPClientForItem:anObject];
        break;
            
        case NSFetchedResultsChangeUpdate:
            /*
            [self removeXMPPClientForItem:anObject];
            [self addXMPPClientForItem:anObject];
             */
        break;
            
        default:
        break;
    }
}

#pragma mark - Delegates registration / unregistration

- (void)registerDelegate:(id<PrivateMessagesModelDelegate>)delegate
{
    @synchronized(self.delegates)
    {
        WDDWeakObject *weekObject = [WDDWeakObject weekObjectWithObject:delegate];
        
        if([self.delegates indexOfObject:weekObject] == NSNotFound)
        {
            [self.delegates addObject:weekObject];
        }
    }
}

- (void)unregisterDelegate:(id<PrivateMessagesModelDelegate>)delegate
{
    @synchronized(self.delegates)
    {
        WDDWeakObject *weekObject = [WDDWeakObject weekObjectWithObject:delegate];
        NSInteger index = [self.delegates indexOfObject:weekObject];
        
        if(index != NSNotFound)
        {
            [self.delegates removeObjectAtIndex:index];
        }
    }
}

#pragma makr - Application notificaitons

- (void)applicationWillTerminate:(NSNotification *)notification
{
    for (XMPPClient *client in _clients)
    {
        if (client.connected)
        {
            [self saveUnreadCountForClient:client];
        }
    }
}

- (void)saveUnreadCountForClient:(XMPPClient *)client
{
    NSMutableDictionary *unreadMessages = [NSMutableDictionary new];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"XMPPUserCoreDataStorageObject"];
    NSArray *users = [client.xmppRosterStorage.mainThreadManagedObjectContext executeFetchRequest:request error:nil];
    
    for (NSManagedObject *user in users)
    {
        NSNumber *messageCount = [user valueForKey:@"unreadMessages"];
        if (messageCount.integerValue)
        {
            [unreadMessages setObject:messageCount forKey:[user valueForKey:@"jidStr"]];
        }
    }
    
    if (unreadMessages.count)
    {
        [[NSUserDefaults standardUserDefaults] setObject:unreadMessages forKey:client.xmppStream.myJID.bare];
    }
    else if ([[NSUserDefaults standardUserDefaults] objectForKey:client.xmppStream.myJID.bare])
    {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:client.xmppStream.myJID.bare];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - XMPPRosterDelegate protocol implementation

- (void)xmppRosterDidEndPopulating:(XMPPRoster *)sender
{
    __block XMPPClient *client = nil;
    [_clients enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if ([(XMPPClient *)obj xmppRoster] == sender)
        {
            client = obj;
            *stop = YES;
        }
    }];
    
    NSManagedObjectContext *currentRosterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    dispatch_sync(dispatch_get_main_queue(), ^{
        
        currentRosterContext.parentContext = client.xmppRosterStorage.mainThreadManagedObjectContext;
    });
    NSDictionary *unreadMessages = [[NSUserDefaults standardUserDefaults] objectForKey:client.xmppStream.myJID.bare];
    if ([unreadMessages isKindOfClass:[NSDictionary class]])
    {
        for (NSString *jidStr in unreadMessages.allKeys)
        {
            
            XMPPJID *jid = [XMPPJID jidWithString:jidStr];
            XMPPUserCoreDataStorageObject *userObj = [client.xmppRosterStorage userForJID:jid
                                                                               xmppStream:client.xmppStream
                                                                     managedObjectContext:currentRosterContext];
            userObj.unreadMessages = @(userObj.unreadMessages.integerValue + [unreadMessages[jidStr] integerValue]);
            [currentRosterContext save:nil];
        }
        
        if (unreadMessages)
        {
            [currentRosterContext.parentContext performBlockAndWait:^{
                
                [currentRosterContext.parentContext save:nil];
            }];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUnreadMessageRecieved object:nil];
        }
    }
    
    [client fetchInbox];
}



@end
