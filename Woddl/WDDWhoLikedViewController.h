//
//  WDDWhoLikedViewController.h
//  Woddl
//
//  Created by Oleg Komaristov on 15.02.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Post, WDDWhoLikedViewController;

@protocol WDDWhoLikedViewControllerDelegate <NSObject>

- (void)contentUpdatedInController:(WDDWhoLikedViewController *)controller;
- (void)dismissController:(WDDWhoLikedViewController *)controller;

@end

@interface WDDWhoLikedViewController : UIViewController

@property (nonatomic, strong) Post *post;
@property (nonatomic, weak) id<WDDWhoLikedViewControllerDelegate> delegate;

@end
