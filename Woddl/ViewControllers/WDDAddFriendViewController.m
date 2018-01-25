//
//  WDDAddFriendViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 26.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDAddFriendViewController.h"
#import "WDDAddFriendCell.h"

#import "UserProfile.h"
#import "TwitterProfile.h"
#import "InstagramProfile.h"
#import "WDDDataBase.h"

#import "UIImage+ResizeAdditions.h"
#import "UIImageView+AvatarLoading.h"

@interface WDDAddFriendViewController ()< UITableViewDelegate,
                                          UITableViewDataSource,
                                          UISearchBarDelegate >
//  UIViews
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *friendsTable;

//  Model
@property (strong, nonatomic) NSArray *friendsProfiles;
@property (strong, nonatomic) NSArray *searchResults;

@end

@implementation WDDAddFriendViewController

#pragma mark - setters and getters

- (NSArray *)friendsProfiles
{
    if (!_friendsProfiles)
    {
        NSMutableArray *allFriends = [[NSMutableArray alloc] init];
        if  (self.socialNetworks)
        {
            for (SocialNetwork *sn in self.socialNetworks)
            {
                NSArray *friends = [[WDDDataBase sharedDatabase] fetchFriendsForSocialNetwork:sn];
                if (friends)
                {
                    [allFriends addObjectsFromArray:friends];
                }
            }
        }
        else
        {
            [allFriends addObjectsFromArray:[[WDDDataBase sharedDatabase] fetchAllFriends]];
        }
        allFriends = [[self removeDublicatedFriendsInArray:allFriends] mutableCopy];
        
        
        NSSortDescriptor *sortDesctiptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        [allFriends sortUsingDescriptors:@[sortDesctiptor]];
        _friendsProfiles = [allFriends copy];
    }
    return _friendsProfiles;
}

- (NSArray *)removeDublicatedFriendsInArray:(NSArray *)allFriends
{
    NSMutableSet *uniqueFriendsIds = [[NSMutableSet alloc] initWithCapacity:allFriends.count];
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:allFriends.count];
    
    [allFriends enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        
        if (![uniqueFriendsIds containsObject:[obj userID]])
        {
            [uniqueFriendsIds addObject:[obj userID]];
            [result addObject:obj];
        }
    }];
    
    return result;
}

#pragma mark - Life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self customizeBackButton];
    [self setupNavigationBarTitle];
    
    self.searchResults = self.friendsProfiles;
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (!searchText.length)
    {
        self.searchResults = self.friendsProfiles;
    }
    else
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name BEGINSWITH[cd] %@",searchText];
        self.searchResults = [self.friendsProfiles filteredArrayUsingPredicate:predicate];
    }
    [self.friendsTable reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = nil;
    [searchBar resignFirstResponder];
    
    self.searchResults = self.friendsProfiles;
    [self.friendsTable reloadData];
}

#pragma mark - UITableView

static NSString * kAddFriendCellIdentifier = @"AddFriendCell";
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WDDAddFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:kAddFriendCellIdentifier
                                                             forIndexPath:indexPath];
    
    UserProfile *profile = self.searchResults[indexPath.row];
    [self configureCell:cell forSocialNetwork:profile];
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    
    return ( self.searchResults ? self.searchResults.count : 0 );
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.searchBar.isFirstResponder)
    {
        [self.searchBar resignFirstResponder];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserProfile *profile = self.searchResults[indexPath.row];
    NSString *userName = profile.name;
    if ([profile isKindOfClass:[TwitterProfile class]])
    {
        userName = [NSString stringWithFormat:@"@%@",[profile.profileURL lastPathComponent]];
    }
    
    if ([self.delegate respondsToSelector:@selector(didAddFriendWithName:)])
    {
        [self.delegate didAddFriendWithName:userName];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Configure cell methods

static CGFloat const kAvatarCornerRadious = 2.0f;
- (void)configureCell:(WDDAddFriendCell *)cell forSocialNetwork:(UserProfile *)profile
{
    cell.usernameLabel.text = profile.name;
    cell.snIconImageView.image = [UIImage imageNamed:[profile socialNetworkIconName]];
    [self setupAvatarImageInCell:cell
                      forProfile:profile];
}

- (void)setupAvatarImageInCell:(WDDAddFriendCell *)cell forProfile:(UserProfile *)profile
{
//    CGFloat width = cell.avatarImageView.frame.size.width * [UIScreen mainScreen].scale;
//    UIImage *placeHolderImage = [[UIImage imageNamed:kAvatarPlaceholderImageName] thumbnailImage:width
//                                                                               transparentBorder:1.0f
//                                                                                    cornerRadius:kAvatarCornerRadious
//                                                                            interpolationQuality:kCGInterpolationDefault];
    NSURL *avatarURL = [NSURL URLWithString:profile.avatarRemoteURL];
    [cell.avatarImageView setAvatarWithURL:avatarURL];
    
//    SDWebImageCompletedBlock completion = ^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
//        if (!error)
//        {
//            image = [image thumbnailImage:width
//                        transparentBorder:1.0f
//                             cornerRadius:kAvatarCornerRadious
//                     interpolationQuality:kCGInterpolationMedium];
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                cell.avatarImageView.image = image;
//            });
//        }
//    };
//    
//    [cell.avatarImageView setImageWithURL:avatarURL
//                         placeholderImage:placeHolderImage
//                                  options:SDWebImageRefreshCached
//                                completed:completion];
//    
//    cell.avatarImageView.layer.masksToBounds = YES;
//    [cell.avatarImageView.layer setCornerRadius:kAvatarCornerRadious];
}

@end
