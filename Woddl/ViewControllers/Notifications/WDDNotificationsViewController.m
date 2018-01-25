//
//  WDDNotificationsViewController.m
//  Woddl
//

#import "WDDNotificationsViewController.h"
#import "WDDNotificationCell.h"
#import <WYPopoverController/WYPopoverController.h>
#import "WYPopoverController+WDDNotifications.h"
#import "WDDDataBase.h"
#import "WDDNotificationsManager.h"
#import "WDDWriteCommetViewController.h"
#import "WDDPhotoPreviewControllerViewController.h"
#import "WDDWebViewController.h"

#import "Notification.h"
#import "Media.h"

#define POPOVER_LEFT_OFFSET         10.0f
#define POPOVER_RIGHT_OFFSET        10.0f
#define POPOVER_TOP_OFFSET          20.0f
#define POPOVER_BOTTOM_OFFSET       0.0f

#define TOP_BAR_HEIGHT              64.0f

#define ESTIMATED_ROW_HEIGHT        60.0f

#define SEPARATOR_MAX_HEIGHT        2.0f

#define NOTIFICATIONS_BLUE_COLOR    [UIColor colorWithRed:0.28 green:0.65 blue:0.86 alpha:1]
#define NOTIFICATIONS_GRAY_COLOR    [UIColor colorWithRed:0.14 green:0.14 blue:0.14 alpha:1]

@interface WDDNotificationsViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, WYPopoverControllerDelegate>
{
    id previousNotificationsFRCDelegate;
}

@property (nonatomic, weak) UIViewController *parentVC;
@property (nonatomic, strong) NSFetchedResultsController *notificationsFRC;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) WDDNotificationCell *cell;
@property (nonatomic, strong) NSMutableIndexSet *expandedCells;

@end

@implementation WDDNotificationsViewController

#pragma mark - appearance & presentation

+ (void)showOnViewController:(UIViewController*)parentVC
{
    WDDNotificationsViewController *notificationsViewController
    = [parentVC.storyboard instantiateViewControllerWithIdentifier:NSStringFromClass(self)];
    notificationsViewController.parentVC = parentVC;
    
    WYPopoverController *popoverController = [[WYPopoverController alloc] initWithContentViewController:notificationsViewController];
    parentVC.notificationsPopover = popoverController;
    
    popoverController.theme.innerCornerRadius   = 0.0f;
    popoverController.theme.outerCornerRadius   = 0.0f;
    popoverController.theme.viewContentInsets   = UIEdgeInsetsZero;
    popoverController.theme.borderWidth         = 3.0f;
    popoverController.theme.arrowBase           = 24.0f;
    popoverController.theme.arrowHeight         = 14.0f;
    popoverController.theme.arrowBaseOffset     = 22.0f;
    popoverController.theme.arrowHeightOffset   = 10.0f;
    popoverController.theme.outerStrokeColor    = NOTIFICATIONS_GRAY_COLOR;
    popoverController.theme.strokeWidth         = 1.25f;
    popoverController.theme.fillTopColor        = [UIColor whiteColor];
    popoverController.theme.fillBottomColor     = [UIColor whiteColor];
    
    popoverController.delegate                  = notificationsViewController;
    
    CGRect frame = parentVC.navigationItem.titleView.frame;
    frame.size.height = frame.size.height - NOTIFICATIONS_BADGE_HEIGHT / 2 + 1;
    [popoverController presentPopoverFromRect:frame
                                       inView:parentVC.navigationItem.titleView.superview
                     permittedArrowDirections:WYPopoverArrowDirectionUp
                                     animated:YES];
}

// iOS 6
- (CGSize)contentSizeForViewInPopover
{
    return [self preferredContentSize];
}

- (CGSize)preferredContentSize
{
    UIView *keyboardView = APP_DELEGATE.keyboardView;
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    return CGSizeMake(screenSize.width - POPOVER_LEFT_OFFSET - POPOVER_RIGHT_OFFSET,
                      screenSize.height - keyboardView.frame.size.height - POPOVER_TOP_OFFSET + NOTIFICATIONS_BADGE_HEIGHT / 2 - 1 - POPOVER_BOTTOM_OFFSET - TOP_BAR_HEIGHT);
}

#pragma mark - lifecycle

