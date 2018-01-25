//
//  WDDTwitterReplyViewController.h
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OHAttributedLabel.h>

#import "WDDLinkShorterViewController.h"

@class Post;

@interface WDDTwitterReplyViewController : WDDLinkShorterViewController

@property(nonatomic,strong) IBOutlet UIImageView* myAvatarImageView;
@property(nonatomic,strong) IBOutlet UIImageView* commentBackImageView;
@property (weak, nonatomic) IBOutlet OHAttributedLabel *postLabel;
@property(nonatomic,strong) IBOutlet UITextView* postTextView;
@property(nonatomic,strong) IBOutlet UIView* twitterPostView;
@property(nonatomic,strong) IBOutlet UIImageView* twitterPostBackImageView;
@property(nonatomic,strong) IBOutlet UIView* commentView;
@property(nonatomic,strong) IBOutlet UIButton* cameraButton;
@property(nonatomic,strong) IBOutlet UIImageView* counterImageView;
@property(nonatomic,strong) IBOutlet UITextField* counterTextField;
@property(nonatomic,strong) NSString* additionalText;
@property(nonatomic,strong) Post* post;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *originalPostViewBottomOffsetConstraint;

//  Constaraints

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *originalPostViewHeightConstraint;

-(IBAction)cameraButtonPressed:(id)sender;

@end
