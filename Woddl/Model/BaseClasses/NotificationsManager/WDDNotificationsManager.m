//
//  WDDNotificationsManager.m
//  Woddl
//
//  Created by Petro Korienev on 5/12/14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "WDDNotificationsManager.h"

#import "WDDDataBase.h"

#define SEC_PER_MIN 60

char * const WDDNotificationsManagerQueueLabel = "com.woddl.notifications-manager.queue";
char * const WDDNotificationsManagerKey        = "com.woddl.notifications-manager.key";
char * const WDDNotificationsManagerContext    = "com.woddl.notifications-manager.context";

@interface WDDNotificationsManager () <NSFetchedResultsControllerDelegate>
{
    dispatch_source_t timer;
    dispatch_queue_t  privateQueue;
    
    UIBackgroundTaskIdentifier backgroundTaskId;
    
    NSFetchedResultsController *notificationsFRC;
}

@end

@implementation WDDNotificationsManager

#pragma mark - singletone

+ (instancetype)sharedManager
{
    static id sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [self new];
    });
    
    return sharedManager;
}

#pragma mark - init

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        privateQueue = dispatch_queue_create(WDDNotificationsManagerQueueLabel, DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(privateQueue, WDDNotificationsManagerKey, WDDNotificationsManagerContext, NULL);
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActive:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willResignActive:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, privateQueue);
        
        if (timer)
        {
            dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), SEC_PER_MIN * NSEC_PER_SEC, NSEC_PER_SEC / 10);
            dispatch_source_set_event_handler(timer, ^()
            {
                [self fetchNotifications];
            });
        }
    }
    return self;
}

- (NSFetchedResultsController*)notificationsFRC
{
    if (!notificationsFRC)
    {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Notification class])];
        
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO]];
        
        notificationsFRC = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                               managedObjectContext:[WDDDataBase sharedDatabase].managedObjectContext
                                                                 sectionNameKeyPath:nil
                                                                          cacheName:nil];
        notificationsFRC.delegate = self;
        [notificationsFRC performFetch:nil];
    }
    return notificationsFRC;
}

- (void)disconnectFromDB
{
    notificationsFRC = nil;
}

#pragma mark - app state observing

- (void)didBecomeActive:(NSNotification*)notification
{
    dispatch_resume(timer);
}

- (void)willResignActive:(NSNotification*)notification
{
    dispatch_suspend(timer);
}

#pragma mark - fetching social network notifications

- (void)fetchNotifications
{
    if ([WDDDataBase isConnectedToDB])
    {
        if (backgroundTaskId != UIBackgroundTaskInvalid)
        {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskId];
        }
        
        backgroundTaskId =  [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^()
        {
            [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskId];
            backgroundTaskId = UIBackgroundTaskInvalid;
        }];
        
        void (^notificationsFetcherBlock)() = ^()
        {
            NSArray *socialNetworks = [[WDDDataBase sharedDatabase] fetchAllSocialNetworks];
            [socialNetworks enumerateObjectsUsingBlock:^(SocialNetwork *sn, NSUInteger idx, BOOL *stop)
            {
                if ([sn respondsToSelector:@selector(fetchNotifications)] && sn.activeState.boolValue)
                {
                    [sn fetchNotifications];
                }
            }];
        };
        
        if (dispatch_get_specific(WDDNotificationsManagerKey) == WDDNotificationsManagerContext)
        {
            notificationsFetcherBlock();
        }
        else
        {
            dispatch_async(privateQueue, notificationsFetcherBlock);
        }
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNotificationsDidUpdate object:nil];    
}

@end
