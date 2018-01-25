//
//  WDDChatContactTitle.h
//  Woddl
//
//  Created by Oleg Komaristov on 30.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, TitleStyle)
{
    FacebookTitleStyle = 0,
    WebViewTitleStyle  = 1
};

@interface WDDChatContactTitle : UIView

- (id)initWithAvatar:(UIImage *)avatar name:(NSString *)name style:(TitleStyle)style;
- (id)initWithAvatar:(UIImage *)avatar name:(NSString *)name maximumWidth:(CGFloat)maximumWidth style:(TitleStyle)style;;

- (void)didRotateToInterfaceOrientation:(UIInterfaceOrientation)uiOrientation;

@end
