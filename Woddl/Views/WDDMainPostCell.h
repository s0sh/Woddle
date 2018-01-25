//
//  WDDMainPostCell.h
//  Woddl
//
//  Created by Sergii Gordiienko on 08.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OHAttributedLabel/OHAttributedLabel.h>

typedef enum tagMode
{
    CellModeNormal,
    CellModeExpanded,
    CellModeEvent
} CellMode;

typedef void(^WDDPostCellReuseBlock)(NSIndexPath *indexpath);

@class WDDMainPostCell, Post;

@protocol WDDMainPostCellDelegate <NSObject>

- (void)showFullImageWithURL:(NSURL *)url previewURL:(NSURL *)previewURL fromCell:(WDDMainPostCell *)cell;
- (void)showFullVideoWithURL:(NSURL *)url fromCell:(WDDMainPostCell *)cell;
- (void)showLinkWithURL:(NSURL *)url fromCell:(WDDMainPostCell *)cell;
- (void)showUserPageWithURL:(NSURL *)url fromCell:(WDDMainPostCell *)cell;
- (void)showPostsWithTag:(NSString *)tag fromCell:(WDDMainPostCell *)cell;
- (void)showPlaceWithInfo:(NSString *)placeInfo fromCell:(WDDMainPostCell *)cell;
- (void)showEventWithEventURL:(NSURL *)url fromCell:(WDDMainPostCell *)cell;
- (void)deleteFromReadLaterListFromCell:(WDDMainPostCell *)cell;

@optional

- (void)shouldBeExpanded:(WDDMainPostCell *)cell;

@end

@interface WDDMainPostCell : UITableViewCell

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
@property (weak, nonatomic) IBOutlet UIImageView *arrowIcon;
@property (weak, nonatomic) IBOutlet UIView *commentsView;
@property (weak, nonatomic) IBOutlet UIImageView *retweetsIcon;
@property (weak, nonatomic) IBOutlet UILabel *retweetsCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *showEventButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

// Constaraints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaScrollHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaScrollBottomOffset;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *likesIconOffset;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *likesIconWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *likesLabelWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentsIconOffset;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentIconWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentsLabelWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentsViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *commentsViewBottomOffSet;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mediaTriangleHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *authorNameRightOffset;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *retweetsLabelWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *showEventInfoButtonHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textToMediaOffset;

//  Appearance properties
@property (strong, nonatomic) NSString *likeIconImageName;
@property (strong, nonatomic) NSString *commentsIconImageName;
@property (strong, nonatomic) NSString *authorProfileURLString;
@property (strong, nonatomic) NSAttributedString *fullMessageText;
@property (strong, nonatomic) NSAttributedString *shortMessageText;

@property (weak, nonatomic) id <WDDMainPostCellDelegate> delegate;
@property (strong, nonatomic) Post *snPost;

- (void)setNumberOfComments:(NSNumber *)commentsCount;
- (void)setNumberOfLikes:(NSNumber *)likessCount;
- (void)setMediasList:(NSSet *)medias;
- (void)setRecentCommets:(NSArray *)comments;
- (void)setNumberOfRetweets:(NSNumber *)retweetsCount;
- (void)deleteButtonEnable:(BOOL)enable;

@property (nonatomic, readonly) BOOL isExpandable;
@property (nonatomic, assign) BOOL isExpanded;
@property (nonatomic, assign) BOOL isEvent;

@property (nonatomic, assign, getter = shouldPreviewLinksAsMedia) BOOL previewLinksAsMedia;

@property (nonatomic, copy) WDDPostCellReuseBlock reuseBlock;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;

+ (CGFloat)calculateCellHeightForText:(id)text
                            withMedia:(BOOL)isMedia
                         withComments:(NSArray *)comments
                               inMode:(CellMode)mode
                   shouldPreviewLinks:(BOOL)shouldPreviewLinks;
+ (UIFont *)messageTextFont;
+ (UIFont *)boldMessageTextFont;

@end
