//
//  WDDContactsViewController.h
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ChatFriendsType)
{
    kChatFriendsTypeAll = 0,
    kChatFriendsTypeOnline,
    kChatFriendsTypeOffline
};

@interface WDDContactsViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIButton * allButton;
@property (nonatomic, strong) IBOutlet UIButton * onlineButton;
@property (nonatomic, strong) IBOutlet UIButton * offlineButton;

@end
