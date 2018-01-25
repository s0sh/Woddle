//
//  WDDEventsSideMenuCell.h
//  Woddl
//
//  Created by Sergii Gordiienko on 09.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OHAttributedLabel.h>

@interface WDDEventsSideMenuCell : UITableViewCell
@property (weak, nonatomic) IBOutlet OHAttributedLabel *eventInformationLabel;

+ (CGFloat)calculateCellHeightForText:(NSString *)text;
@end