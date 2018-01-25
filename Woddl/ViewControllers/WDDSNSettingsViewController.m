//
//  WDDSNSettingsViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import <Parse.h>
#import "WDDSNSettingsViewController.h"
#import "UIImage+ResizeAdditions.h"
#import "UIImageView+WebCache.h"
#import "FacebookSN.h"
#import "TwitterProfile.h"
#import "UserProfile.h"
#import "WDDSocialNetworkCell.h"
#import "SAMHUDView.h"

#import "UIImageView+AvatarLoading.h"

static NSString * const kStateChecked       = @"Sidebar_account_enabled";
static NSString * const kStateUnchecked     = @"Sidebar_account_disabled";

static NSString * const kFollowingCellIdentifier = @"TwitterFollowingCell";
@interface WDDSNSettingsViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UIAlertViewDelegate >

//  Views
@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *enableChatLabel;
@property (weak, nonatomic) IBOutlet UITableView *followingTableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) SAMHUDView *hudView;
@property (weak, nonatomic) IBOutlet UIButton *accountStatusButton;
@property (weak, nonatomic) IBOutlet UIButton *chatStatusButton;

//  Constraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *enableChatLabelOffset;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *enableChatLabelHeight;

//
@property (strong, nonatomic) NSArray *friendsProfiles;
@property (strong, nonatomic) NSArray *tableDataPofiles;

@property (assign, nonatomic, getter = isReloadNeeded) BOOL reloadNeeded;
@end

@implementation WDDSNSettingsViewController

#pragma mark - setters

 - (void)setSocialNetwork:(SocialNetwork *)socialNetwork
{
    _socialNetwork = socialNetwork;
    
    if (socialNetwork)
    {
        [self updateUI];
    }
}

#pragma mark - UIView lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupNavigationBarTitle];
    [self makeAvatarImageRoundConners];
    [self updateUI];
    [self customizeBackButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Heatmaps trackScreenWithKey:@"503395516a70d21a-1bbf9087"];
}

- (void)dismissViewController
{
    [self performSegueWithIdentifier:kStoryboardSegueIDUnwindBackFromSettingsSegue sender:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.isReloadNeeded)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationRefetchMainSreenTable object:nil];
    }
}

#pragma mark - Other actions
#pragma mark

- (IBAction)accountStateChanged:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.socialNetwork.activeState = @(sender.selected);
        [[WDDDataBase sharedDatabase] save];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationRefetchMainSreenTable object:nil];
    });
}

- (IBAction)chatStateChanged:(UIButton *)sender
{
    sender.selected = !sender.selected;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        FacebookSN *fbSN = (FacebookSN *)self.socialNetwork;
        fbSN.isChatEnabled = @(sender.selected);
        [[WDDDataBase sharedDatabase] save];
    });
}

- (IBAction)deleteAccountAction:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:nil
                                message:NSLocalizedString(@"lskDeleteAccountMessage", @"Are you sure, that you want to remove this account?")
                               delegate:self
                      cancelButtonTitle:NSLocalizedString(@"lskNo", @"No")
                      otherButtonTitles:NSLocalizedString(@"lskYes", @"Yes"), nil] show];
}

#pragma mark - UIAlertView
#pragma mark

typedef NS_ENUM(NSUInteger, kDeleteAlertButtons)
{
    kDeleteAlertButtonNo = 0,
    kDeleteAlertButtonYes = 1
};

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == kDeleteAlertButtonYes)
    {
        [self deleteSocialNetworkAccountFromParseAndDataBase];
    }
}

- (void)deleteSocialNetworkAccountFromParseAndDataBase
{
    self.hudView = [[SAMHUDView alloc] initWithTitle:NSLocalizedString(@"lskDeletingAccount", @"Deleting account")];
    [self.hudView show];
    
    PFQuery *query = [PFQuery queryWithClassName:NSStringFromClass([SocialNetwork class])];
    [query whereKey:@"userOwner" equalTo:[PFUser currentUser]];
    [query whereKey:@"networkUserId" equalTo:self.socialNetwork.profile.userID];
    
    
    PFArrayResultBlock findObjectsResultBlock = ^(NSArray *objects, NSError *error)
    {
        if (!error)
        {
            PFObject *socialNetworkFromParse = [objects firstObject];
            [self deleteParseObject:socialNetworkFromParse];
        }
        else
        {
            DLog(@"Error: %@", [error localizedDescription]);
            [self.hudView failAndDismissWithTitle:NSLocalizedString(@"lskDeletionFailed", @"Fail to delete")];
        }
    };
    [query findObjectsInBackgroundWithBlock:findObjectsResultBlock];
}

