//
//  WDDLocationsListViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 16.04.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "WDDLocationsListViewController.h"
#import "WDDLocationTableViewCell.h"
#import "WDDLocation.h"

NSString * const WDDLocationsListViewControllerIdentifier = @"LocationsListViewController";

@interface WDDLocationsListViewController ()

@end

@implementation WDDLocationsListViewController

#pragma mark - Lifecircle
#pragma mark

- (void)viewDidLoad
{
    [super viewDidLoad];
}

#pragma mark - UITableView datasource
#pragma mark

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.locations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WDDLocationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:WDDLocationTableViewCellIdentifier
                                                                     forIndexPath:indexPath];
    
    WDDLocation *location = self.locations[indexPath.row];
    cell.locationLabel.text = location.name;
    
    return cell;
}

#pragma mark - UITableView delegate
#pragma mark

const CGFloat kRowHeight = 38.0f;

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kRowHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WDDLocation *location = self.locations[indexPath.row];
    
    if ([self.delegate respondsToSelector:@selector(didSelectLocataion:)])
    {
        [self.delegate didSelectLocataion:location];
    }
}
@end
