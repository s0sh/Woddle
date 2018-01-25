//
//  WDDAccountSelector.m
//  Woddl
//
//  Created by Oleg Komaristov on 25.03.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "WDDAccountSelector.h"

#import "WDDAccountSelectorCell.h"
#import "WDDAccountSelectorHeaderView.h"

#import "WDDDataBase.h"
#import "SocialNetwork.h"
#import "Group.h"

#import "UIImageView+AvatarLoading.h"

@interface WDDAccountSelector () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) SocialNetworkType networkType;
@property (nonatomic, copy) AccountsSelected completeBlock;
@property (nonatomic, copy) AccountsSelectionCanceled cancelBlock;

@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, strong) NSMutableDictionary *groups;


@property (nonatomic, strong) NSMutableSet *selectedAccounts;
@property (nonatomic, strong) NSMutableSet *selectedGroups;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *titleItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneItem;


@end

@implementation WDDAccountSelector

+ (WDDAccountSelector *)selectorWithSocialNetworkType:(SocialNetworkType)networkType
                               selectionCompleteBlock:(AccountsSelected)complete
                               selectionCanceledBlock:(AccountsSelectionCanceled)canceled
{
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"WDDAccountSelector" owner:self options:nil];
    WDDAccountSelector *selector = (WDDAccountSelector *)[nibContents objectAtIndex:0];
    
    selector.completeBlock = complete;
    selector.cancelBlock = canceled;
    selector.networkType = networkType;
    [selector initialize];
    
    return selector;
}

- (void)initialize
{
    self.accounts = [[WDDDataBase sharedDatabase] fetchSocialNetworksAscendingWithType:self.networkType];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"displayName"
                                                                     ascending:YES];
    self.accounts = [self.accounts sortedArrayUsingDescriptors:@[sortDescriptor]];
    self.groups = [[NSMutableDictionary alloc] initWithCapacity:self.accounts.count];

    for (SocialNetwork *account in self.accounts)
    {
        NSArray *groupsList = [account.profile.manageGroups sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES], [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
        
        if (groupsList.count)
        {
            [self.groups setObject:groupsList forKey:account.objectID];
        }
    }
    
    self.selectedAccounts = [[NSMutableSet alloc] initWithCapacity:self.accounts.count];
    self.selectedGroups = [[NSMutableSet alloc] initWithCapacity:self.groups.count];
    
    [self updateDoneStatus];
}

- (void)show
{
    CGFloat centerY = CGRectGetHeight([UIScreen mainScreen].bounds) + CGRectGetHeight(self.frame) / 2.f;
    CGFloat centerX = CGRectGetWidth([UIScreen mainScreen].bounds) / 2.f;
    
    CGFloat targetY = CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetHeight(self.frame) / 2.f;
    self.center = (CGPoint){centerX, centerY};
    
    [[[UIApplication sharedApplication].delegate window] addSubview:self];
    
    [UIView animateWithDuration:0.15 animations:^{
        
        self.center = (CGPoint){centerX, targetY};
    }];
}

- (void)hide
{
    CGFloat centerY = CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetHeight(self.frame) / 2.f;
    CGFloat centerX = CGRectGetWidth([UIScreen mainScreen].bounds) / 2.f;
    
    [UIView animateWithDuration:0.15 animations:^{
        
        self.center = (CGPoint){centerX, centerY};
    } completion:^(BOOL finished) {
        
        [self removeFromSuperview];
    }];

}

- (void)setTitle:(NSString *)title
{
    self.titleItem.title = title;
}

- (NSString *)title
{
    return self.titleItem.title;
}

#pragma mark - User actions processing

- (IBAction)cancelAction:(id)sender
{
    if (self.cancelBlock)
    {
        self.cancelBlock(self);
    }
}

- (IBAction)doneAction:(id)sender
{
    if (self.completeBlock)
    {
        self.completeBlock([self.selectedAccounts copy], [self.selectedGroups copy], self);
    }
}

