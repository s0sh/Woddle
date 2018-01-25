//
//  FacebookFetchInboxOperation.m
//  Woddl
//
//  Created by Petro Korenev on 12/2/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "FacebookFetchInboxOperation.h"
#import "FacebookRequest.h"

#import "XMPPClient.h"
#import "XMPPFramework.h"

//#import <XMPPFramework/XMPPMessage.h>
//#import <NSDate+XMPPDateTimeProfiles.h>

@implementation FacebookFetchInboxOperation

#pragma mark - Initialization

-(id)initFacebookFetchInboxOperationWithToken:(NSString*)token
                                       client:(XMPPClient *)client
{
    if (self = [super init])
    {
        self.token  = token;
        self.client = client;
    }
    return self;
}

#pragma mark - Main Operation

- (void)main
{
    FacebookRequest * request = [[FacebookRequest alloc] init];
    NSDictionary * result = [request fetchInboxWithToken:self.token];
    
    XMPPJID *myJID = self.client.xmppStream.myJID;
    NSString *myId = [myJID.user substringFromIndex:1];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *defaultsKey = [NSString stringWithFormat:@"FBChatLastUpdateKey_%@", self.token];
    
    __block NSDate *updatedTime = nil;
    NSDate *lastUpdate = [userDefaults objectForKey:defaultsKey];
    __block BOOL isUpdated = NO;
    __block BOOL isNeedSaveRoster = NO;
    
PROCESS_NEXT_PAGE:
    if (result)
    {
        NSArray *data = result[@"data"];
        
        NSManagedObjectContext *currentMessagesContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            currentMessagesContext.parentContext = self.client.xmppMessageArchivingStorage.mainThreadManagedObjectContext;
        });
        
        NSManagedObjectContext *currentRosterContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            currentRosterContext.parentContext = self.client.xmppRosterStorage.mainThreadManagedObjectContext;
        });
        
        [data enumerateObjectsUsingBlock:^(NSDictionary *thread, NSUInteger idx, BOOL *stop)
        {
            NSArray *to = thread[@"to"][@"data"];
            
            NSDate *currentUpdatedTime = [FacebookRequest convertFacebookDateToNSDate:thread[@"updated_time"]];
            if (!isUpdated && lastUpdate && [lastUpdate compare:currentUpdatedTime] == NSOrderedDescending)
            {
                isUpdated = YES;
            }
            if (!updatedTime || [currentUpdatedTime compare:updatedTime] == NSOrderedDescending)
            {
                updatedTime = currentUpdatedTime;
            }
            
            NSInteger indexOfConversation = [to indexOfObjectPassingTest:^BOOL(NSDictionary *user, NSUInteger idx, BOOL *stop)
            {
                return ![user[@"id"] isEqualToString:myId];
            }];
                        
            if (indexOfConversation == NSNotFound) return;
            
            
            NSString *conversationId = to[indexOfConversation][@"id"];
            XMPPJID *conversation = [XMPPJID jidWithString:[NSString stringWithFormat:@"-%@@chat.facebook.com", conversationId]];
            
            NSInteger unreadCount = [thread[@"unread"] integerValue];
            __block NSInteger newMessages = 0;
            
            NSArray *messages = thread[@"comments"][@"data"];
            [messages enumerateObjectsUsingBlock:^(NSDictionary *message, NSUInteger idx, BOOL *stop)
            {
                NSString *dateStr       = message[@"created_time"];
                NSString *fromStr       = message[@"from"][@"id"];
                NSString *messageStr    = message[@"message"];
                
                BOOL isOutgoing = [fromStr isEqualToString:myId];
                
                
                NSDate *timestamp = [FacebookRequest convertFacebookDateToNSDate:dateStr];
                
                NSError *requestErorr = nil;
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bareJidStr LIKE %@ AND outgoing == %@ AND timestamp == %@", conversation.bare, @(isOutgoing), timestamp];
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:self.client.xmppMessageArchivingStorage.messageEntityName];
                fetchRequest.predicate = predicate;
                
                NSArray *messages= [currentMessagesContext executeFetchRequest:fetchRequest error:&requestErorr];
                
                if (!messages.count)
                {
                    XMPPMessage *xmppMessage = [XMPPMessage messageWithType:@"chat" to:isOutgoing ? conversation : myJID];
                    [xmppMessage addAttributeWithName:@"from" stringValue:isOutgoing ? myJID.bare : conversation.bare];
                    
                    [xmppMessage addBody:messageStr];
                    
                    NSXMLElement *delay = [XMPPElement elementWithName:@"delay" xmlns:@"urn:xmpp:delay"];
                    [delay          setStringValue:@"Offline storage"];
                    [delay          addAttributeWithName:@"stamp" stringValue:[timestamp xmppDateTimeString]];
                    [delay          addAttributeWithName:@"from"  stringValue:@"chat.facebook.com"];
                    [xmppMessage    addChild:delay];
                    
                    if (isOutgoing)
                    {
                        [self.client.xmppMessageArchiving performSelector:@selector(xmppStream:didSendMessage:)
                                                               withObject:self.client.xmppStream
                                                               withObject:xmppMessage];
                    }
                    else
                    {
                        [self.client.xmppMessageArchiving performSelector:@selector(xmppStream:didReceiveMessage:)
                                                               withObject:self.client.xmppStream
                                                               withObject:xmppMessage];
                        
                        ++newMessages;
                    }
                }
            }];
            
            unreadCount = MIN(unreadCount, newMessages);
            
            if (unreadCount)
            {
                XMPPUserCoreDataStorageObject *userObj = [self.client.xmppRosterStorage userForJID:conversation
                                                                                        xmppStream:self.client.xmppStream
                                                                              managedObjectContext:currentRosterContext];
                userObj.unreadMessages = @(userObj.unreadMessages.integerValue + unreadCount);
                [currentRosterContext save:nil];
                
                isNeedSaveRoster = YES;
            }

        }];
        
        if (isNeedSaveRoster)
        {
            [currentRosterContext.parentContext performBlockAndWait:^{
                
                [currentRosterContext.parentContext save:nil];
            }];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationUnreadMessageRecieved object:nil];
        }
        
        if (!isUpdated && data.count && result[@"paging"][@"next"])
        {
            NSURL *requestURL = [NSURL URLWithString:[result[@"paging"][@"next"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL
                                                                   cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                               timeoutInterval:30.f];
            
            NSError *error = nil;
            NSURLResponse *response = nil;
            
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
            
            if(data)
            {
                NSError* error = nil;
                result = [NSJSONSerialization JSONObjectWithData:data
                                                         options:kNilOptions
                                                           error:&error];
                
                if (result && !error)
                {
                    goto PROCESS_NEXT_PAGE;
                }
            }
        }
        
        if (updatedTime)
        {
            [userDefaults setObject:updatedTime forKey:defaultsKey];
            [userDefaults synchronize];
        }
    }
}

@end
