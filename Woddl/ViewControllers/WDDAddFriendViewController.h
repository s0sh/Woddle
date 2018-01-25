//
//  WDDAddFriendViewController.h
//  Woddl
//
//  Created by Sergii Gordiienko on 26.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WDDAddFriendDelegate <NSObject>
- (void)didAddFriendWithName:(NSString *)friendName;
@end

@interface WDDAddFriendViewController : UIViewController

@property (weak, nonatomic) id <WDDAddFriendDelegate> delegate;
@property (strong, nonatomic) NSArray *socialNetworks;
@end
