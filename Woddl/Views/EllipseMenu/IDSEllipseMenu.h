//
//  IDSElipseMenu.h
//  ElipseMenu
//
//  Created by Sergii Gordiienko on 13.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WDDConstants.h"

#define SHOULD_FADE = 1

@protocol IDSEllipseMenuDelegate;
@interface IDSEllipseMenu : UIView

//  Elipse radius
@property (assign, nonatomic) CGFloat aRadius;
@property (assign, nonatomic) CGFloat bRadius;

//  Start point for animation
@property (assign, nonatomic) CGPoint startPosition;

//  Rect showing without blur effect
@property (assign, nonatomic) CGRect  clearAreaRect;

//  Should be provided for displaying right side button with social networks 
@property (assign, nonatomic) SocialNetworkType  availableSocialNetworks;

@property (weak, nonatomic) id <IDSEllipseMenuDelegate> delegate;

@property (assign, nonatomic, getter = isLikeAvailable) BOOL likeAvailable;
@property (assign, nonatomic, getter = isCommentAvailable) BOOL commentAvailable;
@property (assign, nonatomic, getter = isSaveImageAvailable) BOOL saveAvailable;

- (instancetype)initWithFrame:(CGRect)frame;

//  Main methods
- (void)showMenuForView:(UIView *)view;
- (void)hideMenu;

- (NSInteger)tagForImageName:(NSString *)imageName;
@end

@protocol IDSEllipseMenuDelegate <NSObject>
@optional
- (void)didPressedButtonWithTag:(NSInteger)tag inMenu:(IDSEllipseMenu *)menu;
- (void)didHideMenu;
@end
