//
//  WDDLocationTableViewCell.h
//  Woddl
//
//  Created by Sergii Gordiienko on 16.04.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const WDDLocationTableViewCellIdentifier;

@interface WDDLocationTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *locationLabel;

@end