#pragma - UITableViewDatasource protocol implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.accounts.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.groups[[self.accounts[section] objectID]] count];
}

static NSString * kStatusSNAccountCellIdentifier = @"AccountSelectorCell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WDDAccountSelectorCell *cell = [tableView dequeueReusableCellWithIdentifier:kStatusSNAccountCellIdentifier];
    
    if (!cell)
    {
        NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"WDDAccountSelectorCell" owner:self options:nil];
        cell = (WDDAccountSelectorCell *)[nibContents objectAtIndex:0];
    }
    
    Group *group = [self.groups[[self.accounts[indexPath.section] objectID]] objectAtIndex:indexPath.row];
    cell.groupName.text = group.name;
    cell.checkmarkImage.image = [self checkmarkImageForObject:group];
    
    return cell;
}

#pragma mark - UITableViewDelegate protocol implementation

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [WDDAccountSelectorHeaderView height];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SocialNetwork *account = self.accounts[section];
    
    NSArray *nibContents = [[NSBundle mainBundle] loadNibNamed:@"WDDAccountSelectorHeaderView" owner:self options:nil];
    WDDAccountSelectorHeaderView *accountView = (WDDAccountSelectorHeaderView *)[nibContents objectAtIndex:0];
    
    accountView.userNameLabel.text = account.displayName;
    accountView.checkmarkImageview.image = [self checkmarkImageForObject:account];
    accountView.tag = section + 1;
    [accountView.checkButton addTarget:self action:@selector(selectAccount:) forControlEvents:UIControlEventTouchUpInside];
    [accountView.avatarImageview setAvatarWithURL:[NSURL URLWithString:account.profile.avatarRemoteURL]];
    
    return accountView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Group *group = [self.groups[[self.accounts[indexPath.section] objectID]] objectAtIndex:indexPath.row];
    
    if ([self.selectedGroups containsObject:group])
    {
        [self.selectedGroups removeObject:group];
    }
    else
    {
        [self.selectedGroups addObject:group];
    }
    
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];

    [self updateDoneStatus];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 30.f;
}

#pragma mark - User acitvity

- (void)selectAccount:(UIButton *)sender
{
    WDDAccountSelectorHeaderView *accountView = (WDDAccountSelectorHeaderView *)sender.superview;
    NSInteger iSection = accountView.tag - 1;
    SocialNetwork *account = self.accounts[iSection];
    
    if ([self.selectedAccounts containsObject:account])
    {
        [self.selectedAccounts removeObject:account];
    }
    else
    {
        [self.selectedAccounts addObject:account];
    }
    
    accountView.checkmarkImageview.image = [self checkmarkImageForObject:account];
    [self updateDoneStatus];
}

#pragma mark - Utility methods

- (void)updateDoneStatus
{
    self.doneItem.enabled = self.selectedGroups.count || self.selectedAccounts.count;
}

- (UIImage *)checkmarkImageForObject:(id)object
{
    BOOL isAccount = [object isKindOfClass:[SocialNetwork class]];
    NSSet *selectedSet = isAccount ? self.selectedAccounts : self.selectedGroups;
    
    BOOL isSelected = [selectedSet containsObject:object];
    __block BOOL isMiddlState = NO;
    if (isAccount)
    {
        NSArray *groups = self.groups[[object objectID]];
    
        [groups enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            if ([self.selectedGroups containsObject:obj])
            {
                isMiddlState = YES;
                *stop = YES;
            }
            
        }];
    }
    
    if (isSelected)
    {
        return [UIImage imageNamed:@"status_black_checkmark_checked"];
    }
    else if (isAccount && isMiddlState)
    {
        return [UIImage imageNamed:@"status_black_checkmark_inactive"];
    }
    
    return [UIImage imageNamed:@"status_black_checkmark_unchecked"];
}

@end
