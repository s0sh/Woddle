//
//  WDDTwitterReplyViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDTwitterReplyViewController.h"
#import "Post.h"
#import <QuartzCore/QuartzCore.h>
#import "TwitterPost.h"
#import "SAMHUDView.h"
#import "UserProfile.h"
#import <SDWebImage/SDWebImageManager.h>
#import "SocialNetwork.h"
#import "WDDWebViewController.h"
#import "WDDSearchViewController.h"
#import "WDDURLShorter.h"
#import "Tag.h"

@interface WDDTwitterReplyViewController () < UITextViewDelegate,
                                              UIImagePickerControllerDelegate,UINavigationControllerDelegate, UIActionSheetDelegate, OHAttributedLabelDelegate>
{
    UIImagePickerController *picker;
    UIImage* selectedImage;
}

@property (strong, nonatomic) SAMHUDView *progressHUD;
@property (assign, nonatomic, getter = isCameraMediaSource) BOOL cameraMediaSource;
@property (assign, nonatomic, getter = shouldResetFontToNormal) BOOL resetFontToNormal;
@end

@implementation WDDTwitterReplyViewController

static const NSInteger kIntendFromEdgeTextPost = 8;
static const NSInteger kIntendFromBottEdgeCommViewToBackTextImage = 35;
static const NSInteger kIntendFromBackTextImageToTextView = 10;
static const NSInteger kIntendFromBottEdgeCommViewToCameraBut = 5;
static const NSInteger kMaxCountOfCharactersInText = 140;
static const NSInteger kCountOfCharactersForImage = 23;
static NSString * kPlaceholderText;

@synthesize postTextView;
@synthesize post = _post;
@synthesize twitterPostView;
@synthesize twitterPostBackImageView;
@synthesize commentView;
@synthesize commentBackImageView;

