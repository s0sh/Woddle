//
//  WDDContactsViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDContactsViewController.h"
#import "WDDChatViewController.h"
#import "WDDChatContactCell.h"
#import "WDDChatContactTitle.h"

#import "XMPPClient.h"
#import "PrivateMessagesModel.h"

#import "WDDDataBase.h"
#import "FaceBookOthersProfile.h"

#import "WDDXMPPChatNotifier.h"

#import "EGORefreshTableHeaderView.h"
#import "LoadMoreTableFooterView.h"

#import "AvatarManager.h"
#import "UIImageView+AvatarLoading.h"

static NSString * const kContactCellID = @"ContactCell";

@interface WDDContactsViewController () <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, PrivateMessagesModelDelegate>
{
    ChatFriendsType currentFriendType;
}

@property (weak, nonatomic) IBOutlet UITableView *contactsTable;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *ios6Bug;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic, strong) NSFetchedResultsController *contactsResultsController;
@property (nonatomic, strong) NSMutableArray *fetchControllers;

@property (nonatomic, strong) NSPredicate *predicateForNonFacebookUser;

- (NSFetchedResultsController *)fetchedResultControllerForClient:(XMPPClient *)client;

@end

@implementation WDDContactsViewController

#pragma mark - Lazy instantiation
#pragma mark

- (NSPredicate *)predicateForNonFacebookUser
{
    if (!_predicateForNonFacebookUser)
    {
        _predicateForNonFacebookUser = [NSPredicate predicateWithFormat:@"NOT (SELF.displayName LIKE[cd] %@)", @"Facebook User"];
    }
    return _predicateForNonFacebookUser;
}

#pragma mark - lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fetchControllers = [[NSMutableArray alloc] initWithCapacity:[PrivateMessagesModel sharedModel].clients.count];
    
    [[PrivateMessagesModel sharedModel] registerDelegate:self];
    
    for (XMPPClient *client in [PrivateMessagesModel sharedModel].clients)
    {
        [self.fetchControllers addObject:[self fetchedResultControllerForClient:client]];
    }
    
    self.ios6Bug.constant = ([[[UIDevice currentDevice] systemVersion] floatValue] > 6.99f) ? 0.0f : 20.0f;
    [self setupNavigationBarTitle];
    [self customizeBackButton];
    
    //selected filter
    [self.onlineButton setSelected: YES];
    
    //set filter
    [self setFetchPredicateWithFriendsType:kChatFriendsTypeOnline];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Heatmaps trackScreenWithKey:@"503395516a70d21a-70a60df9"];
}

- (NSFetchedResultsController *)fetchedResultControllerForClient:(XMPPClient *)client
{
    NSFetchRequest *contactsRequest = [[NSFetchRequest alloc] initWithEntityName:@"XMPPUserCoreDataStorageObject"];
    contactsRequest.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"unreadMessages" ascending:NO],
                                        /*[[NSSortDescriptor alloc] initWithKey:@"primaryResource" ascending:NO],*/
                                        [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES]];
    
    NSFetchedResultsController *contactsController = [[NSFetchedResultsController alloc] initWithFetchRequest:contactsRequest
                                                                                         managedObjectContext:client.managedObjectContext_roster
                                                                                           sectionNameKeyPath:nil
                                                                                                    cacheName:nil];
    contactsController.delegate = self;
    
    NSError *opreationError = nil;
    [contactsController performFetch:&opreationError];
    
    if (opreationError)
    {
        DLog(@"Can't fetch contacts from roster: %@", opreationError);
    }
    
    return contactsController;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [WDDXMPPChatNotifier setCurrentChat:nil];
    
    if (self.contactsTable.indexPathForSelectedRow)
    {
        [self.contactsTable deselectRowAtIndexPath:self.contactsTable.indexPathForSelectedRow animated:animated];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationViewController isKindOfClass:[WDDChatViewController class]])
    {
        WDDChatViewController *chatController = (WDDChatViewController *)segue.destinationViewController;
        NSIndexPath *selectedContact = self.contactsTable.indexPathForSelectedRow;
        NSFetchedResultsController *fetchResultsController = [self.fetchControllers objectAtIndex:selectedContact.section];
        
        chatController.contact = [fetchResultsController objectAtIndexPath:[NSIndexPath indexPathForRow:selectedContact.row inSection:0]];
        
        [WDDXMPPChatNotifier setCurrentChat:chatController.contact.jid];
    }
}

