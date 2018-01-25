//
//  WDDSideMenuViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "WDDAppDelegate.h"
#import "WDDSideMenuViewController.h"
#import "WDDSNSettingsViewController.h"
#import "WDDWebViewController.h"
#import "PrivateMessagesModel.h"
#import "WDDDataBase.h"
#import "SocialNetwork.h"
#import "FacebookSN.h"
#import "SocialNetworkManager.h"
#import "WDDSocialNetworkCell.h"
#import "UIImageView+WebCache.h"
#import "WDDSwitchButton.h"
#import "WDDSAddSocialNetworkViewController.h"
#import "WDDNotificationsManager.h"

#import "FacebookRequest.h"

#import "SAMHUDView.h"
#import "UIImageView+AvatarLoading.h"

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import "UIImage+ResizeAdditions.h"
#import "UIView+ScrollToTopDisabler.h"

#import <Parse/Parse.h>

#import "WDDLoginViewController.h"

//static NSString * const kStateChecked       = @"Sidebar_account_enabled";
//static NSString * const kStateUnchecked     = @"Sidebar_account_disabled";

static NSString * const kSocialNetworkListCache         = @"SocialNetworkKeys";
static NSString * const kSocialNetworkCellIdentifier    = @"SNCell";
static NSString * const kSocialNetworkNameKeyPath       = @"socialNetwork.displayName";
static NSString * const kSocialNetworkTypeKeyPath       = @"socialNetwork.type";
static NSString * const kSocialNetworkField             = @"socialNetwork";

static CGFloat const kSectionHeight = 45.0f;
static const NSInteger kMaxEventToShow = 10;

static const NSInteger tagOptionsActionSheet = 1024;
static const NSInteger tagAccountActionSheet = 2048;

@interface WDDSideMenuViewController ()<MFMailComposeViewControllerDelegate, UIAlertViewDelegate, WDDSocialNetworkCellDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UITableView *socialNetworksTable;

@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;
@property (strong, nonatomic) NSIndexPath *socialNetworkSettingsIndexPath;
@property (strong, nonatomic) NSIndexPath *showingGroupsCellIndexPath;
@property (assign, nonatomic) NSInteger showingGroupsExpandedSections;

@property (strong, nonatomic) SAMHUDView *progressHUD;

@property (assign, nonatomic, getter = isReloadNeeded) BOOL reloadNeeded;
@end


@implementation WDDSideMenuViewController

#pragma mark - View Controller lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (IS_IOS7)
    {
        self.socialNetworksTable.contentInset = UIEdgeInsetsMake(20.0f, 0.0f, 0.0f, 0.0f);
        [self setupBlackStatusBarBackgroung];
    }
    self.socialNetworksTable.scrollsToTop = YES;
    
    UIImageView *woddlImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Sidebar_woddl_header"]];
    UIImageView *woddlLogoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MainScreen_nav_bar_logo"]];
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.socialNetworksTable.bounds.size.width, woddlImageView.bounds.size.height)];
    UILabel *headerLabel = [UILabel new];
    
    [tableHeaderView addSubview:woddlImageView];
    [tableHeaderView addSubview:woddlLogoImageView];
    [tableHeaderView addSubview:headerLabel];
    
    woddlLogoImageView.frame = (CGRect){CGPointZero, CGSizeMake(22.f, 22.f)};
    woddlLogoImageView.center = CGPointMake(15.f + CGRectGetWidth(woddlLogoImageView.frame) / 2.f, CGRectGetHeight(tableHeaderView.frame) / 2.f);
    headerLabel.frame = (CGRect){CGPointZero, CGSizeMake(CGRectGetWidth(woddlImageView.frame) - 15.f, CGRectGetHeight(woddlImageView.frame))};
    headerLabel.center = CGPointMake(55.f + CGRectGetWidth(headerLabel.frame) / 2.f, CGRectGetHeight(tableHeaderView.frame) / 2.f);
    
    [headerLabel setTextColor:[UIColor whiteColor]];
    [headerLabel setBackgroundColor:[UIColor clearColor]];
    [headerLabel setFont:[UIFont systemFontOfSize:19]];
    
    headerLabel.text = NSLocalizedString(@"lskSelectedFeedsText", @"View Selected Feeds");

    tableHeaderView.tag = kSocialNetworkUnknown;
    self.socialNetworksTable.tableHeaderView = tableHeaderView;
    
    [self setupFilterRecognizer:tableHeaderView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.socialNetworksTable reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Heatmaps trackScreenWithKey:@"503395516a70d21a-09c09a26"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.isReloadNeeded)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationRefetchMainSreenTable object:nil];
        self.reloadNeeded = NO;
    }
}

