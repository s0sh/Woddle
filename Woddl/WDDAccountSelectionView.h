//
//  WDDAccountSelectionView.h
//  Woddl
//
//  Created by Oleg Komaristov on 20.03.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WDDAccountSelectionView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *checkmarkImage;
@property (weak, nonatomic) IBOutlet UIButton *checkButton;

+ (CGFloat)height;

@end