#pragma mark - UITableViewDataSource protocol implementaion

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fetchControllers.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.fetchControllers objectAtIndex:section] fetchedObjects].count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WDDChatContactCell *cell = (WDDChatContactCell *)[tableView dequeueReusableCellWithIdentifier:kContactCellID forIndexPath:indexPath];

    XMPPClient *client = [[PrivateMessagesModel sharedModel].clients objectAtIndex:indexPath.section];
    XMPPUserCoreDataStorageObject *user = [[[self.fetchControllers objectAtIndex:indexPath.section] fetchedObjects] objectAtIndex:indexPath.row];
    
    UserProfile *userProfile = nil;
    NSString *userId = [[user.jidStr componentsSeparatedByString:@"@"] firstObject];
    if (userId)
    {
        if ([userId rangeOfString:@"-"].location == 0)  // Hack to remove "-" prefix in JID
        {
            userId = [userId substringFromIndex:1];
        }
        
        userProfile = [[[WDDDataBase sharedDatabase] fetchObjectsWithEntityName:NSStringFromClass([FaceBookOthersProfile class])
                                                                  withPredicate:[NSPredicate predicateWithFormat:@"userID == %@", userId]
                                                                sortDescriptors:nil] firstObject];
    }
    
    UIImage * avatarImage = nil;
    
    if (userProfile.avatarRemoteURL && [[AvatarManager sharedManager] isImageCachedForURL:[NSURL URLWithString:userProfile.avatarRemoteURL]] != ICTypeNone)
    {
        cell.avatareImageView.image = [[AvatarManager sharedManager] imageForURL:[NSURL URLWithString:userProfile.avatarRemoteURL]];
    }
    else
    {
        NSData *avatarData = [[client xmppvCardAvatarModule] photoDataForJID:user.jid];
        
        if (avatarData)
        {
            avatarImage = [UIImage imageWithData:avatarData];
        }
        else
        {
            avatarImage = [UIImage imageNamed:kAvatarPlaceholderImageName];
        }
        
        cell.avatareImageView.image = avatarImage;
        
        if (userProfile.avatarRemoteURL)
        {
            [cell.avatareImageView setAvatarWithURL:[NSURL URLWithString:userProfile.avatarRemoteURL]];
        }
    }
    
    
    ///////////////////
    UserProfile *profile = [self userForSecton:indexPath.section];

    [cell.adminAvatareImageView setAvatarWithURL:[NSURL URLWithString:profile.avatarRemoteURL]];
    cell.nameLabel.text = user.displayName;
    cell.statusImageView.image = (user.isOnline ? [UIImage imageNamed:@"ContactOnlineIcon"] : [UIImage imageNamed:@"ContactOfflineIcon"]);
    cell.unreadMessageLabel.hidden = (user.unreadMessages.integerValue ? NO : YES);
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0f;
}

- (UserProfile *)userForSecton:(NSInteger)sectionIndex
{
    UserProfile *profile = nil;
    
    NSFetchedResultsController *resultsController = [self.fetchControllers objectAtIndex:sectionIndex];
    NSString *streamBareJidStr = [(XMPPUserCoreDataStorageObject *)resultsController.fetchedObjects.firstObject streamBareJidStr];
    
    NSScanner *scaner = [NSScanner scannerWithString:streamBareJidStr];
    long long userId;
    if ([scaner scanLongLong:&userId])
    {
        NSArray *userProfiles = [[WDDDataBase sharedDatabase] fetchObjectsWithEntityName:NSStringFromClass([UserProfile class])
                                                                           withPredicate:[NSPredicate predicateWithFormat:@"userID == %lld", (userId < 0 ? userId * -1 : userId)]
                                                                         sortDescriptors:nil];
        profile = userProfiles.firstObject;
    }
    
    return profile;
}

#pragma mark PrivateMessagesModelDelegate protocol implementation

- (void)xmppClientAdded:(XMPPClient *)client
{
    [self.fetchControllers addObject:[self fetchedResultControllerForClient:client]];
    [self.contactsTable beginUpdates];
    [self.contactsTable insertSections:[NSIndexSet indexSetWithIndex:self.fetchControllers.count - 1]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.contactsTable endUpdates];
}

- (void)xmppClientWillBeRemoved:(XMPPClient *)client
{
    NSInteger clientIndex = [[PrivateMessagesModel sharedModel].clients indexOfObject:client];
    if (clientIndex != NSNotFound)
    {
        [self.fetchControllers removeObjectAtIndex:clientIndex];
        [self.contactsTable beginUpdates];
        [self.contactsTable deleteSections:[NSIndexSet indexSetWithIndex:clientIndex]
                          withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.contactsTable endUpdates];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate protocol implementation

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.contactsTable beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    NSInteger sectionIndex = [self.fetchControllers indexOfObject:controller];
    if (sectionIndex == NSNotFound)
    {
        return;
    }
    
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            [self.contactsTable insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:newIndexPath.row inSection:sectionIndex]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
        break;
            
        case NSFetchedResultsChangeDelete:
            [self.contactsTable deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:sectionIndex]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
        break;
            
        case NSFetchedResultsChangeUpdate:
            [self.contactsTable reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:indexPath.row inSection:sectionIndex]]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
        break;
            
        case NSFetchedResultsChangeMove:
        {
            [self.contactsTable moveRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:sectionIndex]
                                       toIndexPath:[NSIndexPath indexPathForRow:newIndexPath.row inSection:sectionIndex]];
        }
        break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.contactsTable endUpdates];
}

