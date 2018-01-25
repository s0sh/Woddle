//
//  WDDGroupCell.h
//  Woddl
//
//  Created by Sergii Gordiienko on 27.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WDDGroupCell;

@protocol WDDGroupCellDelegate

- (void)groupCelldidTapGroupStatusButton:(WDDGroupCell*)cell;

@end

@interface WDDGroupCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *groupNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *groupStatusButton;

@property (weak, nonatomic) id <WDDGroupCellDelegate> delegate;

@end