- (void)deleteParseObject:(PFObject *)socialNetwoek
{
    PFBooleanResultBlock deleteObjectResultBlock = ^(BOOL succeeded, NSError *error)
    {
        if (succeeded)
        {
            [[WDDDataBase sharedDatabase] removeSocialNetwork:self.socialNetwork];
            [self.hudView completeAndDismissWithTitle:NSLocalizedString(@"lskDeletionSucceed", @"Delete with success")];
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationRefetchMainSreenTable object:nil];
            [self dismiss];
        }
        else
        {
            [self.hudView failAndDismissWithTitle:NSLocalizedString(@"lskDeletionFailed", @"Fail to delete")];
        }
    };
    
    if (socialNetwoek)
    {
        [socialNetwoek deleteInBackgroundWithBlock:deleteObjectResultBlock];
    }
    else
    {
        [self.hudView failAndDismissWithTitle:NSLocalizedString(@"lskDeletionFailed", @"Fail to delete")];
    }
}

#pragma mark - Appearance methods
#pragma mark

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

- (void)makeAvatarImageRoundConners
{
    self.avatarImageView.layer.masksToBounds = YES;
    [self.avatarImageView.layer setCornerRadius:2.0f];
}

- (void)updateUI
{
    self.displayNameLabel.text = self.socialNetwork.displayName;
    self.accountStatusButton.selected = self.socialNetwork.activeState.boolValue;
    
    [self setupAvatarImageforSocialNetwork:self.socialNetwork];
    [self setupEnableChatViews];
    [self setupFriendsAndGroupsTableView];
}

- (void)setupAvatarImageforSocialNetwork:(SocialNetwork *)socialNetwork
{
    CGFloat width = self.avatarImageView.frame.size.width*2;
    UIImage *placeHolderImage = [[UIImage imageNamed:kAvatarPlaceholder] thumbnailImage:width
                                                                      transparentBorder:1.0f
                                                                           cornerRadius:5.0f
                                                                   interpolationQuality:kCGInterpolationDefault];
    
    NSURL *avatarURL = [NSURL URLWithString:socialNetwork.profile.avatarRemoteURL];
    
    SDWebImageCompletedBlock completion = ^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        if (!error)
        {
            image = [image thumbnailImage:width
                        transparentBorder:0
                             cornerRadius:5.0f
                     interpolationQuality:kCGInterpolationMedium];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.avatarImageView.image = image;
            });
        }
    };
    
    [self.avatarImageView setImageWithURL:avatarURL
                         placeholderImage:placeHolderImage
                                  options:SDWebImageRefreshCached
                                completed:completion];
    
}

- (void)setupEnableChatViews
{
    NSInteger socialNetworkType = [self.socialNetwork.type integerValue];
    if (socialNetworkType != kSocialNetworkFacebook)
    {
        self.chatStatusButton.hidden = YES;
        self.enableChatLabel.hidden = YES;
    
        self.enableChatLabelHeight.constant = 0.0f;
        self.enableChatLabelOffset.constant = 0.0f;
    }
    else
    {
        FacebookSN *fbSN = (FacebookSN *)self.socialNetwork;
        self.chatStatusButton.selected = fbSN.isChatEnabled.boolValue;
    }
}

- (void)setupFriendsAndGroupsTableView
{
    NSArray *friendsAndGroups;
    NSArray *friends = [[WDDDataBase sharedDatabase] fetchFriendsForSocialNetwork:self.socialNetwork];
    
    if (friends)
    {
//        if (self.socialNetwork.groups.count)
//        {
//            friendsAndGroups = [friends arrayByAddingObjectsFromArray:[self.socialNetwork.groups allObjects]];
//        }
//        else
        {
            friendsAndGroups = friends;
        }
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
        
        self.friendsProfiles = [friendsAndGroups sortedArrayUsingDescriptors:@[sortDescriptor]];
        self.tableDataPofiles = self.friendsProfiles;
    }
    else
    {
#ifdef DEBUG
        DLog(@"Oops! There are no friends for this account");
#endif
        self.followingTableView.hidden = YES;
        self.followingTableView.delegate = nil;
        self.followingTableView.dataSource = nil;
    }
}