- (void)setupBlackStatusBarBackgroung
{
    UIView *statusBarBackground = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, 360.f, 20.f)];
    statusBarBackground.backgroundColor = [UIColor blackColor];
    [self.view addSubview:statusBarBackground];
}

- (void)setupFilterRecognizer:(UIView *)view
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeFilterType:)];
    view.gestureRecognizers = ( view.gestureRecognizers ? [view.gestureRecognizers arrayByAddingObject:tap] : @[tap] );
}

#pragma mark - Buttons actions

-(IBAction)reportBugPressed:(id)sender
{
    if ([MFMailComposeViewController canSendMail])
    {
        
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        
        
#if IS_LOGGING_TO_FILE == 1
        [mailViewController setToRecipients:@[@"oleg.komaristov@gmail.com"]];
        [mailViewController setSubject:@"Woddl log"];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:@"logfile.txt"];
        NSData *noteData = [NSData dataWithContentsOfFile:path];
        
        [mailViewController addAttachmentData:noteData mimeType:@"text/plain" fileName:@"logfile.txt"];
#else
        [mailViewController setToRecipients:@[kBugReportEmail]];
        [mailViewController setSubject:@"Report Bug"];
        [mailViewController setMessageBody:@"" isHTML:NO];
#endif
        
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
    
    else {
        
        DLog(@"Device is unable to send email in its current state");
        
    }
}

-(IBAction)gotFeedback:(id)sender
{
    if ([MFMailComposeViewController canSendMail])
    {
        
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        
        [mailViewController setToRecipients:@[kBugReportEmail]];
        [mailViewController setSubject:@"Got Feedback"];
        [mailViewController setMessageBody:@"" isHTML:NO];
        
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
    
    else {
        
        DLog(@"Device is unable to send email in its current state");
        
    }
}

- (IBAction)logoutButtonAction:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:NSLocalizedString(@"lskExistWarning", @"Logout message")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"lskCancel", @"Logout message")
                                          otherButtonTitles:NSLocalizedString(@"lskOK", @"Logout message"),nil];
    alert.tag = 0xFFFE;
    [alert show];
}

typedef enum tagMenuButtons
{
    MBAddNetwork,
    MBRecommendWoddlInFB,
    MBFeedback,
    MBReportBug,
    MBLogout
    
} MenuButtons;

- (IBAction)optionsButtonAction:(id)sender
{
    UIActionSheet *menuActionSheet = nil;
    
    NSArray *fbAccounts = [[WDDDataBase sharedDatabase] fetchSocialNetworksAscendingWithType:kSocialNetworkFacebook];

    if (fbAccounts.count)
    {
        menuActionSheet = [[UIActionSheet alloc] initWithTitle:@"Options"
                                                                     delegate:self
                                                            cancelButtonTitle:NSLocalizedString(@"lskCancel", @"")
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:NSLocalizedString(@"lskAddNetwork", @"Add network buton in menu"),
                                          NSLocalizedString(@"lskRecommendWODDLFB", @"Recommend WODDL in FB menu button"),
                                          NSLocalizedString(@"lskFeedback", @"Feedback button in menu"),
                                          NSLocalizedString(@"lskReportABug", @"Report a Bug button in menu"),
                                          NSLocalizedString(@"lskLogout", @""), nil];
        menuActionSheet.destructiveButtonIndex = 4;
    }
    else
    {
        menuActionSheet = [[UIActionSheet alloc] initWithTitle:@"Options"
                                                      delegate:self
                                             cancelButtonTitle:NSLocalizedString(@"lskCancel", @"")
                                        destructiveButtonTitle:nil
                                             otherButtonTitles:NSLocalizedString(@"lskAddNetwork", @"Add network buton in menu"),
                           NSLocalizedString(@"lskFeedback", @"Feedback button in menu"),
                           NSLocalizedString(@"lskReportABug", @"Report a Bug button in menu"),
                           NSLocalizedString(@"lskLogout", @""), nil];
        menuActionSheet.destructiveButtonIndex = 3;
    }
    menuActionSheet.tag = tagOptionsActionSheet;
    
    [menuActionSheet showInView:self.view];
}

