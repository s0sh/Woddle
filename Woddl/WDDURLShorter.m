//
//  WDDURLShorter.m
//  Woddl
//
//  Created by Oleg Komaristov on 2/18/14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "WDDURLShorter.h"
#import "ShortLink.h"

static const NSInteger MaximumInMemoryCacheSize = 150;

@interface WDDURLShorter ()

@property (nonatomic, retain) dispatch_queue_t operationsQueue;

@property (nonatomic, copy) ComplitionBlock allURLsProcessedBlock;
@property (nonatomic, assign) NSInteger linksToProcess;

@property (nonatomic, strong) NSMutableDictionary *inMemoryLinksCache;
@property (nonatomic, strong) NSMutableSet *processingLinks;

@property (nonatomic, strong) dispatch_queue_t masterContextQueue;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *storeCoordinator;
@property (nonatomic, strong) NSManagedObjectContext *masterObjectContext;
@property (nonatomic, strong) NSManagedObjectContext *mainObjectContext;

@end

@implementation WDDURLShorter

+ (instancetype)defaultShorter
{
    static WDDURLShorter *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        instance = [WDDURLShorter new];
    });
    
    return instance;
}

- (NSManagedObjectModel *)createManagedObjectModel
{
    NSManagedObjectModel *managedObjectModel = nil;
    NSString *momName = @"LinksShorterModel";
    
    NSString *momPath = [[NSBundle mainBundle] pathForResource:momName ofType:@"mom"];
    if (momPath == nil)
    {
        // The model may be versioned or created with Xcode 4, try momd as an extension.
        momPath = [[NSBundle mainBundle] pathForResource:momName ofType:@"momd"];
    }
    
    if (momPath)
    {
        // If path is nil, then NSURL or NSManagedObjectModel will throw an exception
        
        NSURL *momUrl = [NSURL fileURLWithPath:momPath];
        
        managedObjectModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:momUrl] copy];
    }

    return managedObjectModel;
}

- (void)initMasterDBInstance
{
    NSString *pathToDB = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"ShortLinks.sqlite"];
    NSURL *storeUrl = [NSURL fileURLWithPath:pathToDB];
    NSError *error = nil;
    self.managedObjectModel = [self createManagedObjectModel];
    self.storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    @try
    {
        if(![ self.storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                 configuration:nil
                                                           URL:storeUrl
                                                       options:@{
                                                                 NSMigratePersistentStoresAutomaticallyOption : @YES,
                                                                 NSInferMappingModelAutomaticallyOption : @YES
                                                                 }
                                                         error:&error])
        {
            @throw [NSException exceptionWithName:@"WDDDataBaseException"
                                           reason:@"Can't add persistent storage"
                                         userInfo:nil];
        }
    }
    @catch (NSException *exception)
    {
        [[NSFileManager defaultManager] removeItemAtURL:storeUrl error:nil];
        [self.storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                            configuration:nil
                                                      URL:storeUrl
                                                  options:@{
                                                            NSMigratePersistentStoresAutomaticallyOption : @YES,
                                                            NSInferMappingModelAutomaticallyOption : @YES
                                                            }
                                                    error:&error];
    }
    @finally
    {
        self.masterObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        self.masterObjectContext.persistentStoreCoordinator = self.storeCoordinator;
    }
}