#pragma mark - lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"lskNewReplyText", @"NEW REPLY");
    
    kPlaceholderText = NSLocalizedString(@"lskWriteCommentText", @"Write comment...");
    
    NSMutableAttributedString *postAtrString = [[NSMutableAttributedString alloc] initWithString:self.post.text attributes:@{NSFontAttributeName : [WDDMainPostCell messageTextFont]}];
    for (Tag *tag in self.post.tags)
    {
        NSString *regexString = [NSString stringWithFormat:@"%@([^\\w]|$)", tag.tag];
        NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:nil];
        NSArray *matches = [regex matchesInString:self.post.text options:0 range:NSMakeRange(0, [self.post.text length])];
        for (NSTextCheckingResult *match in matches)
        {
            NSRange matchRange = [match range];
            NSString *tagString = [tag.tag stringByReplacingOccurrencesOfString:@" "  withString:@"."];
            [postAtrString setLink:[NSURL URLWithString:[kTagURLBase stringByAppendingString:tagString]]
                             range:matchRange];
        }
    }
    [self highlightNamesInText:postAtrString inPost:self.post];
    
    
    self.originalPostViewHeightConstraint.constant = [self sizeForText:postAtrString withFont:[self boldMessageTextFont]].height+2*kIntendFromEdgeTextPost;
    self.originalPostViewBottomOffsetConstraint.constant = 0.0f;
    
    self.postLabel.linkColor = [UIColor blackColor];
    self.postLabel.linkUnderlineStyle = kCTUnderlineStyleNone | kOHBoldStyleTraitSetBold;
    self.postLabel.extendBottomToFit=YES;
    self.postLabel.delegate = self;
    self.postLabel.attributedText = postAtrString;
    
    commentBackImageView.image = [[UIImage imageNamed:@"TwitterReply_message"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 25, 25, 25)];
    
    CAGradientLayer *bgLayer = [self gradient];
    bgLayer.frame = twitterPostBackImageView.bounds;
    [twitterPostBackImageView.layer insertSublayer:bgLayer atIndex:0];
    if(self.additionalText)
    {
        /*if(self.additionalText.length+2>kMaxCountOfCharactersInText)
        {
            self.additionalText = [[self.additionalText substringToIndex:kMaxCountOfCharactersInText-5] stringByAppendingString:@"..."];
        }*/
        self.inputTextview.text = [NSString stringWithFormat:@"\"%@\"",self.additionalText];
    }
    else
    {
        self.inputTextview.text = [NSString stringWithFormat:@"@%@ ",self.post.author.name];
    }
    
    NSInteger availableCharsCount;
    if(![self.inputTextview.text isEqualToString:kPlaceholderText])
    {
        availableCharsCount = kMaxCountOfCharactersInText-[[self.inputTextview text] length];
    }
    else
    {
        availableCharsCount = kMaxCountOfCharactersInText;
    }
    self.counterTextField.text = [NSString stringWithFormat:@"%ld",availableCharsCount];
    
    if(availableCharsCount <= 0)
    {
        [self.cameraButton setEnabled:NO];
    }
    
    self.myAvatarImageView.image = [UIImage imageNamed:kAvatarPlaceholderImageName];
    self.myAvatarImageView.image = [UIImage imageNamed:self.post.subscribedBy.avatarRemoteURL];
    [SDWebImageDownloader.sharedDownloader downloadImageWithURL:[NSURL URLWithString:self.post.subscribedBy.avatarRemoteURL] options:0 progress:^(NSInteger receivedSize, NSInteger expectedSize)
     {
         // progression tracking code
     }completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished)
     {
         if (image && finished)
         {
             self.myAvatarImageView.image = image;
         }
     }];
    
    UIImage* sendButtonImage = [UIImage imageNamed:@"SendIcon"];
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.bounds = CGRectMake( 0, 0, sendButtonImage.size.width, sendButtonImage.size.height );
    [customButton setImage:sendButtonImage forState:UIControlStateNormal];
    [customButton addTarget:self action:@selector(sendReplyAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setCustomView:customButton];
    [self customizeBackButton];
    
    [self highlightNamesInText:[self.inputTextview.attributedText mutableCopy]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
//    CGRect screenRect = self.view.frame;
//    
//    NSUInteger textViewHeight = postTextView.contentSize.height;
//    CGRect textViewFrame = postTextView.frame;
//    textViewFrame.size.height = textViewHeight;
//    
//    NSUInteger twitterReplyBackViewHeight = textViewHeight+kIntendFromEdgeTextPost*2;
//    
//    twitterPostView.frame = CGRectMake(twitterPostView.frame.origin.x,screenRect.size.height-twitterReplyBackViewHeight, twitterPostView.frame.size.width, twitterReplyBackViewHeight);
//    commentView.frame = CGRectMake(commentView.frame.origin.x, commentView.frame.origin.y, commentView.frame.size.width, twitterPostView.frame.origin.y - commentView.frame.origin.y);
//    [self resizePostView];
//    [self resizeCommentView];
}

#pragma mark - Bar items action

- (IBAction)sendReplyAction:(UIBarButtonItem *)sender
{
    if(self.inputTextview.text.length>kMaxCountOfCharactersInText)
    {
        [self showAlertView:NSLocalizedString(@"lsklskCharactersLimitExceeded", @"Limit of characters is exceeded.")];
    }
    else
    {
        TwitterPost * twitterPost = (TwitterPost *)self.post;
        NSData *imageData = UIImagePNGRepresentation(selectedImage);
        [self showProcessHUDWithText:NSLocalizedString(@"lskProcessing", @"")];
        [twitterPost replyWithMessage:self.inputTextview.text andImage:imageData andCompletionBlock:^(NSError *error)
         {
             if(!error)
             {
                 [self removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskSuccess", @"")];
                 [self dismiss];
                 /*
                  SocialNetwork* socNetwork = twitterPost.subscribedBy.socialNetwork;
                  [socNetwork getPostsWithCompletionBlock:^(NSError *error) {
                  [self removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskSuccess", @"")];
                  [self dismiss];
                  }];
                  */
             }
             else
             {
                 [self removeProcessHUDOnFailLoginHUDWithText:NSLocalizedString(@"lskFail", @"")];
                 [self dismiss];
             }
         }];
    }
}

#pragma mark - Appearance methods

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Resizing

-(void)resizeCommentView
{
    [commentView layoutSubviews];
    
    commentBackImageView.frame = CGRectMake(commentBackImageView.frame.origin.x, commentBackImageView.frame.origin.y, commentBackImageView.frame.size.width, commentView.frame.size.height-commentBackImageView.frame.origin.y-kIntendFromBottEdgeCommViewToBackTextImage);
    self.inputTextview.frame = CGRectMake(commentBackImageView.frame.origin.x+kIntendFromBackTextImageToTextView, commentBackImageView.frame.origin.y+kIntendFromBackTextImageToTextView, commentBackImageView.frame.size.width-kIntendFromBackTextImageToTextView*2, commentBackImageView.frame.size.height-kIntendFromBackTextImageToTextView*2);
    self.cameraButton.frame = CGRectMake(self.cameraButton.frame.origin.x,commentView.frame.size.height-kIntendFromBottEdgeCommViewToCameraBut-self.cameraButton.frame.size.height, self.cameraButton.frame.size.width, self.cameraButton.frame.size.height);
    self.counterImageView.frame = CGRectMake(self.counterImageView.frame.origin.x,commentView.frame.size.height-kIntendFromBottEdgeCommViewToCameraBut-self.counterImageView.frame.size.height, self.counterImageView.frame.size.width, self.counterImageView.frame.size.height);
    self.counterTextField.frame = self.counterImageView.frame;
}

-(void)resizePostView
{
    [twitterPostView layoutSubviews];
    
    twitterPostBackImageView.frame = CGRectMake(0,0,twitterPostView.frame.size.width, twitterPostView.frame.size.height+5);
    postTextView.frame = CGRectMake(postTextView.frame.origin.x, kIntendFromEdgeTextPost, postTextView.frame.size.width, twitterPostView.frame.size.height - kIntendFromEdgeTextPost*2);
    
    CAGradientLayer *bgLayer = [self gradient];
    bgLayer.frame = twitterPostBackImageView.bounds;
    [twitterPostBackImageView.layer insertSublayer:bgLayer atIndex:0];
}

#pragma mark - Keyboard Appearence

-(void)keyboardWillShow:(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameValue = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrame = [keyboardFrameValue CGRectValue];
    double animationDuration;
    animationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration: animationDuration];
    
    twitterPostView.frame = CGRectMake(twitterPostView.frame.origin.x,twitterPostView.frame.origin.y-keyboardFrame.size.height, twitterPostView.frame.size.width, twitterPostView.frame.size.height);
    commentView.frame = CGRectMake(commentView.frame.origin.x, commentView.frame.origin.y, commentView.frame.size.width, twitterPostView.frame.origin.y - commentView.frame.origin.y);
    [self resizeCommentView];
    [self resizePostView];
    
    [UIView commitAnimations];
}

-(void)keyboardWillHide:(NSNotification*)notification
{
    CGRect screenRect = self.view.frame;
    CGFloat screenHeight = screenRect.size.height;
    double animationDuration;
    animationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration: animationDuration];
    
    twitterPostView.frame = CGRectMake(twitterPostView.frame.origin.x,screenHeight-twitterPostView.frame.size.height, twitterPostView.frame.size.width, twitterPostView.frame.size.height);
    commentView.frame = CGRectMake(commentView.frame.origin.x, commentView.frame.origin.y, commentView.frame.size.width, twitterPostView.frame.origin.y - commentView.frame.origin.y);
    [self resizeCommentView];
    [self resizePostView];
    
    [UIView commitAnimations];
}