- (void)postRecomendationToFB
{
    NSArray *fbAccounts = [[WDDDataBase sharedDatabase] fetchSocialNetworksAscendingWithType:kSocialNetworkFacebook];

    if (fbAccounts.count > 1)
    {
        UIActionSheet *accountSelector = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"lskSelectAccount", @"")
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:nil];
        for (SocialNetwork *network in fbAccounts)
        {
            [accountSelector addButtonWithTitle:network.displayName];
        }
        [accountSelector addButtonWithTitle:NSLocalizedString(@"lskCancel", @"")];
        accountSelector.cancelButtonIndex = fbAccounts.count;
        accountSelector.tag = tagAccountActionSheet;
        
        [accountSelector showInView:self.view];
    }
    else
    {
        [self postRecomendationToFBWithSN:fbAccounts.firstObject];
    }
    
}

- (void)postRecomendationToFBWithSN:(SocialNetwork *)socialNetwork
{
    NSString *accessToken = [socialNetwork accessToken];
    
    self.progressHUD = [[SAMHUDView alloc] initWithTitle:NSLocalizedString(@"lskProcessing", @"Processing...")];
    [self.progressHUD show];
    
    __weak WDDSideMenuViewController *w_self = self;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        FacebookRequest *request = [FacebookRequest new];
        BOOL isSuccess = [request addPostToWallWithToken:accessToken
                                              andMessage:@"Check out this awesome new iPhone app called WODDL - It connects all of your Social Networks in one united timeline - For FREE!"
                                                 andLink:kLinkToWoddlOnAppStore
                                                 andName:nil
                                         withDescription:nil
                                             andImageURL:nil
                                           toGroupWithID:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (isSuccess)
            {
                [w_self.progressHUD completeAndDismissWithTitle:NSLocalizedString(@"lskSuccess", @"")];
            }
            else
            {
                [w_self.progressHUD failAndDismissWithTitle:NSLocalizedString(@"lskFail", @"")];
            }
            
            self.progressHUD = nil;
        });
        
    });
}

