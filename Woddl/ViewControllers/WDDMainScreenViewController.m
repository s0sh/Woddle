//
//  IDSMainScreenViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 22.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDMainScreenViewController.h"

#import "ECSlidingViewController.h"
#import "WDDSideMenuViewController.h"
#import "WDDReadLaterViewController.h"
#import "WDDDataBase.h"
#import "Post.h"
#import "Tag.h"
#import "SocialNetworkManager.h"
#import "InstagramPost.h"
#import "WDDMainPostCell.h"
#import "UIImage+ResizeAdditions.h"
#import "TwitterPost.h"
#import "SocialNetwork.h"
#import "Comment.h"
#import "WDDConstants.h"
#import "TwitterPost.h"
#import "LinkedinPost.h"
#import <SDWebImage/SDWebImageManager.h>
#import "WDDLocationManager.h"
#import "UserProfile.h"
#import <BTBadgeView/BTBadgeView.h>

#import "PrivateMessagesModel.h"
#import "XMPPClient.h"

#import "WDDAppDelegate.h"
#import "WDDNotificationsManager.h"

static const NSInteger kCountLoadMorePosts = 10;

@interface WDDMainScreenViewController () <IDSEllipseMenuDelegate, WDDMainPostCellDelegate, UIGestureRecognizerDelegate>

//@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;


//  Views
@property (weak, nonatomic) IBOutlet UIImageView *imIconImageView;
@property (assign, nonatomic) NSUInteger unreadMessagesCount;
@property (weak, nonatomic) IBOutlet BTBadgeView *unreadMessagesBadge;

@end

@implementation WDDMainScreenViewController

@synthesize menuSideButton;
@synthesize navigationBar;

#pragma mark - UIViewController methods

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateStatusChanged:)
                                                 name:kNotificationUpdatingStatusChanged
                                               object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupSliding];
    
    [[WDDNotificationsManager sharedManager] notificationsFRC];     // This is final init of notificatins manager after DB is 100% connected
    [[WDDNotificationsManager sharedManager] fetchNotifications];
    
    if (IS_IOS7)
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kNotificationDidDownloadNewPots
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self didDownloadPosts];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kNotificationInternetNotConnected
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self connectionAllert];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kNotificationUnreadMessageRecieved
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self startUnreadMessageAnimationWithCount:++self.unreadMessagesCount];
                                                  }];
    
    
    [self setupNavigationBarTitle];
    [self setupIMIconAnimation];
    [self setupPullToRefresh];
    [self setupNavigationBarButtons];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadTableContent)
                                                 name:kNotificationRefetchMainSreenTable
                                               object:nil];
    //[self.postsTable disableLoadMore];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (!IS_IOS7)
    {
        if ([[UIScreen mainScreen] bounds].size.height <= 480.0)
        {
            [self resizeTableViewWithHeight:384.0f];
        }
        else
        {
            [self resizeTableViewWithHeight:472.0f];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    if ([WDDDataBase sharedDatabase].isSearchProduced || [WDDDataBase sharedDatabase].isUpdatingStatus )
    {
        [self showProcessHUDWithText:NSLocalizedString(@"lskUpdating", @"Updating message on main screen HUD")];
    }

    [super viewWillAppear:animated];
    self.postsTable.scrollsToTop = YES;
        
    [self setAnchorForSlideMenu];
}

- (void)viewDidAppear:(BOOL)animated
{
    [Heatmaps trackScreenWithKey:@"503395516a70d21a-f9652991"];
    
    if ([WDDDataBase sharedDatabase].isSearchProduced)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            [[WDDDataBase sharedDatabase] removeSearchedPosts];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [super viewDidAppear:animated];
                self.fetchedResultsController.delegate = self;
                
                [self reloadTableContent];
                self.postsTable.scrollsToTop = YES;
                
                [self setAnchorForSlideMenu];
                [self removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskUpdated", @"Updated message on main screen HUD")];
            });
        });
    }
    if ([WDDDataBase sharedDatabase].isUpdatingStatus)
    {
        self.fetchedResultsController.delegate = self;
        
        [self reloadTableContent];
        
        [self setAnchorForSlideMenu];
        [self removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskUpdated", @"Updated message on main screen HUD")];
        
        [WDDDataBase sharedDatabase].updatingStatus = NO;
        
        [super viewDidAppear:animated];
    }
    else
    {
        [super viewDidAppear:animated];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{

        [self checkAndUpdateAnimationForUnreadMessages];
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.postsTable.scrollsToTop = NO;
    self.isAppeared = NO;
    [self removeAnchorForSlideMenu];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [Heatmaps trackScreenWithKey:@"503395516a70d21a-f9652991"];
}

- (void)resizeTableViewWithHeight:(CGFloat)height
{
    if (CGRectGetHeight(self.postsTable.frame) > height)
    {
        CGRect frame = self.postsTable.frame;
        frame.size.height = height;
        self.postsTable.frame = frame;
    }
}

- (void)reloadTableContent
{
    [NSFetchedResultsController deleteCacheWithName:kPostMessagesCache];
    
    
    self.fetchedResultsController.fetchRequest.predicate = [self formPredicate];
    [self.fetchedResultsController performFetch:nil];
    [self.postsTable reloadData];
}

- (void)updateStatusChanged:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{

        self.postsTable.pullTableIsRefreshing = [notification.userInfo[kNotificationParamaterStatus] boolValue];
    });
}

