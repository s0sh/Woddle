//
//  WDDStatusViewController.h
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WDDLinkShorterViewController.h"

@interface WDDStatusViewController : WDDLinkShorterViewController
{
    BOOL isTwitterButtonEnabled;
    BOOL isLinkedinButtonEnabled;
    BOOL isFoursquareButtonEnabled;
}

- (IBAction)setActiveNetwork:(UIButton *)sender;
@property (assign, nonatomic) NSInteger statusesTaskCounter;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;

@end