#pragma mark - UIActionSheetDelegate protocol implementation

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == tagOptionsActionSheet)
    {
        if (actionSheet.destructiveButtonIndex != MBLogout && buttonIndex > MBAddNetwork)
        {
            --buttonIndex;
        }
        
        switch (buttonIndex)
        {
            case MBAddNetwork:
                [self performSegueWithIdentifier:kStoryboardIDAddNetworkNavigationViewController sender:self];
            break;
                
            case MBRecommendWoddlInFB:
                [self postRecomendationToFB];
            break;
                
            case MBFeedback:
                [self gotFeedback:self];
            break;
                
            case MBReportBug:
                [self reportBugPressed:self];
            break;
                
            case MBLogout:
                [self logoutButtonAction:self];
            break;
        }
    }
    else if (actionSheet.tag == tagAccountActionSheet && actionSheet.cancelButtonIndex != buttonIndex)
    {
        NSArray *fbAccounts = [[WDDDataBase sharedDatabase] fetchSocialNetworksAscendingWithType:kSocialNetworkFacebook];
        
        if (fbAccounts.count > buttonIndex && fbAccounts.count > 0)
        {
            SocialNetwork *socialNetwork = fbAccounts[buttonIndex];
            [self postRecomendationToFBWithSN:socialNetwork];
        }
    }
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kSectionHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static const CGFloat labelLeftOffset = 55.f;
    
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.socialNetworksTable.frame.size.width, kSectionHeight)];
    SocialNetworkType sectionType = [[[self.fetchedResultsController sections][section] name]integerValue];
    sectionView.tag = sectionType;
    
    UIImageView *socialNetworkImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[self imageNameForSection:sectionType]]];
    [sectionView addSubview:socialNetworkImage];
    
    UILabel *networkName = [[UILabel alloc] initWithFrame:CGRectMake(labelLeftOffset, 0.f, CGRectGetWidth(tableView.frame), CGRectGetHeight(sectionView.frame))];
    networkName.backgroundColor = [UIColor clearColor];
    networkName.textColor = [UIColor whiteColor];
    networkName.font = [UIFont systemFontOfSize:19.f];
    networkName.text = [self socialNetwork:sectionType];
    [sectionView addSubview:networkName];

    WDDSwitchButton *networkSwitcher = [[WDDSwitchButton alloc] initWithFrame:(CGRect){CGPointZero, CGSizeMake(65.f, kSectionHeight)}];
    networkSwitcher.center = CGPointMake(CGRectGetWidth(tableView.frame) - CGRectGetWidth(networkSwitcher.frame) / 2.f - 82.f, CGRectGetHeight(sectionView.frame) / 2.f);
    networkSwitcher.tag = sectionType;
    networkSwitcher.on = [[WDDDataBase sharedDatabase] activeSocialNetworkOfType:sectionType];
    [networkSwitcher addTarget:self action:@selector(socialNetworkActivityChange:) forControlEvents:UIControlEventValueChanged];
    [sectionView addSubview:networkSwitcher];
    
    [self setupFilterRecognizer:sectionView];
    
    return sectionView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    //return 100;
     //I comment
    UserProfile *profile = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSSortDescriptor *sortByNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    
    NSPredicate *groupPredicate = [NSPredicate predicateWithFormat:@"SELF.type == %@", @(kGroupTypeGroup)];
    NSPredicate *pagesPredicate = [NSPredicate predicateWithFormat:@"SELF.type == %@", @(kGroupTypePage)];
    NSSet *groups = [profile.socialNetwork.groups filteredSetUsingPredicate:groupPredicate];
    NSSet *pages = [profile.socialNetwork.groups filteredSetUsingPredicate:pagesPredicate];
    NSArray *events = [profile.socialNetwork getSavedEvents];
    if (events.count > kMaxEventToShow)
    {
        events = [events subarrayWithRange:NSMakeRange(0, kMaxEventToShow)];
    }
    
    NSInteger expandedGroups = ( [indexPath isEqual:self.showingGroupsCellIndexPath] ? self.showingGroupsExpandedSections : kGroupTableNone );
   
    return [WDDSocialNetworkCell calculateCellHeightForEvents:events
                                                       groups:[[groups allObjects] sortedArrayUsingDescriptors:@[sortByNameDescriptor]]
                                                        pages:[[pages allObjects] sortedArrayUsingDescriptors:@[sortByNameDescriptor]]
                                         withExpandedSections:expandedGroups];
     
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WDDSocialNetworkCell *cell = [tableView dequeueReusableCellWithIdentifier:kSocialNetworkCellIdentifier forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
            DLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    [NSFetchedResultsController deleteCacheWithName:kSocialNetworkListCache];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
     NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([UserProfile class]) inManagedObjectContext:[WDDDataBase sharedDatabase].managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    
    //  Sort descriptors
    NSSortDescriptor *sortDescriptorByName = [[NSSortDescriptor alloc] initWithKey:kSocialNetworkNameKeyPath ascending:YES];
    NSSortDescriptor *sortDescriptorByType = [[NSSortDescriptor alloc] initWithKey:kSocialNetworkTypeKeyPath ascending:YES];
    
    NSArray *sortDescriptors = @[sortDescriptorByType, sortDescriptorByName];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    //  Predicate
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.%@ != NULL", kSocialNetworkField];
    fetchRequest.predicate = predicate;
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[WDDDataBase sharedDatabase].managedObjectContext sectionNameKeyPath:kSocialNetworkTypeKeyPath cacheName:kSocialNetworkListCache];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        DLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.socialNetworksTable beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.socialNetworksTable insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.socialNetworksTable deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.socialNetworksTable;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.socialNetworksTable endUpdates];
}

