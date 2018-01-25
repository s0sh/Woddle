//
//  WDDChatMessageCell.h
//  Woddl
//
//  Created by Petro Korenev on 12/2/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SHOW_AVATAR

@class XMPPMessageArchiving_Message_CoreDataObject;

@interface WDDChatMessageCell : UITableViewCell

@property (strong, nonatomic) UIImage *avatar;

@property (strong, nonatomic) XMPPMessageArchiving_Message_CoreDataObject *message;

- (void)setupSubviews;

+ (CGFloat)heightForCellWithText:(NSString *)text;

@end