#pragma mark - Search implementation

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
	searchBar.showsScopeBar = YES;
	[searchBar sizeToFit];
    
	[searchBar setShowsCancelButton:YES animated:YES];
    
	return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsScopeBar = NO;
    [searchBar sizeToFit];
    
    [searchBar setShowsCancelButton:NO animated:YES];
    
    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self setupPredicateWithText:searchText];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = nil;
    
    [self setFetchPredicateWithFriendsType:currentFriendType];
    
    [self.contactsTable reloadData];
    
    [searchBar resignFirstResponder];

}

- (void)setupPredicateWithText:(NSString *)text
{
    if (!text)
    {
        text = @"";
    }
    
    for (NSFetchedResultsController *fetchController in self.fetchControllers)
    {
        NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"SELF.displayName BEGINSWITH[cd] %@", text];
        fetchController.fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ searchPredicate, self.predicateForNonFacebookUser ]];
        NSError *fetchError = nil;
        [fetchController performFetch:&fetchError];
        
        if (fetchError)
        {
            DLog(@"Fetching error: %@", fetchError);
        }
    }
    [self.contactsTable reloadData];
}

- (void)enableSearchBar
{
    [self.searchBar setUserInteractionEnabled:YES];
}

- (void)disableSearchBar
{
    [self.searchBar setUserInteractionEnabled:NO];
    [self.searchBar resignFirstResponder];
}

#pragma mark - Actions

- (IBAction)allButtonPressed:(id)sender
{
    [self.allButton setSelected: YES];
    [self.onlineButton setSelected: NO];
    [self.offlineButton setSelected: NO];
    
    [self.searchBar resignFirstResponder];
    self.searchBar.text = nil;
    
    [self setFetchPredicateWithFriendsType:kChatFriendsTypeAll];
    [self.contactsTable reloadData];
}

- (IBAction)onlineButtonPressed:(id)sender
{
    [self.allButton setSelected: NO];
    [self.onlineButton setSelected: YES];
    [self.offlineButton setSelected: NO];
    
    [self.searchBar resignFirstResponder];
    self.searchBar.text = nil;
    
    [self setFetchPredicateWithFriendsType:kChatFriendsTypeOnline];
    [self.contactsTable reloadData];
}

- (IBAction)offlineButtonPressed:(id)sender
{
    [self.allButton setSelected: NO];
    [self.onlineButton setSelected: NO];
    [self.offlineButton setSelected: YES];
    
    [self.searchBar resignFirstResponder];
    self.searchBar.text = nil;
    
    [self setFetchPredicateWithFriendsType:kChatFriendsTypeOffline];
    [self.contactsTable reloadData];
}

#pragma mark - Set predicate

- (void)setFetchPredicateWithFriendsType:(ChatFriendsType) friendsType
{
    if (friendsType == kChatFriendsTypeAll)
    {
        currentFriendType = kChatFriendsTypeAll;
        
        for (NSFetchedResultsController *fetchController in self.fetchControllers)
        {
            fetchController.fetchRequest.predicate = self.predicateForNonFacebookUser;
            NSError *fetchError = nil;
            [fetchController performFetch:&fetchError];
            
            if (fetchError)
            {
                DLog(@"Fetching error: %@", fetchError);
            }
        }
    }
    else if (friendsType == kChatFriendsTypeOnline)
    {
        currentFriendType = kChatFriendsTypeOnline;
        
        for (NSFetchedResultsController *fetchController in self.fetchControllers)
        {
            NSPredicate *unreadMessagesPredicate = [NSPredicate predicateWithFormat:@"SELF.unreadMessages != 0"];
            NSPredicate *onlinePredicate = [NSPredicate predicateWithFormat:@"primaryResource != nil"];
            
            NSPredicate *competePredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[unreadMessagesPredicate, onlinePredicate]];
            fetchController.fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ competePredicate, self.predicateForNonFacebookUser ]];
            NSError *fetchError = nil;
            [fetchController performFetch:&fetchError];
            
            if (fetchError)
            {
                DLog(@"Fetching error: %@", fetchError);
            }
        }
    }
    else if (friendsType == kChatFriendsTypeOffline)
    {
        currentFriendType = kChatFriendsTypeOffline;
        
        for (NSFetchedResultsController *fetchController in self.fetchControllers)
        {
            NSPredicate *onlinePredicate = [NSPredicate predicateWithFormat:@"primaryResource == nil"];
            
            fetchController.fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ onlinePredicate, self.predicateForNonFacebookUser ]];
            NSError *fetchError = nil;
            [fetchController performFetch:&fetchError];
            
            if (fetchError)
            {
                DLog(@"Fetching error: %@", fetchError);
            }
        }
    }
}

@end