#pragma mark - Configure cell

- (void)configureCell:(WDDSocialNetworkCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    UserProfile *profile = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSSortDescriptor *sortByNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    
    NSPredicate *groupPredicate = [NSPredicate predicateWithFormat:@"SELF.type == %@", @(kGroupTypeGroup)];
    NSPredicate *pagesPredicate = [NSPredicate predicateWithFormat:@"SELF.type == %@", @(kGroupTypePage)];
    NSSet *groups = [profile.socialNetwork.groups filteredSetUsingPredicate:groupPredicate];
    NSSet *pages = [profile.socialNetwork.groups filteredSetUsingPredicate:pagesPredicate];
    NSArray *events = [profile.socialNetwork getSavedEvents]; //I comment
    if (events.count > kMaxEventToShow)
    {
        events = [events subarrayWithRange:NSMakeRange(0, kMaxEventToShow)];
    }
    
    NSInteger expandedGroups = ( [indexPath isEqual:self.showingGroupsCellIndexPath] ? self.showingGroupsExpandedSections : kGroupTableNone );
    
    SocialNetwork *socialNetwork = profile.socialNetwork;
    NSArray *statusesArray = @[@(socialNetwork.isEventsEnabled.boolValue),
                               @(socialNetwork.isGroupsEnabled.boolValue),
                               @(socialNetwork.isPagesEnabled.boolValue)];

    [cell       setEvents:events //I comment
                   groups:[[groups allObjects] sortedArrayUsingDescriptors:@[sortByNameDescriptor]]
                    pages:[[pages allObjects] sortedArrayUsingDescriptors:@[sortByNameDescriptor]]
         expandedSections:expandedGroups
           sectionsStates:statusesArray];
    
    cell.stateButton.selected = ([profile.socialNetwork.activeState boolValue] && profile.socialNetwork.accessToken != nil);
    
    NSString *imageName = (profile.socialNetwork.accessToken == nil) ? @"Sidebar_account_unavailable.png" : @"Sidebar_account_disabled.png";
    [cell.stateButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    
    cell.displayName.text = profile.socialNetwork.displayName;
    [self  setupAvatarImageInCell:cell forSocialNetwork:profile.socialNetwork];    
    cell.delegate = self;
    
    cell.avatarImage.layer.masksToBounds = YES;
    [cell.avatarImage.layer setCornerRadius:5.0f];
}

- (void)setupAvatarImageInCell:(WDDSocialNetworkCell *)cell forSocialNetwork:(SocialNetwork *)socialNetwork
{
    NSURL *avatarURL = [NSURL URLWithString:socialNetwork.profile.avatarRemoteURL];
    DLog(@"setting up avatar image in cell for social network %@ %@ with avatarURL %@", SOCIAL_NETWORK_CLASSNAME_FROM_ENUM(socialNetwork.type.integerValue), socialNetwork.displayName, avatarURL);
    [cell.avatarImage setAvatarWithURL:avatarURL];
    [cell.avatarImage setUserInteractionEnabled:YES];
    [cell.avatarImage addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAuthorProfile:)]];
    
}

#pragma mark - helper methods

- (NSString *)imageNameForSection:(SocialNetworkType)section
{
    NSString *imageName;
    
    switch (section)
    {
        case kSocialNetworkFacebook:
            imageName = @"Sidebar_facebook_section";
            break;
            
        case kSocialNetworkTwitter:
            imageName = @"Sidebar_twitter_section";
            break;
            
        case kSocialNetworkGooglePlus:
            imageName = @"Sidebar_GooglePlus_section";
            break;
            
        case kSocialNetworkFoursquare:
            imageName = @"Sidebar_foursquare_section";
            break;
            
        case kSocialNetworkInstagram:
            imageName = @"Sidebar_Instagram_section";
            break;
            
        case kSocialNetworkLinkedIN:
            imageName = @"Sidebar_linkedin_section";
            break;
            
        case kSocialNetworkUnknown:
            imageName = @"Sidebar_Placeholder_section";
            break;
    }
    
    return imageName;
}

