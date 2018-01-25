//
//  WDDChatContactCell.h
//  Woddl
//
//  Created by Oleg Komaristov on 30.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WDDChatContactCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatareImageView;
@property (weak, nonatomic) IBOutlet UIImageView *adminAvatareImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *statusImageView;
@property (weak, nonatomic) IBOutlet UILabel *unreadMessageLabel;

@end