#pragma mark - Text View Delegate

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
                              options:0].location != NSNotFound)
    {
        self.resetFontToNormal = YES;
    }
    
    if([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];
        return NO;
    }
    else if([text length] == 0)
    {
        if([textView.text length] != 0)
        {
            return YES;
        }
        else
        {
            return NO;
        }
    }
    else if(selectedImage)
    {
        if([[textView text] length] > kMaxCountOfCharactersInText-kCountOfCharactersForImage-1)
        {
            return NO;
        }
    }
    else if([[textView text] length] > kMaxCountOfCharactersInText-1)
    {
        return NO;
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:kPlaceholderText]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor];
    }
    [textView becomeFirstResponder];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = kPlaceholderText;
        textView.textColor = [UIColor lightGrayColor];
    }
    [textView resignFirstResponder];
}

-(void)textViewDidChange:(UITextView *)textView
{
    [super textViewDidChange:textView];
    
    if([[textView text] length] > kMaxCountOfCharactersInText-kCountOfCharactersForImage)
    {
        if(!selectedImage)
        {
            [self.cameraButton setEnabled:NO];
        }
        else
        {
            [self.cameraButton setEnabled:YES];
        }
    }
    else
    {
        [self.cameraButton setEnabled:YES];
    }
    [self updateCounter];
    
    //  Save cursor position - prevent jumping cursor after highlighting tags and usernames
    NSRange cursorPostion = textView.selectedRange;
    
    [self highlightNamesInText:[textView.attributedText mutableCopy]];
    if (textView.text.length && self.shouldResetFontToNormal)
    {
        NSRange lastCharacterRange = NSMakeRange(textView.text.length-1, 1);
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:textView.attributedText];
        [attributedString setAttributes:@{ NSFontAttributeName:[UIFont systemFontOfSize:kPostFontSize ],
                                           NSForegroundColorAttributeName:[UIColor blackColor]} range:lastCharacterRange];
        textView.attributedText = attributedString;
    }

    //  Reset cursor position after highlighting tags and usernames
    textView.selectedRange = cursorPostion;
}