- (id)init
{
    if (self = [super init])
    {
        self.operationsQueue = dispatch_queue_create("link shorter queue", DISPATCH_QUEUE_SERIAL);
        _linksToProcess = 0;
        self.inMemoryLinksCache = [[NSMutableDictionary alloc] initWithCapacity:MaximumInMemoryCacheSize];
        self.processingLinks = [NSMutableSet new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(processLowMemoryNotification:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(saveChangesToDB:)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
        
        dispatch_semaphore_t masterContextInitialization = dispatch_semaphore_create(0);
        self.masterContextQueue = dispatch_queue_create("link_shorter_master_object_context", DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(self.masterContextQueue, ^{
            
            [self initMasterDBInstance];
            dispatch_semaphore_signal(masterContextInitialization);
        });
        
        dispatch_semaphore_wait(masterContextInitialization, DISPATCH_TIME_FOREVER);
        
        if (![[NSThread currentThread] isEqual:[NSThread mainThread]])
        {
            dispatch_semaphore_t mainThreadContextInitialization = dispatch_semaphore_create(0);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.mainObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
                self.mainObjectContext.parentContext = self.masterObjectContext;
                
                dispatch_semaphore_signal(mainThreadContextInitialization);
            });
            
            dispatch_semaphore_wait(mainThreadContextInitialization, DISPATCH_TIME_FOREVER);
        }
        else
        {
            self.mainObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            self.mainObjectContext.parentContext = self.masterObjectContext;
        }
    }
    
    return self;
}

- (NSURL *)cachedLinkForURL:(NSURL *)sourceURL
{
    NSURL *link = self.inMemoryLinksCache[@(sourceURL.hash)];
    if (!link)
    {
        NSManagedObjectContext *objectContext = nil;
        if ([[NSThread mainThread] isEqual:[NSThread currentThread]])
        {
            objectContext = self.mainObjectContext;
        }
        else
        {
            objectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            objectContext.parentContext = self.mainObjectContext;
        }
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ShortLink class])];
        request.predicate = [NSPredicate predicateWithFormat:@"fullURLHash == %@", @(sourceURL.hash)];
        NSError *requestError = nil;
        NSArray *links = [objectContext executeFetchRequest:request error:&requestError];
        
        if (requestError)
        {
            DLog(@"Can't execute fetch request : %@", requestError.localizedDescription);
            return nil;
        }
        
        if (links.firstObject)
        {
            if ((link = [NSURL URLWithString:[(ShortLink *)links.firstObject url]]))
            {
                @synchronized(self.inMemoryLinksCache)
                {
                    [self.inMemoryLinksCache setObject:link forKey:@(sourceURL.hash)];
                }
            }
        }
    }

    return link;
}

