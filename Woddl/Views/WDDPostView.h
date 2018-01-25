//
//  WDDPostView.h
//  Woddl
//
//  Created by Sergii Gordiienko on 27.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WDDMainPostCell.h"

@class Post;
@class OHAttributedLabel;

@interface WDDPostView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIImageView *socialNetworkIcon;
@property (weak, nonatomic) IBOutlet UILabel *authorNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeAgoLabel;
@property (weak, nonatomic) IBOutlet OHAttributedLabel *textMessage;
@property (weak, nonatomic) IBOutlet UILabel *commentsCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *commentsIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *likesCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *likesIconImageView;
@property (nonatomic, weak) IBOutlet UIScrollView *mediaScrollView;
@property (weak, nonatomic) IBOutlet UIImageView *retweetsIcon;
@property (weak, nonatomic) IBOutlet UILabel *retweetsCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *showEventButton;
@property (nonatomic, strong) NSSet *links;
@property (nonatomic, assign) BOOL previewLinksAsMedia;

//  Constaraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaScrollHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaScrollBottomOffset;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *likesIconWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *likesLabelWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentsIconOffset;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentIconWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentsLabelWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaTriangleHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *authorNameRightOffset;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *retweetsLabelWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *showEventInfoButtonHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageLabelHeight;

// Post View - data source
@property (weak, nonatomic) Post *post;
@property (weak, nonatomic) id<WDDMainPostCellDelegate> delegate;

- (void)updateViewContent;
@end
