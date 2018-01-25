//
//  WDDLocationsListViewController.h
//  Woddl
//
//  Created by Sergii Gordiienko on 16.04.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

//  Constants
extern NSString * const WDDLocationsListViewControllerIdentifier;

@class WDDLocation;

@protocol WDDLocationsListDelegate <NSObject>
@optional
- (void)didSelectLocataion:(WDDLocation *)location;
@end

@interface WDDLocationsListViewController : UIViewController <  UITableViewDelegate,
                                                                UITableViewDataSource   >

//  Views
@property (weak, nonatomic) IBOutlet UITableView *locationsTableView;

//  Model
@property (strong, nonatomic) NSArray *locations;   // of WDDLocation objects
@property (weak, nonatomic) id <WDDLocationsListDelegate> delegate;
@end