static const NSTimeInterval kAnimationDuration = 2.0f;
static NSString * const kIMIconBase = @"main_im_frame";
static const NSUInteger kIMIconFrames = 14;

- (void)setupIMIconAnimation
{
    NSArray *imFrames = [self framesWithBaseFrameName:kIMIconBase count:kIMIconFrames];
    
    self.imIconImageView.image = [imFrames firstObject];
    self.imIconImageView.animationImages = imFrames;
    self.imIconImageView.animationDuration = kAnimationDuration;
    self.imIconImageView.animationRepeatCount = 0;  // repeat forever

    self.unreadMessagesBadge.hideWhenEmpty = YES;
    self.unreadMessagesBadge.fillColor = [UIColor redColor];
    self.unreadMessagesBadge.strokeColor = [UIColor whiteColor];
    self.unreadMessagesBadge.strokeWidth = 1.0f;
    self.unreadMessagesBadge.textColor = [UIColor whiteColor];
    self.unreadMessagesBadge.font = [UIFont systemFontOfSize:8.0f];
    self.unreadMessagesBadge.shine = NO;
    self.unreadMessagesBadge.shadow = NO;
    self.unreadMessagesBadge.value = [@(self.unreadMessagesCount) stringValue];
}

- (NSArray *)framesWithBaseFrameName:(NSString *)frameName count:(NSUInteger)count
{
    NSMutableArray *frames = [[NSMutableArray alloc] initWithCapacity:count];
    
    for (NSUInteger i = 0; i<count; i++)
    {
        NSString *frame = [NSString stringWithFormat:@"%@%u", frameName, i];
        UIImage *frameImage = [UIImage imageNamed:frame];
        [frames addObject:frameImage];
    }
    
    return [frames copy];
}

- (void)setupPullToRefresh
{
    self.postsTable.pullDelegate = self;
    self.postsTable.pullArrowImage = [UIImage imageNamed:@"blackArrow"];
    self.postsTable.pullBackgroundColor = [UIColor whiteColor];
    self.postsTable.pullTextColor = [UIColor darkGrayColor];
}

#pragma marl - Filter setter

- (void)setSocialNetworkFilterType:(NSNumber *)socialNetworkFilterType
{
    _socialNetworkFilterType = socialNetworkFilterType;
    _groupIDFilter = nil;
    
    [self reloadTableContent];
}

- (void)setGroupIDFilter:(NSString *)groupIDFilter
{
    _groupIDFilter = groupIDFilter;
    
    if (groupIDFilter)
    {
        _socialNetworkFilterType = nil;
    }
    
    [self reloadTableContent];
}

#pragma mark - Unread/Read message in chat logic

- (void)startUnreadMessageAnimationWithCount:(NSUInteger)count
{
    self.unreadMessagesBadge.value = [@(count) stringValue];
//    if (!self.imIconImageView.isAnimating)
//    {
//        [self.imIconImageView startAnimating];
//    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^()
    {
        self.unreadMessagesBadge.value = [@(self.unreadMessagesCount = [self getUnreadMessagesCount]) stringValue];
    });
}

- (void)checkAndUpdateAnimationForUnreadMessages
{
    self.unreadMessagesCount = [self getUnreadMessagesCount];
    if (!self.unreadMessagesCount)
    {
        [self stopUnreadAnimation];
    }
    else
    {
        [self startUnreadMessageAnimationWithCount:self.unreadMessagesCount];
    }
}