- (void)getLinkForURL:(NSURL *)sourceURL withCallback:(void(^)(NSURL *resultURL))callback
{
    NSURL *cachedURL = [self cachedLinkForURL:sourceURL];
    if (cachedURL && callback)
    {
        callback(cachedURL);
    }
    else if (!cachedURL && ![self.processingLinks containsObject:@(sourceURL.hash)])
    {
        self.linksToProcess += 1;
        
        @synchronized(self.processingLinks)
        {
            [self.processingLinks addObject:@(self.processingLinks.hash)];
        }
        
        dispatch_async(self.operationsQueue, ^{
            
            NSString *requestString = [NSString stringWithFormat:@"action=shorturl&format=json&username=%@&password=%@&url=%@",
                                       kLinkShorterUsername, kLinkShorterPassword, sourceURL];

            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kLinkShorterURL]];
            request.HTTPMethod = @"POST";
            request.HTTPBody = [requestString dataUsingEncoding:NSUTF8StringEncoding];
            
            NSURLResponse *response = nil;
            NSError *error = nil;
            
            NSData *responseData = [NSURLConnection sendSynchronousRequest:request
                                                         returningResponse:&response
                                                                     error:&error];
            if (error)
            {
                if (callback)
                {
                    callback(nil);
                }
                self.linksToProcess -= 1;
                return;
            }
            
            id linkInfo = [NSJSONSerialization JSONObjectWithData:responseData
                                                            options:kNilOptions
                                                                error:&error];
            
            if (!error && [linkInfo[@"statusCode"] integerValue] == 200 && linkInfo[@"shorturl"])
            {
                NSURL *url = [NSURL URLWithString:linkInfo[@"shorturl"]];
                if (url)
                {
                    NSManagedObjectContext *objectContext = nil;
                    BOOL isMainThread = [[NSThread mainThread] isEqual:[NSThread currentThread]];
                    if (isMainThread)
                    {
                        objectContext = self.mainObjectContext;
                    }
                    else
                    {
                        objectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                        objectContext.parentContext = self.mainObjectContext;
                    }
                    
                    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:NSStringFromClass([ShortLink class]) inManagedObjectContext:objectContext];
                    ShortLink *shorlLink= (ShortLink *)[[NSManagedObject alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:objectContext];
                    shorlLink.fullURL = sourceURL.absoluteString;
                    shorlLink.fullURLHash = @(sourceURL.hash);
                    shorlLink.url = url.absoluteString;

                    if (!isMainThread)
                    {
                        NSError *saveError = nil;
                        [objectContext save:&saveError];
                        if (saveError)
                        {
                            DLog(@"Can't save changes to context %@ because of %@", objectContext, saveError.localizedDescription);
                        }
                    }
                    [self.mainObjectContext performBlock:^{
                        
                        NSError *mainContextSaveError = nil;
                        [self.mainObjectContext save:&mainContextSaveError];
                        
                        if (mainContextSaveError)
                        {
                            DLog(@"Can't save main context because of %@", mainContextSaveError.localizedDescription);
                        }
                        else
                        {
                            [self.masterObjectContext performBlock:^{
                                
                                NSError *masterContextSaveError = nil;
                                [self.masterObjectContext save:&masterContextSaveError];
                                
                                if (masterContextSaveError)
                                {
                                    DLog(@"Can't save master context because of %@", masterContextSaveError.localizedDescription);
                                }
                            }];
                        }
                        
                    }];
                    
                    @synchronized(self.inMemoryLinksCache)
                    {
                        [self.inMemoryLinksCache setObject:url forKey:@(sourceURL.hash)];
                    }
                }
                
                if (callback)
                {
                    callback(url);
                }
                
                self.linksToProcess -= 1;
                @synchronized(self.processingLinks)
                {
                    [self.processingLinks removeObject:@(self.processingLinks.hash)];
                }
            }
            else
            {
                if (callback)
                {
                    callback(nil);
                }
                self.linksToProcess -= 1;
            }
        });
    }
}

- (NSURL *)fullLinkForURL:(NSURL *)shortURL
{
    NSManagedObjectContext *objectContext = nil;
    if ([[NSThread mainThread] isEqual:[NSThread currentThread]])
    {
        objectContext = self.mainObjectContext;
    }
    else
    {
        objectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        objectContext.parentContext = self.mainObjectContext;
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ShortLink class])];
    request.predicate = [NSPredicate predicateWithFormat:@"url == %@", shortURL];
    NSError *requestError = nil;
    NSArray *links = [objectContext executeFetchRequest:request error:&requestError];
    
    if (requestError)
    {
        DLog(@"Can't execute fetch request : %@", requestError.localizedDescription);
        return shortURL;
    }
    
    NSURL *link = [NSURL URLWithString:[(ShortLink *)links.firstObject fullURL]];
    
    return (link ?: shortURL);
}

- (void)setLinksToProcess:(NSInteger)linksToProcess
{
    if (_linksToProcess && !linksToProcess && self.allURLsProcessedBlock)
    {
        self.allURLsProcessedBlock();
    }
    _linksToProcess = linksToProcess;
}

- (void)registerAllURLsPorocessedBlock:(ComplitionBlock)completeBlock;
{
    self.allURLsProcessedBlock = completeBlock;
}

- (void)unregisterAllURLsProcessedBlock
{
    self.allURLsProcessedBlock = nil;
}

#pragma mark - Memmory management

- (void)processLowMemoryNotification:(NSNotification *)notificaiton
{
    [self.inMemoryLinksCache removeAllObjects];
}

- (void)saveChangesToDB:(NSNotification *)notificaiton
{
}

@end
