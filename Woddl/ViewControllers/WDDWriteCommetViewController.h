//
//  WDDWriteCommetViewController.h
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PullTableView.h"

#import "WDDLinkShorterViewController.h"

@class Post;
@interface WDDWriteCommetViewController : WDDLinkShorterViewController
{
    NSUInteger commentTextViewHeight;
    NSUInteger normalCommentTextViewHeight;
    NSUInteger normalCommentBarViewHeight;
    CGRect keyboardRect;
    CGRect myImageRect;
    UISwipeGestureRecognizer* keyboardHideSwipeRecognizer;
    NSIndexPath *copyCommentIndexPath;
}

@property(nonatomic,strong) IBOutlet UIView* addCommentView;
@property(nonatomic,strong) IBOutlet UIImageView* myAvatarImageView;
@property(nonatomic,strong) IBOutlet UIImageView* backCommentBarImageView;
@property(nonatomic,strong) IBOutlet UIImageView* backTextCommentBarImageView;
@property(nonatomic,strong) IBOutlet UIView* commentView;
@property(nonatomic,strong) IBOutlet PullTableView* commentsTable;
@property(nonatomic,strong) IBOutlet UIImageView* myAvaPlaceholder;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *counterWidthConstraint;
@property (weak, nonatomic) IBOutlet UILabel *counterLabel;

@property (nonatomic, strong) Post* post;

-(IBAction)sendPressed:(id)sender;

@end