#pragma mark - Table View
#pragma mark

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (self.tableDataPofiles ? [self.tableDataPofiles count] : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WDDSocialNetworkCell *cell = [tableView dequeueReusableCellWithIdentifier:kFollowingCellIdentifier forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

const CGFloat kHeightForFriendsCell = 44.0f;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kHeightForFriendsCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.reloadNeeded = YES;
    
    id friendOrGroup = self.tableDataPofiles[indexPath.row];
    
    if ([friendOrGroup isKindOfClass:[UserProfile class]])
    {
        [self blockAuthor:friendOrGroup];
    }
    else    // Group
    {
        [self blockGroup:friendOrGroup];
    }
    
    [self.followingTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)blockGroup:(Group *)group
{
    BOOL newState = ![group.isGroupBlock boolValue];
    group.isGroupBlock = [NSNumber numberWithBool:newState];
    [[WDDDataBase sharedDatabase] save];
}

- (void)blockAuthor:(UserProfile *)profile
{
    BOOL isBlocked = ![profile.isBlocked boolValue];
    profile.isBlocked = [NSNumber numberWithBool:isBlocked];
    [[WDDDataBase sharedDatabase] save];
}

#pragma mark - Configure cell
#pragma mark

- (void)configureCell:(WDDSocialNetworkCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    id friendOrGroup = self.tableDataPofiles[indexPath.row];
    
    if ([friendOrGroup isKindOfClass:[UserProfile class]])
    {
        [self configureCell:cell forUserProfile:friendOrGroup];
    }
    else // Group
    {
        [self configureCell:cell forGroup:friendOrGroup];
    }
    
    cell.avatarImage.layer.masksToBounds = YES;
    [cell.avatarImage.layer setCornerRadius:5.0f];
}

- (void)configureCell:(WDDSocialNetworkCell *)cell forUserProfile:(UserProfile *)profile
{
    cell.stateButton.userInteractionEnabled = NO;
    cell.stateButton.selected = ![profile.isBlocked boolValue];
    cell.displayName.text = profile.name;
    [self  setupAvatarImageInCell:cell forImageURL:profile.avatarRemoteURL];
}

- (void)configureCell:(WDDSocialNetworkCell *)cell forGroup:(Group *)group
{
    cell.stateButton.userInteractionEnabled = NO;
    cell.stateButton.selected = ![group.isGroupBlock boolValue];
    
    cell.displayName.text = group.name;
    [self  setupAvatarImageInCell:cell forImageURL:group.imageURL];
}

- (void)setupAvatarImageInCell:(WDDSocialNetworkCell *)cell forImageURL:(NSString *)imageURL
{
//    CGFloat width = cell.avatarImage.frame.size.width*2;
//    UIImage *placeHolderImage = [[UIImage imageNamed:kAvatarPlaceholder] thumbnailImage:width
//                                                                      transparentBorder:1.0f
//                                                                           cornerRadius:5.0f
//                                                                   interpolationQuality:kCGInterpolationDefault];
//    
//    NSURL *avatarURL = [NSURL URLWithString:imageURL];
//    
//    SDWebImageCompletedBlock completion = ^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//        if (!error)
//        {
//            image = [image thumbnailImage:width
//                        transparentBorder:0
//                             cornerRadius:5.0f
//                     interpolationQuality:kCGInterpolationMedium];
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                cell.avatarImage.image = image;
//            });
//        }
//    };
//    
//    [cell.avatarImage setImageWithURL:avatarURL
//                     placeholderImage:placeHolderImage
//                            completed:completion];
    
    NSURL *avatarURL = [NSURL URLWithString:imageURL];
    [cell.avatarImage setAvatarWithURL:avatarURL];
}

#pragma mark - Searchbar delegate
#pragma mark

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchText.length)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name CONTAINS[cd] %@", searchText];
        self.tableDataPofiles = [self.friendsProfiles filteredArrayUsingPredicate:predicate];
    }
    else
    {
        self.tableDataPofiles = self.friendsProfiles;
    }
    [self.followingTableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *) searchBar
{
    self.tableDataPofiles = self.friendsProfiles;
    [self.followingTableView reloadData];
    [searchBar resignFirstResponder];
}
@end