- (void)highlightNamesInText:(NSMutableAttributedString *)text
{
    [text setAttributes:@{ NSFontAttributeName:[UIFont systemFontOfSize:kPostFontSize ],
                           NSForegroundColorAttributeName:[UIColor blackColor]  }
                  range:NSMakeRange(0, [text length])];
    self.inputTextview.attributedText = text;
    
    NSString *regexString = [NSString stringWithFormat:@"(?:(?<=\\s)|^)(#|@)(\\w*[0-9A-Za-z_]+\\w*)"];
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:nil];
    NSArray *matches = [regex matchesInString:text.string
                                      options:0
                                        range:NSMakeRange(0, [text length])];
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = [match range];
        [text setAttributes:@{ NSFontAttributeName:[UIFont boldSystemFontOfSize:kPostFontSize ],
                               NSForegroundColorAttributeName:[UIColor blackColor] }
                      range:matchRange];
        self.inputTextview.attributedText = text;
    }
}


#pragma mark - Quartz Core Methods

- (CAGradientLayer*) gradient
{
    UIColor *colorOne = [UIColor colorWithRed:(255/256.0) green:(255/256.0) blue:(255/256.0) alpha:1.0];
    UIColor *colorTwo = [UIColor colorWithRed:(246/256.0)  green:(247/256.0)  blue:(246/256.0)  alpha:1.0];
    
    NSArray *colors = [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor, nil];
    
    NSNumber *stopOne = [NSNumber numberWithFloat:0.0];
    NSNumber *stopTwo = [NSNumber numberWithFloat:1.0];
    
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, nil];
    
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
	headerLayer.colors = colors;
	headerLayer.locations = locations;
	
	return headerLayer;
}

#pragma mark - Actions

-(IBAction)cameraButtonPressed:(id)sender
{
    //self.cameraButton.selected = !self.cameraButton.selected;
    if(!selectedImage)
    {
        if(!([[self.inputTextview text] length]>kMaxCountOfCharactersInText-kCountOfCharactersForImage))
        {
            [self showPhotoActionSheet];
        }
    }
    else
    {
        selectedImage = nil;
        self.cameraButton.selected = NO;
        NSInteger availableCharsCount;
        if(![self.inputTextview.text isEqualToString:kPlaceholderText])
        {
            availableCharsCount = kMaxCountOfCharactersInText-[[self.inputTextview text] length];
        }
        else
        {
            availableCharsCount = kMaxCountOfCharactersInText;
        }
        self.counterTextField.text = [NSString stringWithFormat:@"%ld",availableCharsCount];
    }
}

