//
//  WDDStatusSNAccountsViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 17.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDStatusSNAccountsViewController.h"
#import "WDDStatusSNAccountCell.h"
#import "WDDDataBase.h"
#import "WDDAccountSelectionView.h"

#import "SDWebImageManager.h"
#import "UIImage+ResizeAdditions.h"
#import "UIImageView+AvatarLoading.h"

@interface WDDStatusSNAccountsViewController ()
//  Views
@property (weak, nonatomic) IBOutlet UITableView *accountsTableView;
//  Model
@property (strong, nonatomic) NSArray *allSocialNetworkAccounts;
@property (strong, nonatomic) NSMutableDictionary *allOwnGroups;
@property (strong, nonatomic) NSMutableDictionary *sectionHeaders;

@end

@implementation WDDStatusSNAccountsViewController

#pragma mark - Setters and getters

- (NSArray *)allSocialNetworkAccounts
{
    if (!_allSocialNetworkAccounts)
    {
        if (!self.socialNetworkType)
        {
            return  nil;
        }
        
        _allSocialNetworkAccounts = [[WDDDataBase sharedDatabase] fetchSocialNetworksAscendingWithType:self.socialNetworkType];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accessToken != nil"];
        _allSocialNetworkAccounts = [_allSocialNetworkAccounts filteredArrayUsingPredicate:predicate];
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"displayName"
                                                                         ascending:YES];
        _allSocialNetworkAccounts = [_allSocialNetworkAccounts sortedArrayUsingDescriptors:@[sortDescriptor]];
        self.allOwnGroups = [[NSMutableDictionary alloc] initWithCapacity:_allSocialNetworkAccounts.count];
        for (SocialNetwork *account in _allSocialNetworkAccounts)
        {
            NSArray *groupsList = [account.profile.manageGroups sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
            
//            NSArray *groupsList = [[account.groups filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"isManagedByMe == %@", @YES]]
//                                   sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
            if (groupsList.count)
            {
                [self.allOwnGroups setObject:groupsList forKey:account.objectID];
            }
        }
        
    }
    return _allSocialNetworkAccounts;
}

- (NSMutableDictionary *)sectionHeaders
{
    if (!_sectionHeaders)
    {
        _sectionHeaders = [[NSMutableDictionary alloc] initWithCapacity:self.allSocialNetworkAccounts.count];
    }
    
    return _sectionHeaders;
}

- (NSMutableArray *)selectedAccounts
{
    if (!_selectedAccounts)
    {
        _selectedAccounts = [[NSMutableArray alloc] init];
    }
    return _selectedAccounts;
}

- (NSMutableArray *)selectedGroups
{
    if (!_selectedGroups)
    {
        _selectedGroups = [[NSMutableArray alloc] init];
    }
    return _selectedGroups;
}

- (void)setSocialNetworkType:(SocialNetworkType)socialNetworkType
{
    _socialNetworkType = socialNetworkType;
    [self allSocialNetworkAccounts];
    
    __block NSInteger fullGroupsCount = 0;
    [self.allOwnGroups enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
        fullGroupsCount += [obj count];
    }];
    
    if (self.allSocialNetworkAccounts.count + fullGroupsCount > 4)
    {
        CGRect frame = self.view.frame;
        frame.size.height += [WDDAccountSelectionView height] * 2.f;
        self.view.frame = frame;
    }
    else
    {
        CGRect frame = self.view.frame;
        frame.size.height += [WDDAccountSelectionView height] * 2.f / 3.f;
        self.view.frame = frame;
    }
}


#pragma mark - Life cycle methods
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if ([self.delegate respondsToSelector:@selector(didSelectSocialNetworkAccounts:andGroups:forType:)])
    {
        [self.delegate didSelectSocialNetworkAccounts:[self.selectedAccounts copy] andGroups:[self.selectedGroups copy] forType:self.socialNetworkType];
    }
}

#pragma mark - TableView Delegate and Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.allSocialNetworkAccounts.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.allOwnGroups[[self.allSocialNetworkAccounts[section] objectID]] count];
}