- (NSString *)socialNetwork:(SocialNetworkType)section
{
    NSString *result;
    
    switch (section)
    {
        case kSocialNetworkFacebook:
            result = NSLocalizedString(@"Facebook", @"");
            break;
            
        case kSocialNetworkTwitter:
            result = NSLocalizedString(@"Twitter", @"");
            break;
            
        case kSocialNetworkGooglePlus:
            result = NSLocalizedString(@"Google Plus", @"");
            break;
            
        case kSocialNetworkFoursquare:
            result = NSLocalizedString(@"Foursquare", @"");
            break;
            
        case kSocialNetworkInstagram:
            result = NSLocalizedString(@"Instagram", @"");
            break;
            
        case kSocialNetworkLinkedIN:
            result = NSLocalizedString(@"LinkedIn", @"");
            break;
            
        case kSocialNetworkUnknown:
            result = NSLocalizedString(@"lskUnknown", @"");
            break;
    }
    
    return result;
}

#pragma mark - storyboard navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kStoryboardSegueIDSNSettings])
    {
        UINavigationController *navigationVCSettings = (UINavigationController *)segue.destinationViewController;
        WDDSNSettingsViewController *settingsVC = [[navigationVCSettings viewControllers] firstObject];

        UserProfile *selectedProfile = [self.fetchedResultsController objectAtIndexPath:self.socialNetworkSettingsIndexPath];
        settingsVC.socialNetwork = selectedProfile.socialNetwork;
    }
}


- (IBAction)backFromProfileSettingsScreen:(UIStoryboardSegue *)unwindSegue
{
    if  ([unwindSegue.identifier isEqualToString:kStoryboardSegueIDUnwindBackFromSettingsSegue])
    {
        [self.socialNetworksTable reloadData];
        self.socialNetworkSettingsIndexPath = nil;
    }
}

#pragma mark - Delegate

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult: (MFMailComposeResult)result error: (NSError*)error {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WDDSocialNetworkCellDelegate protocol implementation

- (void)settingsButtonPressedForCell:(WDDSocialNetworkCell *)cell
{
    self.socialNetworkSettingsIndexPath = [self.socialNetworksTable indexPathForCell:cell];
    [self performSegueWithIdentifier:kStoryboardSegueIDSNSettings sender:self];
}

- (void)accountStatusChangesForCell:(WDDSocialNetworkCell *)cell
{
    NSIndexPath *cellIndexPath = [self.socialNetworksTable indexPathForCell:cell];
    UserProfile *selectedProfile = [self.fetchedResultsController objectAtIndexPath:cellIndexPath];
    
    if (!selectedProfile.socialNetwork.accessToken.length)
    {
        UIAlertView *needReloginAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"lskLogin", @"")
                                                                   message:[NSString stringWithFormat:NSLocalizedString(@"lskLoginToAccountMessage", @"Login to account alert"), selectedProfile.name]
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"lskCancel", @"")
                                                         otherButtonTitles:NSLocalizedString(@"lskLogin", @""), nil];
        needReloginAlert.tag = [self tagForIndexPath:cellIndexPath];
        [needReloginAlert show];
    }
    else
    {
        BOOL newState = ![selectedProfile.socialNetwork.activeState boolValue];
        cell.stateButton.selected = newState;
        selectedProfile.socialNetwork.activeState = [NSNumber numberWithBool:newState];
        [[WDDDataBase sharedDatabase] save];
    
        self.reloadNeeded = YES;
    }
}

- (void)expandEventsForCell:(WDDSocialNetworkCell *)cell
{
    [self expandCell:cell withExpandType:kGroupTableEvents];
}

- (void)expandGroupsForCell:(WDDSocialNetworkCell *)cell
{
    [self expandCell:cell withExpandType:kGroupTableGroups];
}

- (void)expandPagesForCell:(WDDSocialNetworkCell *)cell
{
    [self expandCell:cell withExpandType:kGroupTablePages];
}