#pragma mark - Picker Delegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.cameraButton.selected = YES;
    selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSInteger availableCharsCount;
    if(![self.inputTextview.text isEqualToString:kPlaceholderText])
    {
        availableCharsCount = kMaxCountOfCharactersInText-[[self.inputTextview text] length]-kCountOfCharactersForImage;
    }
    else
    {
        availableCharsCount = kMaxCountOfCharactersInText-kCountOfCharactersForImage;
    }
    if (self.isCameraMediaSource)
    {
        self.cameraMediaSource = NO;
        UIImageWriteToSavedPhotosAlbum(selectedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
    self.counterTextField.text = [NSString stringWithFormat:@"%ld",availableCharsCount];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
#ifdef DEBUG
    if (!error)
    {
        DLog(@"Image saved to camera roll");
        
    }
    else
    {
        DLog(@"Error saving media: %@", [error localizedDescription]);
    }
#endif
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - HUD methods

- (void)showProcessHUDWithText:(NSString *)text
{
    if (!self.progressHUD)
    {
        self.progressHUD = [[SAMHUDView alloc] initWithTitle:text];
        [self.progressHUD show];
    }
    else
    {
        self.progressHUD.textLabel.text = text;
    }
}

- (void)removeProcessHUDOnSuccessLoginHUDWithText:(NSString *)text
{
    if (self.progressHUD)
    {
        [self.progressHUD completeAndDismissWithTitle:text];
        self.progressHUD = nil;
    }
}

- (void)removeProcessHUDOnFailLoginHUDWithText:(NSString *)text
{
    if (self.progressHUD)
    {
        [self.progressHUD failAndDismissWithTitle:text];
        self.progressHUD = nil;
    }
}

#pragma mark - Action sheet
- (void)showPhotoActionSheet
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"lskImageSource", @"Select camera source type")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"lskCancel", @"Cancel button title")
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"lskTakePhoto", @"Take photo using camera"),
                                  NSLocalizedString(@"lskChooseFromLibrary", @"Selcet photo from library"),nil];
    [actionSheet showInView:self.view];
}

static const NSInteger kActionSheetPhotoCameraButton = 0;
static const NSInteger kActionSheetLibraryCameraButton = 1;

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIImagePickerController *imagePicker =[[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    
    switch (buttonIndex) {
        case kActionSheetPhotoCameraButton:
        {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            {
                self.cameraMediaSource = YES;
                imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                [self presentViewController:imagePicker animated:YES completion:nil];
            }
            else
            {
                [self showAlertView:NSLocalizedString(@"lskCameraNotAvailable", @"Device has not camera")];
            }
        }
            break;
        case kActionSheetLibraryCameraButton:
        {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
            {
                self.cameraMediaSource = NO;
                imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                [self presentViewController:imagePicker animated:YES completion:nil];
            }
            else
            {
                [self showAlertView:NSLocalizedString(@"lskLibraryUnavailable", @"Library is not available")];
            }
        }
            break;
    }
}

- (void)showAlertView:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"lskOK", @"OK button for alert")
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - post height

static const CGFloat MessageWidth = 300.f;

- (CGSize)sizeForText:(id)text withFont:(UIFont *)font
{
    CGSize textSize;
    if (!IS_IOS7)
    {
        NSString *textString = [text isKindOfClass:[NSAttributedString class]] ? [text string] : text;
        
        textSize = [textString sizeWithFont:font constrainedToSize:CGSizeMake(MessageWidth, INFINITY) lineBreakMode:NSLineBreakByWordWrapping];
    }
    else
    {
        if ([text isKindOfClass:[NSAttributedString class]])
        {
            textSize = [(NSAttributedString *)text boundingRectWithSize:CGSizeMake(MessageWidth, INFINITY)
                                                                options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                                context:nil].size;
        }
        else
        {
            textSize = [(NSString *)text boundingRectWithSize:CGSizeMake(MessageWidth, INFINITY)
                                                      options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:@{UITextAttributeFont : font}
                                                      context:nil].size;
        }
    }
    
    //  KOSTYL: Wrong calculation of bondingRectWithSize, especialy for arabic founts
    if (textSize.height < 20.0f)
    {
        textSize.height = 20.0f;
    }
    return textSize;
}

