//
//  WDDAccountSelectorHeaderView.h
//  Woddl
//
//  Created by Oleg Komaristov on 25.03.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WDDAccountSelectorHeaderView : UIView

@property (weak, nonatomic) IBOutlet UILabel *userNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageview;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkImageview;
@property (weak, nonatomic) IBOutlet UIButton *checkButton;

+ (CGFloat)height;

@end