static NSString * kStatusSNAccountCellIdentifier = @"StatusSNAccountCell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WDDStatusSNAccountCell *cell = [tableView dequeueReusableCellWithIdentifier:kStatusSNAccountCellIdentifier
                                                                   forIndexPath:indexPath];

    Group *group = [self.allOwnGroups[[self.allSocialNetworkAccounts[indexPath.section] objectID]] objectAtIndex:indexPath.row];
    cell.usernameLabel.text = group.name;
    cell.checkmarkImage.image = [self checkmarkImageForGroup:group];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [WDDAccountSelectionView height];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SocialNetwork *account = self.allSocialNetworkAccounts[section];

    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"WDDAccountSelectionView" owner:self options:nil];
    WDDAccountSelectionView *accountView = (WDDAccountSelectionView *)[nibContents objectAtIndex:0];
    accountView.usernameLabel.text = account.displayName;
    accountView.checkmarkImage.image = [self checkmarkImageForSocialNetwork:account];
    accountView.tag = section + 1;
    [accountView.checkButton addTarget:self action:@selector(selectAccount:) forControlEvents:UIControlEventTouchUpInside];
    [accountView.avatarImageView setAvatarWithURL:[NSURL URLWithString:account.profile.avatarRemoteURL]];
    
    [self.sectionHeaders setObject:accountView forKey:@(section)];
    
    return accountView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    Group *group = [self.allOwnGroups[[self.allSocialNetworkAccounts[indexPath.section] objectID]] objectAtIndex:indexPath.row];
    BOOL isSelected = NO;
    if ([self.selectedGroups containsObject:group])
    {
        [self.selectedGroups removeObject:group];
    }
    else
    {
        isSelected = YES;
        [self.selectedGroups addObject:group];
    }
    
    SocialNetwork *account = self.allSocialNetworkAccounts[indexPath.section];
    WDDAccountSelectionView *accountView = [self.sectionHeaders objectForKey:@(indexPath.section)];
//    if (isSelected && [self.selectedAccounts containsObject:account])
//    {
//        [self.selectedAccounts removeObject:account];
//    }
    
    [tableView beginUpdates];
    accountView.checkmarkImage.image = [self checkmarkImageForSocialNetwork:account];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [tableView endUpdates];
}

- (void)selectAccount:(UIButton *)sender
{
    WDDAccountSelectionView *accountView = (WDDAccountSelectionView *)sender.superview;
    
    SocialNetwork *account = self.allSocialNetworkAccounts[accountView.tag - 1];
    
    if ([self.selectedAccounts containsObject:account])
    {
        [self.selectedAccounts removeObject:account];
    }
    else
    {
        [self.selectedAccounts addObject:account];
        
//        NSArray *groups = self.allOwnGroups[account.objectID];
//        __block BOOL isNeedUpdate = NO;
//        [groups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//            
//            if ([self.selectedGroups containsObject:obj])
//            {
//                [self.selectedGroups removeObject:obj];
//                isNeedUpdate = YES;
//            }
//            
//        }];
//        
//        if (isNeedUpdate)
//        {
//            [self.accountsTableView reloadSections:[NSIndexSet indexSetWithIndex:(accountView.tag - 1)]
//                                  withRowAnimation:UITableViewRowAnimationAutomatic];
//        }
    }
    accountView.checkmarkImage.image = [self checkmarkImageForSocialNetwork:account];
}

#pragma mark - Configure cell methods
- (void)configureCell:(WDDStatusSNAccountCell *)cell forSocialNetwork:(SocialNetwork *)socialNetwork
{
    cell.usernameLabel.text = socialNetwork.displayName;
    cell.checkmarkImage.image = [self checkmarkImageForSocialNetwork:socialNetwork];
    [cell.avatarImageView setAvatarWithURL:[NSURL URLWithString:socialNetwork.profile.avatarRemoteURL]];
}

- (UIImage *)checkmarkImageForSocialNetwork:(SocialNetwork *)socialNetwork
{
    UIImage *checkmarkImage;
    if ([self.selectedAccounts containsObject:socialNetwork])
    {
        checkmarkImage = [UIImage imageNamed:kWhiteCheckmarkChecked];
    }
    else
    {
        NSArray *groups = self.allOwnGroups[socialNetwork.objectID];
        __block BOOL isInactive = NO;
        [groups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
           
            if ([self.selectedGroups containsObject:obj])
            {
                isInactive = YES;
                *stop = YES;
            }
            
        }];
        
        if (isInactive)
        {
            checkmarkImage = [UIImage imageNamed:kWhiteCheckmartInactive];
        }
        else
        {
            checkmarkImage = [UIImage imageNamed:kWhiteCheckmarkUnchecked];
        }
    }
    return checkmarkImage;
}

- (UIImage *)checkmarkImageForGroup:(Group *)group
{
    UIImage *checkmarkImage;
    if ([self.selectedGroups containsObject:group])
    {
        checkmarkImage = [UIImage imageNamed:kWhiteCheckmarkChecked];
    }
    else
    {
        checkmarkImage = [UIImage imageNamed:kWhiteCheckmarkUnchecked];
    }
    return checkmarkImage;
}

@end