- (void)expandCell:(WDDSocialNetworkCell *)cell withExpandType:(GroupTableMasks)type
{
    NSIndexPath *indexPath = [self.socialNetworksTable indexPathForCell:cell];
    NSMutableArray *reloadIndexPaths = [[NSMutableArray alloc] initWithCapacity:2];
    if (self.showingGroupsCellIndexPath)
    {
        [reloadIndexPaths addObject:self.showingGroupsCellIndexPath];
    }
    
    if ([indexPath isEqual:self.showingGroupsCellIndexPath])
    {
        if (self.showingGroupsExpandedSections & type)
        {
            NSInteger reversed = ~type;
            self.showingGroupsExpandedSections = self.showingGroupsExpandedSections & reversed;
        }
        else
        {
            self.showingGroupsExpandedSections = self.showingGroupsExpandedSections | type;
        }
    }
    else
    {
        self.showingGroupsExpandedSections = type;
        self.showingGroupsCellIndexPath = indexPath;
        [reloadIndexPaths addObject:indexPath];
    }
    
    [self.socialNetworksTable beginUpdates];
    [self.socialNetworksTable reloadRowsAtIndexPaths:reloadIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.socialNetworksTable endUpdates];
}

- (void)showEventInformationForCell:(WDDSocialNetworkCell *)cell withEvent:(Post *)event
{
    NSURL *eventURL = [NSURL URLWithString:event.linkURLString];
    SocialNetwork *sourceNetwork = event.subscribedBy.socialNetwork;
    
    [self openWebViewWithURL:eventURL
              socialNetowork:sourceNetwork
        requireAuthorization:YES];
}

- (void)filterWithGroup:(Group *)group
{
    if (!group)
    {
        self.mainScreenViewController.groupIDFilter = group.groupID;
        return;
    }
    
    WDDWebViewController *webController = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDWebViewViewController];
    webController.requireAuthorization = YES;
    webController.sourceNetwork = [group.members anyObject];
    webController.url = [NSURL URLWithString:group.groupURL];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:webController];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)didChangeStateForEvents:(BOOL)state inCell:(WDDSocialNetworkCell *)cell
{
    UserProfile *profile = [self.fetchedResultsController objectAtIndexPath:[self.socialNetworksTable indexPathForCell:cell]];
    profile.socialNetwork.isEventsEnabled = @(state);
    [[WDDDataBase sharedDatabase] save];
    self.reloadNeeded = YES;
}

- (void)didChangeStateForGroups:(BOOL)state inCell:(WDDSocialNetworkCell *)cell
{
    UserProfile *profile = [self.fetchedResultsController objectAtIndexPath:[self.socialNetworksTable indexPathForCell:cell]];
    profile.socialNetwork.isGroupsEnabled = @(state);
    [[WDDDataBase sharedDatabase] save];
    self.reloadNeeded = YES;
}

- (void)didChangeStateForPages:(BOOL)state inCell:(WDDSocialNetworkCell *)cell
{
    UserProfile *profile = [self.fetchedResultsController objectAtIndexPath:[self.socialNetworksTable indexPathForCell:cell]];
    profile.socialNetwork.isPagesEnabled = @(state);
    [[WDDDataBase sharedDatabase] save];
    self.reloadNeeded = YES;
}

#pragma mark - SN activity changes processing

- (void)socialNetworkActivityChange:(UISwitch *)sender
{
    [[WDDDataBase sharedDatabase] setSocialNetworkOfType:sender.tag active:sender.isOn];
    self.reloadNeeded = YES;
}

- (void)changeFilterType:(UITapGestureRecognizer *)gestureRecognizer
{
    UIView *view = gestureRecognizer.view;
    if  (view.tag != kSocialNetworkUnknown)
    {
        self.mainScreenViewController.socialNetworkFilterType = @(view.tag);
    }
    else
    {
        self.mainScreenViewController.socialNetworkFilterType = nil;
    }
}

#pragma mark - Show author profile

