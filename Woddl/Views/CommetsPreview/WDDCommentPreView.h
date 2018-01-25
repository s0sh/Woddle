//
//  WDDCommentPreView.h
//  Woddl
//
//  Created by Sergii Gordiienko on 26.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WDDMainPostCell.h"
#import "WDDCommentCell.h"

@class Comment;

@protocol WDDCommentPreviewDelegate <NSObject>

- (void)showCommentUserProfileWithURL:(NSURL *)url;

@optional
- (void)needRelayoutCommentWithID:(NSManagedObjectID *)commentId;

@end

@interface WDDCommentPreView : UIView

@property (weak, nonatomic) id<WDDCommentPreviewDelegate> delegate;
@property (weak, nonatomic) id<OHAttributedLabelDelegate> messageLabeldelegate;

@property (strong, nonatomic) OHAttributedLabel *commentLabel;

- (void)hideSeparator;

- (instancetype)initWithComment:(Comment *)comment;

+ (CGSize)sizeOfViewForComment:(Comment *)comment;

@end