- (NSUInteger)getUnreadMessagesCount
{
    NSUInteger count = 0;
    for (XMPPClient *client in [PrivateMessagesModel sharedModel].clients)
    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"XMPPUserCoreDataStorageObject"];
        
        NSExpression *keypathExpression = [NSExpression expressionForKeyPath:@"unreadMessages"];
        NSExpression *sumExpression     = [NSExpression expressionForFunction:@"sum:" arguments:@[keypathExpression]];
        
        NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
        [expressionDescription setName:@"sumOfUnreadMessages"];
        [expressionDescription setExpression:sumExpression];
        [expressionDescription setExpressionResultType:NSInteger32AttributeType];
        
        fetchRequest.propertiesToFetch = @[expressionDescription];
        fetchRequest.resultType = NSDictionaryResultType;
        
        NSArray *result = [client.managedObjectContext_roster executeFetchRequest:fetchRequest error:nil];
        
        count += [result.firstObject[@"sumOfUnreadMessages"] integerValue];
    }
    return count;
}

- (void)stopUnreadAnimation
{
//    if (self.imIconImageView.isAnimating)
//    {
//        [self.imIconImageView stopAnimating];
//    }
    self.unreadMessagesBadge.value = @"0";
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (super.fetchedResultsController != nil) {
        return super.fetchedResultsController;
    }
    
    [NSFetchedResultsController deleteCacheWithName:kPostMessagesCache];
    NSManagedObjectContext *context = [WDDDataBase sharedDatabase].managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Post class]) inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    
    //  Sort descriptors
    NSSortDescriptor *sortDescriptorByTime = [[NSSortDescriptor alloc] initWithKey:kPostTimeKey ascending:NO];
    
    
    NSArray *sortDescriptors = @[sortDescriptorByTime];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSPredicate *predicate = [self formPredicate];//[NSPredicate predicateWithFormat:@"SELF.author.isBlocked == %@", @NO];
    [fetchRequest setPredicate:predicate];
    
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:context
                                                                                                  sectionNameKeyPath:nil
                                                                                                           cacheName:kPostMessagesCache];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        DLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return super.fetchedResultsController;
}

- (NSPredicate *)formPredicate
{
    NSPredicate *finalPredicate;
    
    NSPredicate *authorPredicate= [NSPredicate predicateWithFormat:@"SELF.author.isBlocked == %@ AND SELF.group == nil", @NO];
    NSPredicate *groupPredicate = [NSPredicate predicateWithFormat:@"SELF.group.isGroupBlock == %@ AND SELF.group != nil", @NO];
    finalPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[authorPredicate, groupPredicate]];
    
    if (!self.groupIDFilter)
    {
        
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"((SELF.subscribedBy.socialNetwork.isGroupsEnabled == %@ AND SELF.group.type == %@) OR\
                                                                           (SELF.subscribedBy.socialNetwork.isPagesEnabled == %@ AND SELF.group.type == %@) OR\
                                                                           SELF.group == nil) AND (SELF.subscribedBy.socialNetwork.isEventsEnabled == %@ OR SELF.type != %@)",
                                                                          @YES, @(kGroupTypeGroup), @YES, @(kGroupTypePage), @YES, @(kPostTypeEvent)];
        finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[finalPredicate, filterPredicate]];
    }
    
    NSPredicate *socialNetworksPredicate = [self availableNetworksPredicate];
    if (socialNetworksPredicate)
    {
        finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[socialNetworksPredicate, finalPredicate]];
    }
    
    if (self.socialNetworkFilterType)
    {
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"SELF.subscribedBy.socialNetwork.type == %@",self.socialNetworkFilterType];
        finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[filterPredicate, finalPredicate]];
    }
    else if (self.groupIDFilter)
    {
        NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"SELF.group.groupID == %@", self.groupIDFilter];
        finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[filterPredicate, finalPredicate]];
    }
    
    return finalPredicate;
}


#pragma mark - Sliding behavior

- (void)setupSliding
{
    if (![self.slidingViewController.underLeftViewController isKindOfClass:[WDDSideMenuViewController class]])
    {
        WDDSideMenuViewController *sideVC = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDSideMenuScreen];
        sideVC.mainScreenViewController = self;
        self.slidingViewController.underLeftViewController  = sideVC;
    }
    
    if (![self.slidingViewController.underRightViewController isKindOfClass:[UINavigationController class]])
    {
        UINavigationController *navVC = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDReadLaterScreenNavigationViewController];
        WDDReadLaterViewController *readLaterVC = (WDDReadLaterViewController *)[navVC.viewControllers firstObject];
        readLaterVC.mainScreenViewController = self;
        self.slidingViewController.underRightViewController = navVC;
    }
    
    [self.navigationController.view addGestureRecognizer:self.slidingViewController.panGesture];
    [self setAnchorForSlideMenu];
    
    // setup shadow for top view contoller
    self.navigationController.view.layer.shadowOpacity = 0.75f;
    self.navigationController.view.layer.shadowRadius = 10.0f;
    self.navigationController.view.layer.shadowColor = [UIColor blackColor].CGColor;
    
    self.slidingViewController.panGesture.delegate = self;
}

