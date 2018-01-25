//
//  WDDSearchViewController.h
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WDDBasePostsViewController.h"

@interface WDDSearchViewController : WDDBasePostsViewController
@property (weak, nonatomic) IBOutlet UITableView *postsTable;
@property (strong, nonatomic) NSString * searchText;

@end
