//
//  WDDStatusSNAccountsViewController.h
//  Woddl
//
//  Created by Sergii Gordiienko on 17.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WDDStatusSNAccountsDelegate <NSObject>

@optional
- (void)didSelectSocialNetworkAccounts:(NSArray *)selectedAccounts andGroups:(NSArray *)groups forType:(SocialNetworkType)type;

@end

@interface WDDStatusSNAccountsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (assign, nonatomic) SocialNetworkType socialNetworkType;
@property (weak, nonatomic) id <WDDStatusSNAccountsDelegate> delegate;

@property (strong, nonatomic) NSMutableArray *selectedAccounts;
@property (strong, nonatomic) NSMutableArray *selectedGroups;

@end