- (void)setupNavigationBarButtons
{
    
    UIImage *hamburgerButtonImage = [UIImage imageNamed:@"MainScreen_hamburger_icon"];
    UIImage *readLaterButtonImage = [UIImage imageNamed:@"MainScreen_readlater_icon"];
    
    UIButton *sideButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *readLaterButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    sideButton.bounds = CGRectMake( 0, 0, hamburgerButtonImage.size.width, hamburgerButtonImage.size.height );
    readLaterButton.bounds = CGRectMake( 0, 0, readLaterButtonImage.size.width, readLaterButtonImage.size.height );
    
    [sideButton setImage:hamburgerButtonImage forState:UIControlStateNormal];
    [readLaterButton setImage:readLaterButtonImage forState:UIControlStateNormal];
    
    [sideButton addTarget:self action:@selector(showSideMenuAction:) forControlEvents:UIControlEventTouchUpInside];
    [readLaterButton addTarget:self action:@selector(showReadLaterAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [menuSideButton setCustomView:sideButton];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:readLaterButton];
}

static const CGFloat kSlideMenuLeftAnchor = 320.0f;
static const CGFloat kSlideMenuRightAnchor = 240.0f;

- (void)setAnchorForSlideMenu
{
    [self.slidingViewController setAnchorLeftRevealAmount:kSlideMenuLeftAnchor];
    [self.slidingViewController setAnchorRightRevealAmount:kSlideMenuRightAnchor];
}

- (void)removeAnchorForSlideMenu
{
    [self.slidingViewController setAnchorLeftRevealAmount:0.0f];
    [self.slidingViewController setAnchorRightRevealAmount:0.0f];
}

- (IBAction)showSideMenuAction:(UIBarButtonItem *)sender
{
    [self.slidingViewController anchorTopViewTo:ECRight];
}

- (void)showReadLaterAction:(UIBarButtonItem *)sender
{
    [self.slidingViewController anchorTopViewTo:ECLeft];
}

- (void)showMainScreenAction:(UIBarButtonItem *)sender
{
    [self.slidingViewController resetTopView];
}

#pragma mark - UIGestureRecognizer

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint currentTouchPoint = [gestureRecognizer locationInView:self.view];
    
    BOOL shouldBegin = NO;
    if  ( (currentTouchPoint.x < 60.0f || currentTouchPoint.x > 260.0f) && self.isAppeared)
    {
        shouldBegin = YES;
    }
    return shouldBegin;
}


#pragma mark - PullTableViewDelegate

- (void)pullTableViewDidTriggerRefresh:(PullTableView *)pullTableView
{
    DLog(@"Refresh posts will be requested");
    if (![SocialNetworkManager sharedManager].isApplicationReady)
    {
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            
            self.postsTable.pullTableIsRefreshing = NO;
        });
        DLog(@"Refresh posts was cancled - application is not ready");
        return;
    }
    

    __weak WDDMainScreenViewController *wSelf = self;
    BOOL updating = [[SocialNetworkManager sharedManager] updatePostsWithComplationBlock:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{

            wSelf.postsTable.pullTableIsRefreshing = NO;
            TF_CHECKPOINT(@"Update using pull to refresh finished");
            DLog(@"Refresh posts finished");
        });
        
    }];
    
    if (updating)
    {
        TF_CHECKPOINT(@"Update using pull to refresh started");
        DLog(@"Update using pull to refresh started");
    }
    
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        self.postsTable.pullTableIsRefreshing = updating;
    });
}

