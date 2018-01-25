//
//  WDDAccountSelector.h
//  Woddl
//
//  Created by Oleg Komaristov on 25.03.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WDDAccountSelector;

typedef void (^AccountsSelected)(NSArray *accounts, NSArray *groups, WDDAccountSelector *selector);
typedef void (^AccountsSelectionCanceled)(WDDAccountSelector *selector);

@interface WDDAccountSelector : UIView

@property (nonatomic, strong) NSString *title;

+ (WDDAccountSelector *)selectorWithSocialNetworkType:(SocialNetworkType)networkType
                               selectionCompleteBlock:(AccountsSelected)complete
                               selectionCanceledBlock:(AccountsSelectionCanceled)canceled;
- (void)show;
- (void)hide;

@end
