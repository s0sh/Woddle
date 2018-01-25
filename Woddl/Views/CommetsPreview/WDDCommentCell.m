//
//  WDDCommentCell.m
//  
//
//  Created by Sergii Gordiienko on 27.11.13.
//
//

#import "WDDCommentCell.h"
#import <MobileCoreServices/UTCoreTypes.h>
#import "WDDCommentPreView.h"

@interface WDDCommentCell()
@property (weak, nonatomic) IBOutlet UIImageView *separatorImageView;
@end

@implementation WDDCommentCell

- (void)setCommentPreviewView:(UIView *)commentPreviewView
{
    if (_commentPreviewView)
    {
        [_commentPreviewView removeFromSuperview];
    }
    
    _commentPreviewView = (WDDCommentPreView*) commentPreviewView;
    [self addSubview:commentPreviewView];
    [self bringSubviewToFront:self.separatorImageView];
}

- (void)prepareForReuse
{
    if (self.commentPreviewView)
    {
        [self.commentPreviewView removeFromSuperview];
        self.commentPreviewView = nil;
    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(copyAction:))
    {
        return YES;
    }
    
    return NO;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

-(void)copyAction:(id)sender
{
    [[UIPasteboard generalPasteboard] setValue:self.commentPreviewView.commentLabel.text forPasteboardType:(__bridge NSString*)kUTTypeUTF8PlainText];
}

@end