- (void)showAuthorProfile:(UITapGestureRecognizer *)sender
{
    id cell = [[[sender.view superview] superview] superview];
    
    if (IS_IOS7)
    {
        cell = [cell superview];
    }
    
    if ([cell isKindOfClass:[WDDSocialNetworkCell class]])
    {
        NSIndexPath *indexPath = [self.socialNetworksTable indexPathForCell:cell];
        UserProfile *userProfile = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        NSURL *profileURL = [NSURL URLWithString:userProfile.profileURL];
        SocialNetwork *sourceNetwork = userProfile.socialNetwork;
        
        [self openWebViewWithURL:profileURL
                  socialNetowork:sourceNetwork
            requireAuthorization:YES];
    }
}

#pragma mark - Utility methods

- (void)openWebViewWithURL:(NSURL *)url socialNetowork:(SocialNetwork *)network requireAuthorization:(BOOL)requireAuthorization
{
    WDDWebViewController *webController = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDWebViewViewController];
    webController.url = url;
    webController.sourceNetwork = network;
    webController.requireAuthorization = requireAuthorization;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:webController]
                       animated:YES
                     completion:nil];
}

- (NSInteger)tagForIndexPath:(NSIndexPath *)indexPath
{
    return ((indexPath.section & 0x00FF) << 16 ) | (indexPath.row & 0x00FF);
}

- (NSIndexPath *)indexPathForTag:(NSInteger)tag
{
    NSInteger section= tag >> 16;
    NSInteger row= tag & 0x00FF;
    
    return [NSIndexPath indexPathForRow:row inSection:section];
}

#pragma mark - UIAlertViewDelegate protocol implememtation

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 0xFFFE && buttonIndex != alertView.cancelButtonIndex)
    {
        [[SocialNetworkManager sharedManager] cancelAllPostUpdates];
        for(SocialNetwork *sn in [[WDDDataBase sharedDatabase] fetchSocialNetworksAscendingWithType:kSocialNetworkFacebook])
        {
            [[PrivateMessagesModel sharedModel] removeXMPPClientForItem:sn];
        }
        
        WDDAppDelegate * appDelegate = (WDDAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate showHUDWithTitle:NSLocalizedString(@"lskLoggingOut", @"Logging out")];
        
        [PFUser logOut];
        
        [[WDDNotificationsManager sharedManager] disconnectFromDB];
        
        [self performSegueWithIdentifier:kStoryboardSegueIDPoweredByViewFromSlideView sender:nil];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag != 0xFFFE && buttonIndex != alertView.cancelButtonIndex)
    {
        NSIndexPath *indexPath = [self indexPathForTag:alertView.tag];
        UserProfile *selectedProfile = [self.fetchedResultsController objectAtIndexPath:indexPath];
        
        WDDSAddSocialNetworkViewController *controller = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDAddNetworkScreen];
        controller.loginMode = LoginModeRestoreToken;
        controller.updatingAccountId = selectedProfile.userID;
        controller.updatingAccountName = selectedProfile.name;
        controller.updatedCallback = ^(SocialNetworkType networkType, NSString *accessKey, NSDate *expirationTime)
        {
            if (accessKey)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    selectedProfile.socialNetwork.accessToken = accessKey;
                    selectedProfile.socialNetwork.exspireTokenTime = expirationTime;
                    selectedProfile.socialNetwork.activeState = @YES;
                    [[WDDDataBase sharedDatabase] save];
                    [[selectedProfile socialNetwork] updateSocialNetworkOnParse];
                    
                    NSManagedObjectID *socialNetworkID = [[selectedProfile socialNetwork] objectID];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                        
                        SocialNetwork *socialNetwork = (SocialNetwork *)[[WDDDataBase sharedDatabase].managedObjectContext objectWithID:socialNetworkID];
                        [socialNetwork updateProfileInfo];
                        [socialNetwork refreshGroups];
                        [socialNetwork getPosts];
                    });
                    
                    [self dismissViewControllerAnimated:YES completion:nil];
                    [self.socialNetworksTable reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                });
            }
        };
        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        [self presentViewController:navigationController
                           animated:YES
                         completion:^{
                             
                             [controller showLoginForNetworkWithType:selectedProfile.socialNetwork.type.integerValue];
                         }];
    }
}

@end