- (void)pullTableViewDidTriggerLoadMore:(PullTableView *)pullTableView
{
    if (![SocialNetworkManager sharedManager].isApplicationReady)
    {
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            self.postsTable.pullTableIsLoadingMore = NO;
        });
        
        return;
    }
    
    NSArray *socialNetworks = nil;
    
    if (self.groupIDFilter)
    {
        NSPredicate *snPreidcate = [NSPredicate predicateWithFormat:@"ANY SELF.groups.groupID == %@", self.groupIDFilter];
        NSFetchRequest *snRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass([SocialNetwork class])];
        snRequest.predicate = snPreidcate;
        
        socialNetworks = [[WDDDataBase sharedDatabase].managedObjectContext executeFetchRequest:snRequest error:nil];
        
        if (!socialNetworks.count)
        {
            self.postsTable.pullTableIsLoadingMore = NO;
            [self performSelector:@selector(refreshLoadActivityIndicator) withObject:nil afterDelay:1.0f];
        }
    }
    else
    {
    
        NSMutableArray *predicates = [[NSMutableArray alloc] init];
        
        for (NSInteger socialNwtworkType = 1; socialNwtworkType <= kSocialNetworkFoursquare; ++socialNwtworkType)
        {
            if ([[WDDDataBase sharedDatabase] activeSocialNetworkOfType:socialNwtworkType])
            {
                NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"SELF.type == %@", @(socialNwtworkType)],
                                                                                              [NSPredicate predicateWithFormat:@"SELF.activeState == %@", @YES]]];
                [predicates addObject:predicate];
            }
        }
        NSPredicate *availableNetworksPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicates];
        
        NSFetchRequest *snRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([SocialNetwork class])];
        
        if (self.socialNetworkFilterType)
        {
            NSPredicate *filterPredicate = [NSPredicate predicateWithFormat:@"SELF.type == %@",self.socialNetworkFilterType];
            snRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[filterPredicate, availableNetworksPredicate]];
        }
        else
        {
            snRequest.predicate = availableNetworksPredicate;
        }
        
        socialNetworks = [[WDDDataBase sharedDatabase].managedObjectContext executeFetchRequest:snRequest error:nil];
    }
    
    NSMutableDictionary *loadMoreInfoDict = [[NSMutableDictionary alloc] init];
    
    for (SocialNetwork *network in socialNetworks)
    {
        NSPredicate *selfPostsPredicate = [NSPredicate predicateWithFormat:@"SELF.subscribedBy.userID == SELF.author.userID AND SELF.subscribedBy.socialNetwork == %@", network];
        NSPredicate *othersPostsPredicate = [NSPredicate predicateWithFormat:@"SELF.subscribedBy.userID != SELF.author.userID AND SELF.subscribedBy.socialNetwork == %@", network];
        NSPredicate *notGroupPostsPredicate = [NSPredicate predicateWithFormat:@"SELF.group == nil AND SELF.subscribedBy.socialNetwork == %@", network];
        
        NSFetchRequest *selfPosts = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Post class])];
        selfPosts.predicate = selfPostsPredicate;
        NSFetchRequest *othersPosts = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Post class])];
        othersPosts.predicate = othersPostsPredicate;
        NSFetchRequest *notGroupPosts = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Post class])];
        notGroupPosts.predicate = notGroupPostsPredicate;
        
        NSInteger countOfSelfPosts = [[WDDDataBase sharedDatabase].managedObjectContext countForFetchRequest:selfPosts error:nil];
        NSInteger countOfOthersPosts = [[WDDDataBase sharedDatabase].managedObjectContext countForFetchRequest:othersPosts error:nil];
        NSInteger countOfNotGroupPosts = [[WDDDataBase sharedDatabase].managedObjectContext countForFetchRequest:notGroupPosts error:nil];
        
        NSFetchRequest *lastPostTimestampRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Post class]) inManagedObjectContext:[WDDDataBase sharedDatabase].managedObjectContext];
        [lastPostTimestampRequest setEntity:entity];
        lastPostTimestampRequest.predicate = [NSPredicate predicateWithFormat:@"SELF.group == nil AND SELF.type != %@ AND SELF.subscribedBy.socialNetwork == %@", @(kPostTypeEvent), network];
        
        lastPostTimestampRequest.fetchLimit = 1;
        lastPostTimestampRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"time" ascending:YES]];
        