- (UIFont *)messageTextFont
{
    return [UIFont systemFontOfSize:kPostFontSize];
}

- (UIFont *)boldMessageTextFont
{
    return [UIFont boldSystemFontOfSize:kPostFontSize];
}

#pragma mark - OHLabel delegate

-(BOOL)attributedLabel:(OHAttributedLabel*)attributedLabel shouldFollowLink:(NSTextCheckingResult*)linkInfo
{
    NSString *urlString = [linkInfo.URL absoluteString];
    if ([urlString hasPrefix:kTagURLBase])
    {
        NSString *tag = [urlString substringFromIndex:kTagURLBase.length];
#if DEBUG
        DLog(@"Tag: %@", tag);
#endif
        tag = [tag stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        tag = [tag stringByReplacingOccurrencesOfString:@"%23" withString:@"#"];
        [self goToSearchWithTag:tag];
    }
    else if ([urlString hasPrefix:kTwitterNameURLBase])
    {
        NSString *tag = [urlString substringFromIndex:kTwitterNameURLBase.length];
#if DEBUG
        DLog(@"Twitter name: %@", tag);
#endif
        NSString *twitterBaseURL = @"https://twitter.com";
        NSString *twitterProfileURLString = [twitterBaseURL stringByAppendingPathComponent:tag];
        [self openWebViewWithURL:[NSURL URLWithString:twitterProfileURLString]];
    }
    else
    {
        [self openWebViewWithURL:linkInfo.URL];
    }
    
    return NO;
}

- (void)openWebViewWithURL:(NSURL *)url
{
    WDDWebViewController *webController = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDWebViewViewController];
    
    if ([url.absoluteString rangeOfString:@"woddl.it/"].location != NSNotFound)
    {
        url = [[WDDURLShorter defaultShorter] fullLinkForURL:url];
    }
    
    webController.url = url;
    webController.sourceNetwork = self.post.subscribedBy.socialNetwork;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:webController]
                       animated:YES
                     completion:nil];
}

- (void)goToSearchWithTag:(NSString *)tag
{
    tag = [tag stringByReplacingOccurrencesOfString:@"." withString:@" "];
    WDDSearchViewController *searchVC = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDSearchScreen];
    searchVC.searchText = tag;
    //    [searchVC performSelector:@selector(searchBarSearchButtonClicked:) withObject:nil];
    [self.navigationController pushViewController:searchVC animated:YES];
}

- (void)highlightNamesInText:(NSMutableAttributedString *)text inPost:(Post *)post
{
    NSString *regexString = [NSString stringWithFormat:@"(?<=[^a-zA-Z0-9-\\.])@([0-9a-zA-Z_]+)"];
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                            options:NSRegularExpressionCaseInsensitive
                                                                              error:nil];
    NSArray *matches = [regex matchesInString:text.string
                                      options:0
                                        range:NSMakeRange(0, [text length])];
    
    for (NSTextCheckingResult *match in matches)
    {
        NSRange matchRange = [match range];
        NSString *username = [[text.string substringWithRange:matchRange] stringByReplacingOccurrencesOfString:@"@" withString:@""];
        NSString *urlBase = ([post isKindOfClass:[TwitterPost class]] ? kTwitterNameURLBase : kTagURLBase);
        [text setLink:[NSURL URLWithString:[urlBase stringByAppendingString:username]]
                range:matchRange];
    }
}

- (void)updateCounter
{
    NSInteger len = self.inputTextview.text.length;
    if(!selectedImage)
    {
        self.counterTextField.text=[NSString stringWithFormat:@"%ld",kMaxCountOfCharactersInText-len];
    }
    else
    {
        self.counterTextField.text=[NSString stringWithFormat:@"%ld",kMaxCountOfCharactersInText-kCountOfCharactersForImage-len];
        [self.cameraButton setSelected:YES];
    }
}

@end