- (void)dealloc
{
    self.notificationsFRC.delegate = previousNotificationsFRCDelegate;
    [self.notificationsFRC performFetch:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[WDDNotificationsManager sharedManager] fetchNotifications];
    
    self.notificationsFRC = [[WDDNotificationsManager sharedManager] notificationsFRC];
    previousNotificationsFRCDelegate = self.notificationsFRC.delegate;
    self.notificationsFRC.delegate = self;
    [self.notificationsFRC performFetch:nil];
    
    self.expandedCells = [[NSMutableIndexSet alloc] init];
    
    for (Notification * notification in self.notificationsFRC.fetchedObjects)
    {
        if (notification.isUnread)
        {
            [notification markAsRead];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Heatmaps trackScreenWithKey:@"503395516a70d21a-3e0de1b2"];
}

#pragma mark - UITableViewDatasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.notificationsFRC.fetchedObjects.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WDDNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([WDDNotificationCell class])
                                                                forIndexPath:indexPath];

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ESTIMATED_ROW_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.cell)
    {
        self.cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([WDDNotificationCell class])];
    }
    [self configureCell:self.cell atIndexPath:indexPath];
    return [self.cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + SEPARATOR_MAX_HEIGHT;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if (![self.expandedCells containsIndex:[indexPath row]])
//    {
//        [self.expandedCells addIndex:[indexPath row]];
//        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//    }
//    else
//    {
//        [self.expandedCells removeIndex:[indexPath row]];
//        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
//    }
    Notification * notification = [self.notificationsFRC.fetchedObjects objectAtIndex:[indexPath row]];
    
    UIViewController *viewControllerToPresent;
    NSURL *url;
    SocialNetwork *socialNetwork;;
    
    if (notification.post)
    {
        UINavigationController *navigationController
        = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDWriteCommentNavigationViewController];
        
        ((WDDWriteCommetViewController*)[navigationController viewControllers][0]).post = notification.post;
        
        viewControllerToPresent = navigationController;
    }
    else if ([notification.externalObjectType isEqualToString:@"event"] && notification.socialNetwork.type.integerValue == kSocialNetworkFacebook)
    {
        url = [NSURL URLWithString:notification.externalURL];
        socialNetwork = notification.socialNetwork;
    }
    else if (notification.group)
    {
        url = [NSURL URLWithString:notification.group.groupURL];
        socialNetwork = notification.socialNetwork;
    }
    else if (notification.media)
    {
        viewControllerToPresent
        = [[WDDPhotoPreviewControllerViewController alloc] initWithImageURL:[NSURL URLWithString:notification.media.mediaURLString]
                                                                 previewURL:[NSURL URLWithString:notification.media.previewURLString]];
    }
    else if (notification.externalURL && notification.socialNetwork.type.integerValue == kSocialNetworkTwitter)
        // this may be twitter list, so it's displaying priority is more that displaying actor user profile
    {
        url = [NSURL URLWithString:notification.externalURL];
    }
    else if (notification.sender)
    {
        url = [NSURL URLWithString:notification.sender.profileURL];
        socialNetwork = notification.socialNetwork;
    }
    else if (notification.externalURL)
    {
        url = [NSURL URLWithString:notification.externalURL];
    }

    
    if (url)
    {
        if (!url.scheme.length)
        {
            url = [NSURL URLWithString:[@"https://" stringByAppendingString:[url absoluteString]]];
        }
        
        WDDWebViewController *webController = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDWebViewViewController];
        webController.url = url;
        webController.sourceNetwork = socialNetwork;
        webController.requireAuthorization = YES;
        viewControllerToPresent = [[UINavigationController alloc] initWithRootViewController:webController];
    }
    
    if (viewControllerToPresent)
    {
        UIViewController *parentVC = self.parentVC;
        [parentVC.notificationsPopover dismissPopoverAnimated:YES completion:^()
        {
            [parentVC presentViewController:viewControllerToPresent animated:YES completion:nil];
        }];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(WDDNotificationCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    Notification *notification = self.notificationsFRC.fetchedObjects[indexPath.row];
    if (notification.isUnread.boolValue)
    {
        [notification markAsRead];
        [cell blinkUnreadShield];
    }
}

#pragma mark - Fetched results controller

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[newIndexPath]
                                   withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[indexPath]
                                   withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                   withRowAnimation:UITableViewRowAnimationNone];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNotificationsDidUpdate object:nil];
}

#pragma mark - auxiliary

- (void)configureCell:(WDDNotificationCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    [cell setNotification:self.notificationsFRC.fetchedObjects[indexPath.row]];
    cell.expanded = [self.expandedCells containsIndex:[indexPath row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)popoverController
{
    self.parentVC.notificationsPopover = nil;
}


@end