//        // Execute the fetch.
        NSError *error = nil;
        NSArray *objects = [[WDDDataBase sharedDatabase].managedObjectContext executeFetchRequest:lastPostTimestampRequest error:&error];
        NSNumber *oldestPostId = [objects.firstObject valueForKey:@"postID"];
        
        NSMutableArray *groupsToLoad = [[NSMutableArray alloc] initWithCapacity:network.groups.count];
        NSSet *groupsToProcess = nil;
        
        if (self.groupIDFilter)
        {
            groupsToProcess = [network.groups filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.groupID == %@", self.groupIDFilter]];
        }
//        else
//        {
//            groupsToProcess = network.groups;
//        }
//        
        for (Group *group in groupsToProcess)
        {
            lastPostTimestampRequest.predicate = [NSPredicate predicateWithFormat:@"SELF.group == %@", group];
            NSError *error = nil;
            NSArray *objects = [[WDDDataBase sharedDatabase].managedObjectContext executeFetchRequest:lastPostTimestampRequest error:&error];
            NSDate *oldestPostTimestamp = [objects.firstObject valueForKey:@"time"];
            
            [groupsToLoad addObject:@{group.groupID : @{kLoadMorePostsGroupCount : @(group.posts.count),
                                                        kLoadMorePostsGroupType : group.type,
                                                        kLoadMorePostsGroupLastPostTimestamp : @([oldestPostTimestamp timeIntervalSince1970])}}];
        }
        
        NSInteger postsToLoad = kCountLoadMorePosts;
        if (network.type.integerValue == kSocialNetworkTwitter)
        {
            postsToLoad *= 2;
        }
        
        NSMutableDictionary *networkInfo = [@{kLoadMorePostsTo : [NSString stringWithFormat:@"%d", postsToLoad],
                                              kLoadMorePostsType : network.type,
                                              kLoadMorePostsSelfCount : @(countOfSelfPosts),
                                              kLoadMorePostsTheirCount : @(countOfOthersPosts),
                                              kLoadMorePostsFrom : @(countOfNotGroupPosts),
                                              kLoadMorePostsGroups : groupsToLoad} mutableCopy];
        
        if (oldestPostId)
        {
            [networkInfo setObject:oldestPostId forKey:kLoadMorePostsLastPostID];
        }
        
        [loadMoreInfoDict setObject:networkInfo forKey:network.profile.userID];
    }
    
    
    __weak WDDMainScreenViewController *wSelf = self;
    BOOL isStarted = [[SocialNetworkManager sharedManager] loadMorePostsFromInfoData:loadMoreInfoDict withComplitionBlock:^{
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            wSelf.postsTable.pullTableIsLoadingMore = NO;
            TF_CHECKPOINT(@"Load more finished");
        });
    }];
    
    if (isStarted)
    {
        TF_CHECKPOINT(@"Load more started");
    }
}

#pragma mark - Refresh and load more methods

- (void)didDownloadPosts
{
    self.postsTable.pullLastRefreshDate = [NSDate date];
    self.postsTable.pullTableIsRefreshing = NO;
    
    self.postsTable.pullTableIsLoadingMore = NO;
    
    [self reloadTableContent];
}

- (void) refreshTable
{
    /*
     
     Code to actually refresh goes here.
     
     */
    self.postsTable.pullLastRefreshDate = [NSDate date];
    self.postsTable.pullTableIsRefreshing = NO;
}

- (void) loadMoreDataToTable
{
    /*
     
     Code to actually load more data goes here.
     
     */
    self.postsTable.pullTableIsLoadingMore = NO;
}

#pragma mark - Methods for overloading in WDDBasePostViewController

- (NSString *)goToCommentsScreenSegueIdentifier
{
    return kStoryboardSegueIDWriteComment;
}

- (NSString *)goToTwitterReplyScreenSegueIdentifier
{
    return kStoryboardSegueIDTwitterReply;
}

static NSString * const kPostCellIdentifier = @"PostCell";
- (NSString *)cellIdentifier
{
    return kPostCellIdentifier;
}

- (void)connectionAllert
{
    [[[UIAlertView alloc] initWithTitle:nil
                                message:NSLocalizedString(@"lskConnectInternet", @"Please connect to the internet")
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"lskOK", @"Ok")
                      otherButtonTitles:nil] show];
    
    [self performSelector:@selector(didDownloadPosts) withObject:nil afterDelay:1.5];
}

#pragma mark - Activity Indicator

- (void) refreshLoadActivityIndicator
{
    WDDAppDelegate* delegate = [[UIApplication sharedApplication] delegate];
    delegate.networkActivityIndicatorCounter++;
    delegate.networkActivityIndicatorCounter--;
}

#pragma mark - UITableViewDelegate protocol implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = [super tableView:tableView numberOfRowsInSection:section];
    self.emptyGroupLabel.hidden = !(!count && self.groupIDFilter);
    
    return count;
}

#pragma mark - Storyboard
#pragma mark

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:kStoryboardSegueIDStatusScreen])
    {
        self.fetchedResultsController.delegate = nil;
    }
}

@end
