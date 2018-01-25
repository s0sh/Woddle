//
//  WDDChatViewController.h
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

//#define SHOW_AVATAR_AND_NAME_IN_TITLE

static NSString * const kChatCellID = @"ChatMessageCell";
static NSString * const kTapingCellID = @"TapingCell";

@class XMPPUserCoreDataStorageObject;

@interface WDDChatViewController : UIViewController

@property (nonatomic, strong) XMPPUserCoreDataStorageObject *contact;

@end
