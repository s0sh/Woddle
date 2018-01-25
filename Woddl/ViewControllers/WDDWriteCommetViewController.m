//
//  WDDWriteCommetViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDWriteCommetViewController.h"
#import "WDDWebViewController.h"
#import "WDDSearchViewController.h"
#import "WDDMapViewController.h"
#import "WDDWhoLikedViewController.h"
#import "WDDAddFriendViewController.h"
#import "WDDPhotoPreviewControllerViewController.h"

#import "WDDDataBase.h"
#import "WDDAppDelegate.h"
#import "WDDPreviewManager.h"
#import "WDDURLShorter.h"

#import "Comment.h"
#import "Post.h"
#import "Place.h"
#import "TwitterPost.h"
#import "Tag.h"
#import "InstagramPost.h"

#import "LinkedinPost.h"
#import "SAMHUDView.h"
#import "WDDCommentPreView.h"
#import "WDDCommentCell.h"
#import "WDDPostView.h"

#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <SDWebImage/SDWebImageManager.h>
#import <QuartzCore/QuartzCore.h>
#import <WYPopoverController.h>
#import <MobileCoreServices/UTCoreTypes.h>

#import "UIImageView+WebCache.h"
#import "UIImage+ResizeAdditions.h"
#import "NSCharacterSet+Emoji.h"
#import "UITapGestureRecognizer+MediaInfo.h"


#define POPOVER_COLOR [UIColor colorWithRed:51.0f/255.0f green:51.0f/255.0f blue:51.0f/255.0f alpha:1.0f]

@interface WDDWriteCommetViewController ()< UITextViewDelegate,
                                            NSFetchedResultsControllerDelegate,
                                            UITextViewDelegate,
                                            UITableViewDataSource,
                                            UITableViewDelegate,
                                            WDDMainPostCellDelegate,
                                            UIGestureRecognizerDelegate,
                                            PullTableViewDelegate,
                                            OHAttributedLabelDelegate,
                                            WDDCommentPreviewDelegate,
                                            WDDWhoLikedViewControllerDelegate,
                                            WDDAddFriendDelegate>

@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;

@property (strong, nonatomic) SAMHUDView *progressHUD;
@property (weak, nonatomic) IBOutlet WDDPostView *postView;

@property (strong, nonatomic) MPMoviePlayerController *mediaPlayer;
@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UIButton *closeButton;

@property (assign, nonatomic) NSInteger twitterCharactersLeft;

@property (nonatomic, strong) WYPopoverController *popoverViewController;
@property (assign, nonatomic, getter = shouldResetFontToNormal) BOOL resetFontToNormal;
@property (assign, nonatomic, getter = isLastCharacterEmoji) BOOL lastCharacterEmoji;

@property (nonatomic, assign) BOOL activateInputFieldsOnAppear;

- (void)openWebViewWithURL:(NSURL *)url requiresAuthorization:(BOOL)requiresAuthorization;

@end

static const NSInteger kMaxCountOfCharactersInText = 140;
static const NSInteger kTwitterImageLinkLength =  26;

@implementation WDDWriteCommetViewController


static NSString * const kCommentsMessagesCache = @"PostCommentsCache";
static NSString * const kCommentTimeKey = @"date";
static NSString * kPlaceholderText;
static NSInteger const kMaxCountOfComments = 25;

#pragma mark - lifecycle methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    kPlaceholderText = NSLocalizedString(@"lskWriteCommentText", @"Write comment...");
    
    self.postView.post = self.post;
    self.postView.delegate = self;
    self.postView.textMessage.delegate = self;

    self.activateInputFieldsOnAppear = NO;
    
    [self setupNavigationBarTitle];
    self.twitterCharactersLeft = kMaxCountOfCharactersInText - (self.post.author.name.length+2);
    
    self.postView.previewLinksAsMedia = NO;
    if (!([self.post isKindOfClass:[TwitterPost class]]/* || [self.post isKindOfClass:[InstagramPost class]]*/))
    {
        self.counterWidthConstraint.constant = 0.0f;
        self.postView.previewLinksAsMedia = YES;
    }
    
    self.inputTextview.scrollsToTop = NO;
    
    UIImage* sendButtonImage = [UIImage imageNamed:@"SendIcon"];
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.bounds = CGRectMake( 0, 0, sendButtonImage.size.width, sendButtonImage.size.height );
    [customButton setImage:sendButtonImage forState:UIControlStateNormal];
    [customButton addTarget:self action:@selector(sendPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setCustomView:customButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    self.backTextCommentBarImageView.image = [[UIImage imageNamed:@"FieldComment"] resizableImageWithCapInsets:UIEdgeInsetsMake(25, 10, 5, 10)];
    
    normalCommentTextViewHeight = self.inputTextview.frame.size.height;
    normalCommentBarViewHeight = self.addCommentView.frame.size.height;
    self.addCommentView.hidden = (self.post.subscribedBy.socialNetwork.type.integerValue == kSocialNetworkGooglePlus ||
                                  self.post.subscribedBy.socialNetwork.type.integerValue == kSocialNetworkInstagram);
    
    CAGradientLayer *bgLayer = [self gradient];
    bgLayer.frame = self.backCommentBarImageView.bounds;
    [self.backCommentBarImageView.layer insertSublayer:bgLayer atIndex:0];
    
    self.inputTextview.text = kPlaceholderText;
    self.inputTextview.textColor = [UIColor lightGrayColor];
    
    [self setupPullToRefresh];
    [self customizeBackButton];
    if (self.post)
    {
        [self setupUserAvatar];
    }
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 1.0; //seconds
    lpgr.delegate = self;
    
    self.postView.gestureRecognizers = @[lpgr];
    
    [self setupPopoverAppearance];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Heatmaps trackScreenWithKey:@"503395516a70d21a-21618ac5"];
    
    self.commentsTable.frame = CGRectMake(self.commentsTable.frame.origin.x, self.commentsTable.frame.origin.y, self.commentsTable.frame.size.width, self.addCommentView.frame.origin.y-self.commentsTable.frame.origin.y);
    if (self.activateInputFieldsOnAppear)
    {
        commentTextViewHeight = normalCommentTextViewHeight;
        [self.inputTextview becomeFirstResponder];
        [self resizeCommentBar];
        
        self.activateInputFieldsOnAppear = NO;
    }
}

- (void)setupUserAvatar
{
    CGFloat width = CGRectGetWidth(self.myAvatarImageView.bounds)*[UIScreen mainScreen].scale;
    UIImage *placeHolderImage = [[UIImage imageNamed:kAvatarPlaceholderImageName] thumbnailImage:width
                                                                               transparentBorder:1.0f
                                                                                    cornerRadius:0.0
                                                                            interpolationQuality:kCGInterpolationMedium];
    NSURL *avatarURL = [NSURL URLWithString:self.post.subscribedBy.avatarRemoteURL];
    
    SDWebImageCompletedBlock completion = ^(UIImage *image, NSError *error, SDImageCacheType cacheType)
    {
        if (!error)
        {
            image = [image thumbnailImage:width
                        transparentBorder:1.0f
                             cornerRadius:0.0f
                     interpolationQuality:kCGInterpolationMedium];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.myAvatarImageView.image = image;
            });
        }
    };
    
    [self.myAvatarImageView setImageWithURL:avatarURL
                           placeholderImage:placeHolderImage
                                    options:SDWebImageRefreshCached
                                  completed:completion];
}

- (void)setupPullToRefresh
{
    self.commentsTable.pullDelegate = self;
    self.commentsTable.pullArrowImage = [UIImage imageNamed:@"blackArrow"];
    self.commentsTable.pullBackgroundColor = [UIColor whiteColor];
    self.commentsTable.pullTextColor = [UIColor darkGrayColor];
}

- (void)setupPopoverAppearance
{
    [WYPopoverBackgroundView appearance].fillBottomColor = POPOVER_COLOR;
    [WYPopoverBackgroundView appearance].fillTopColor = POPOVER_COLOR;
    [WYPopoverBackgroundView appearance].borderWidth = 5.0f;
}

#pragma mark - Setters

- (void)setTwitterCharactersLeft:(NSInteger)twitterCharactersLeft
{
    _twitterCharactersLeft = twitterCharactersLeft;
    
    if (twitterCharactersLeft < 0)
    {
        self.counterLabel.textColor = [UIColor redColor];
    }
    else
    {
        self.counterLabel.textColor = [UIColor whiteColor];
    }
    
    self.counterLabel.text = [NSString stringWithFormat:@"%d", twitterCharactersLeft];
}

#pragma mark - Appearance methods

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES
                             completion:nil];
}

#pragma mark - Keyboard Appearence

-(void)keyboardWillShow:(NSNotification*)notification
{
    NSDictionary* keyboardInfo = [notification userInfo];
    NSValue* keyboardFrameValue = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect keyboardFrame = [keyboardFrameValue CGRectValue];
    keyboardRect = keyboardFrame;
    double animationDuration;
    animationDuration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration: animationDuration];
    
    self.addCommentView.frame = CGRectMake(self.addCommentView.frame.origin.x,self.addCommentView.frame.origin.y-keyboardFrame.size.height, self.addCommentView.frame.size.width, self.addCommentView.frame.size.height);
    self.commentsTable.frame = CGRectMake(self.commentsTable.frame.origin.x, self.commentsTable.frame.origin.y, self.commentsTable.frame.size.width, self.addCommentView.frame.origin.y-self.commentsTable.frame.origin.y);
    
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
    
    self.addCommentView.frame = CGRectMake(self.addCommentView.frame.origin.x,screenHeight-self.addCommentView.frame.size.height, self.addCommentView.frame.size.width, self.addCommentView.frame.size.height);
    self.commentsTable.frame = CGRectMake(self.commentsTable.frame.origin.x, self.commentsTable.frame.origin.y, self.commentsTable.frame.size.width, self.addCommentView.frame.origin.y-self.commentsTable.frame.origin.y);
    
    [UIView commitAnimations];
}

#pragma mark - Text View Delegate
/*
-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"])
    {
        [textView resignFirstResponder];   
        return NO;
    }
    return YES;
}
 */

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:kPlaceholderText]) {
        textView.text = @"";
        textView.textColor = [UIColor blackColor]; //optional
    }
//    [textView becomeFirstResponder];
    [self resizeCommentBar];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = kPlaceholderText;
        textView.textColor = [UIColor lightGrayColor]; //optional
    }
    [textView resignFirstResponder];
}

- (void)textViewDidChange:(UITextView *)textView
{
    [super textViewDidChange:textView];
    
    NSRange cursorPostion = textView.selectedRange;
    
    [self highlightTagsInText:[textView.attributedText mutableCopy]];
    
    if (textView.text.length && self.shouldResetFontToNormal && !self.isLastCharacterEmoji)
    {
        NSRange lastCharacterRange = NSMakeRange(textView.text.length-1, 1);
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:textView.attributedText];
        [attributedString setAttributes:@{ NSFontAttributeName:[UIFont fontWithName:@"Helvetica Neue" size:14.f],
                                           NSForegroundColorAttributeName:[UIColor blackColor]} range:lastCharacterRange];
        textView.attributedText = attributedString;
    }
     
    //  Reset cursor position after highlighting tags and usernames
    textView.selectedRange = cursorPostion;
    
    [self resizeCommentBar];
    [self updateCounter];
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (IS_IOS7)
    {
        [textView fixSrollingToLastLineBugInIOS7withText:text];
    }
    
    if ([text rangeOfCharacterFromSet:[NSCharacterSet emojiCharacterSet]
                              options:0].location != NSNotFound)
    {
        self.lastCharacterEmoji = YES;
    }
    else
    {
        self.lastCharacterEmoji = NO;
    }
    
    if ([text rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
                              options:0].location != NSNotFound)
    {
        self.resetFontToNormal = YES;
    }
    
    if ([text isEqualToString:@"@"] && range.location == textView.text.length)
    {
        NSRange range = NSMakeRange((textView.text.length > 0) ? textView.text.length - 1 : 0, MIN(1, textView.text.length));
        NSString *previousCharacter = [textView.text substringWithRange:range];
        previousCharacter = [previousCharacter stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (!previousCharacter.length)
        {
            UINavigationController *addFriendsNavController = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDAddFriendsViewController];
            
            WDDAddFriendViewController *addFriendsController = addFriendsNavController.viewControllers.firstObject;
            addFriendsController.delegate = self;
            addFriendsController.socialNetworks = [[WDDDataBase sharedDatabase] fetchSocialNetworksAscendingWithType:self.post.subscribedBy.socialNetwork.type.integerValue];
            [self presentViewController:addFriendsNavController animated:YES completion:nil];

            return NO;
        }
    }
    
    return YES;
}

- (void)highlightTagsInText:(NSMutableAttributedString *)text
{
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
        [text setAttributes:@{ NSFontAttributeName:[UIFont boldSystemFontOfSize:14],
                               NSForegroundColorAttributeName:[UIColor blackColor] }
                      range:matchRange];
        self.inputTextview.attributedText = text;
    }
}

- (void)updateCounter
{
    self.twitterCharactersLeft = kMaxCountOfCharactersInText - self.inputTextview.text.length - (self.post.author.name.length+2);
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.post.postID like %@", self.post.postID];
    
    [NSFetchedResultsController deleteCacheWithName:kCommentsMessagesCache];
    NSManagedObjectContext *context = [WDDDataBase sharedDatabase].managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Comment class]) inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    fetchRequest.predicate = predicate;
    
    //  Sort descriptors
    NSSortDescriptor *sortDescriptorByTime = [[NSSortDescriptor alloc] initWithKey:kCommentTimeKey ascending:NO];
    
    
    NSArray *sortDescriptors = @[sortDescriptorByTime];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:context
                                                                                                  sectionNameKeyPath:nil
                                                                                                           cacheName:kCommentsMessagesCache];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        DLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.commentsTable beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.commentsTable insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.commentsTable deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.commentsTable;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            //[self configureCell:(WDDMainPostCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            //[tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.commentsTable endUpdates];
    //[self.commentsTable reloadData];
}


#pragma mark - TableView Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Comment *comment = [self.fetchedResultsController objectAtIndexPath:indexPath];
    return [WDDCommentPreView sizeOfViewForComment:comment].height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const kCommentsCellIdentifier = @"CommentCell";
    WDDCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:kCommentsCellIdentifier forIndexPath:indexPath];
    
    Comment *comment = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    WDDCommentPreView *commentPreView = [[WDDCommentPreView alloc] initWithComment:comment];
    commentPreView.delegate = self;
    commentPreView.messageLabeldelegate = self;
    cell.commentPreviewView = commentPreView;
    
    cell.commentPreviewView.backgroundColor = [UIColor whiteColor];
    
    UILongPressGestureRecognizer *lpgrTable = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self action:@selector(handleLongPressTable:)];
    lpgrTable.minimumPressDuration = 1.0; //seconds
    lpgrTable.delegate = self;
    
    cell.gestureRecognizers = @[lpgrTable];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(copyAction:)];
    
    [menuController setMenuItems:[NSArray arrayWithObject:menuItem]];
    [[UIMenuController sharedMenuController] update];
    
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copyAction:))
    {
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
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

#pragma mark - Change Size Methods

-(void)resizeCommentBar
{
    NSUInteger textViewHeight = self.inputTextview.contentSize.height;
    NSInteger numLines = self.inputTextview.contentSize.height / self.inputTextview.font.lineHeight;
    if (textViewHeight != commentTextViewHeight && numLines < 5)
    {
        CGRect textViewFrame = self.inputTextview.frame;
        commentTextViewHeight = textViewHeight;
        
        CGRect screenRect = self.view.frame;
        NSUInteger textSizeDifferent = commentTextViewHeight - normalCommentTextViewHeight;
        NSUInteger updatedCommentBarHeight = normalCommentBarViewHeight+textSizeDifferent;
        NSUInteger updatedYPosition;
        if([self.inputTextview isFirstResponder])
        {
            updatedYPosition = screenRect.size.height - keyboardRect.size.height - updatedCommentBarHeight;
        }
        else
        {
            updatedYPosition = screenRect.size.height - updatedCommentBarHeight;
        }
        [self.addCommentView setFrame:CGRectMake(self.addCommentView.frame.origin.x, updatedYPosition, self.addCommentView.frame.size.width, updatedCommentBarHeight)];
        [self.addCommentView layoutSubviews];
        
        [self.backCommentBarImageView setFrame:CGRectMake(0, 0, self.addCommentView.frame.size.width, updatedCommentBarHeight)];
        CAGradientLayer *bgLayer = [self gradient];
        bgLayer.frame = self.backCommentBarImageView.bounds;
        [self.backCommentBarImageView.layer addSublayer:bgLayer];
        
        textViewFrame.size.height = commentTextViewHeight;
        [self.inputTextview setFrame:textViewFrame];
        [self.backTextCommentBarImageView setFrame:CGRectMake(self.backTextCommentBarImageView.frame.origin.x, self.backTextCommentBarImageView.frame.origin.y, self.backTextCommentBarImageView.frame.size.width, commentTextViewHeight+2)];
        
//        self.myAvatarImageView.frame = myImageRect;
//        self.myAvaPlaceholder.frame = CGRectMake(self.myAvaPlaceholder.frame.origin.x, self.myAvatarImageView.frame.origin.y - 2, self.myAvaPlaceholder.frame.size.width, self.myAvatarImageView.frame.size.height+5);
        self.commentsTable.frame = CGRectMake(self.commentsTable.frame.origin.x, self.commentsTable.frame.origin.y, self.commentsTable.frame.size.width, self.addCommentView.frame.origin.y-self.commentsTable.frame.origin.y);
    }
}

#pragma mark - Quartz Core Methods

- (CAGradientLayer*) gradient
{
    UIColor *colorOne = [UIColor colorWithRed:(245/255.0) green:(245/255.0) blue:(245/255.0) alpha:1.0];
    UIColor *colorTwo = [UIColor colorWithRed:(208/255.0)  green:(208/255.0)  blue:(208/255.0)  alpha:1.0];
    
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

- (IBAction)showWhoLiedList:(UIButton *)sender
{
    if (!self.post.likesCount.integerValue ||
        self.post.subscribedBy.socialNetwork.type.integerValue == kSocialNetworkTwitter ||
        self.post.subscribedBy.socialNetwork.type.integerValue == kSocialNetworkLinkedIN)
    {
        return;
    }
    
    WDDWhoLikedViewController *whoLikedVC = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDWhoLikedViewControllerViewController];
    whoLikedVC.post = self.post;
    whoLikedVC.delegate = self;
    
    WYPopoverTheme *theme = [WYPopoverTheme themeForIOS7];
    theme.tintColor = whoLikedVC.view.backgroundColor;
    
    WYPopoverController *popover = [[WYPopoverController alloc] initWithContentViewController:whoLikedVC];
    CGFloat likersListHeight = (self.post.likedBy.count ? self.post.likedBy.count : self.post.likesCount.integerValue) * 44.f;
    if (likersListHeight < 0.001 || likersListHeight > 220.f)
    {
        likersListHeight = 5.f * 44.f;
    }
    popover.theme = theme;
    
    CGRect likersListRect = (CGRect){CGPointZero, CGSizeMake(240.f, likersListHeight)};
    whoLikedVC.view.frame = likersListRect;
    popover.popoverContentSize = likersListRect.size;
    self.popoverViewController = popover;
    
    [popover presentPopoverFromRect:sender.bounds
                             inView:sender
           permittedArrowDirections:WYPopoverArrowDirectionUp
                           animated:YES];
}

-(IBAction)sendPressed:(id)sender
{
    if (!self.inputTextview.text.length || [self.inputTextview.text isEqualToString:kPlaceholderText])
    {
        return ;
    }
    
    __weak WDDWriteCommetViewController *wSelf = self;
    
    [self showProcessHUDWithText:NSLocalizedString(@"lskProcessing", @"")];
    [self.post addCommentWithMessage:self.inputTextview.text andCompletionBlock:^(NSDictionary *info)
    {
        [wSelf.postView updateViewContent];
        
        [wSelf removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskSuccess", @"")];
        [wSelf resetCommentBar];
    }
                       withFailBlock:^(NSError *error)
    {
        //NSLocalizedFailureReason=ended in the number of requests
        [wSelf removeProcessHUDOnFailLoginHUDWithText:NSLocalizedString(@"lskFail", @"")];
        if([[error localizedFailureReason] isEqualToString:@"ended in the number of requests"])
        {
            [UIAlertView showAlertWithMessage:NSLocalizedString(@"lskEnterRequestsNumber", @"")];
        }
        if (error.code == kErrorCodeTwitterCommentFailed)
        {
            [UIAlertView showAlertWithMessage:NSLocalizedString(@"lskCharactersLimitExceeded", @"")];
        }
    }];
}

#pragma mark - Reset

-(void)resetCommentBar
{
    [self.inputTextview setText:@""];
    [self.inputTextview layoutSubviews];
    [self resizeCommentBar];
    [self.inputTextview resignFirstResponder];
    self.twitterCharactersLeft = kMaxCountOfCharactersInText - (self.post.author.name.length+2);
}

#pragma mark - Message cell delegate protocol implementation

- (void)showFullImageWithURL:(NSURL *)url previewURL:(NSURL *)previewURL fromCell:(WDDMainPostCell *)cell
{
    WDDPhotoPreviewControllerViewController *previewController = [[WDDPhotoPreviewControllerViewController alloc] initWithImageURL:url previewURL:previewURL];
    previewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.navigationController presentViewController:previewController animated:YES completion:nil];
}

- (void)showFullVideoWithURL:(NSURL *)url fromCell:(WDDMainPostCell *)cell
{
    NSString *urlString = [NSString stringWithFormat:@"%@", url];
    NSRange rangeOfSubstring = [urlString rangeOfString:@"youtu"];
    
    if (rangeOfSubstring.location != NSNotFound)
    {
        self.webView = [[UIWebView alloc] init];
        [self.view addSubview:self.webView];
        self.webView.frame = self.view.bounds;
        
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.closeButton setBackgroundColor:[UIColor blackColor]];
        [self.closeButton setTitle:@"lskClose" forState:UIControlStateNormal];
        [self.closeButton addTarget:self action:@selector(hideWebView) forControlEvents:UIControlEventTouchUpInside];
        self.closeButton.layer.cornerRadius = 5;
        [self.view addSubview:self.closeButton];
        self.closeButton.frame = CGRectMake(5, 70, 70, 35);
    }
    else
    {
        CGFloat offset = 10.f;
        CGFloat closeButtonSize = 30.f;
        
        UIView *backgroundView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        backgroundView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.8];
        backgroundView.userInteractionEnabled = YES;
        
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        closeButton.frame = CGRectMake(offset, offset + (IS_IOS7 ? CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) : 0), closeButtonSize, closeButtonSize);
        [closeButton setImage:[UIImage imageNamed:@"CloseIcon"] forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(hideVideoViewver:) forControlEvents:UIControlEventTouchUpInside];
        [backgroundView addSubview:closeButton];
        
        CGRect playerFrame = CGRectZero;
        playerFrame.origin.y = CGRectGetMaxY(closeButton.frame) + offset;
        playerFrame.size.width = CGRectGetWidth(backgroundView.frame);
        playerFrame.size.height= CGRectGetHeight(backgroundView.frame) - playerFrame.origin.y * 2.f;
        
        self.mediaPlayer = [[MPMoviePlayerController alloc] initWithContentURL:url];
        [self.mediaPlayer prepareToPlay];
        
        [self.mediaPlayer.view setFrame:playerFrame];
        [backgroundView addSubview:self.mediaPlayer.view];
        
        [self.parentViewController.view addSubview:backgroundView];
        
        [self.mediaPlayer play];
    }
}

- (void)showLinkWithURL:(NSURL *)url fromCell:(WDDMainPostCell *)cell
{
    [self openWebViewWithURL:url requiresAuthorization:NO];
}

- (void)showUserPageWithURL:(NSURL *)url fromCell:(WDDMainPostCell *)cell
{
    if (!url)
    {
        return;
    }
    
    [self openWebViewWithURL:url requiresAuthorization:YES];
}

- (void)showPostsWithTag:(NSString *)tag fromCell:(WDDMainPostCell *)cell
{
     [self goToSearchWithTag:tag];
}

- (void)showPlaceWithInfo:(NSString *)placeInfo fromCell:(WDDMainPostCell *)cell
{
    NSArray *placeInfoComponents = [placeInfo componentsSeparatedByString:@"_"];
    if (placeInfoComponents.count < 2)
    {
        DLog(@"Error: can't parse place info: %@", placeInfo);
        return;
    }
    NSPredicate *placePredicate = [NSPredicate predicateWithFormat:@"networkType == %@ && placeId == %@", placeInfoComponents[0], placeInfoComponents[1]];
    NSArray *places = [[WDDDataBase sharedDatabase] fetchObjectsWithEntityName:NSStringFromClass([Place class])
                                                                 withPredicate:placePredicate
                                                               sortDescriptors:nil];
    if (places.count)
    {
        WDDMapViewController *mapController = [[WDDMapViewController alloc] initWithPlace:places.firstObject];
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:mapController]
                           animated:YES
                         completion:nil];
        
    }
}

- (void)hideWebView
{
    [self.webView removeFromSuperview];
    self.webView = nil;
    [self.closeButton removeFromSuperview];
    self.closeButton = nil;
}


- (void)showEventWithEventURL:(NSURL *)url fromCell:(WDDMainPostCell *)cell
{
    [self openWebViewWithURL:url requiresAuthorization:YES];
}

#pragma mark - WDDCommentPreviewDelegate protocol implementation

- (void)showCommentUserProfileWithURL:(NSURL *)url
{
    if (!url)
    {
        return ;
    }
    
    [self openWebViewWithURL:url requiresAuthorization:YES];
}

- (void)needRelayoutCommentWithID:(NSManagedObjectID *)commentId
{
    Comment *comment = (Comment *)[[WDDDataBase sharedDatabase].managedObjectContext existingObjectWithID:commentId
                                                                                                    error:nil];
    if (comment)
    {
        NSIndexPath *indexPath = [self.fetchedResultsController indexPathForObject:comment];
        if (indexPath)
        {
            [self.commentsTable reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

#pragma mark - Media viewver controll methods

- (void)hideImageViewer:(UIGestureRecognizer *)sender
{
    [UIView animateWithDuration:0.1 animations:^{
        
        [sender.view removeFromSuperview];
    }];
}

- (void)hideVideoViewver:(id)sender
{
    [self.mediaPlayer stop];
    [UIView animateWithDuration:0.1f
                     animations:^{
                         [self.mediaPlayer.view.superview removeFromSuperview];
                     } completion:^(BOOL finished) {
                         
                         if (finished)
                         {
                             self.mediaPlayer = nil;
                         }
                     }];
}

#pragma mark - PullTableViewDelegate

- (void)pullTableViewDidTriggerRefresh:(PullTableView *)pullTableView
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][0];
    
    //  if there are no any comments - comment == nil
    //  Call when loading is finished
    
    __weak WDDWriteCommetViewController *w_self = self;
    
    [self.post commentsRefreshWithComplationBlock:^(NSError *error) {

        w_self.commentsTable.pullLastRefreshDate = [NSDate date];
        w_self.commentsTable.pullTableIsRefreshing = NO;
        [w_self.postView updateViewContent];
    }];
    
    //[self performSelector:@selector(refreshedTable) withObject:nil afterDelay:3.0f];
}

- (void)pullTableViewDidTriggerLoadMore:(PullTableView *)pullTableView
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][0];
    
    __weak WDDWriteCommetViewController *w_self = self;
    
    if(self.post.subscribedBy.socialNetwork.type.integerValue == kSocialNetworkTwitter)
    {
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][0];
        
        NSString* lastCommentID = self.post.postID;
        if([sectionInfo numberOfObjects])
        {
            for(int i = 0;i<[sectionInfo numberOfObjects];i++)
            {
                NSIndexPath *postPath = [NSIndexPath indexPathForRow:i inSection:0];
                Comment* commentInTable = [self.fetchedResultsController objectAtIndexPath:postPath];
                lastCommentID = commentInTable.commentID;
            }
        }
        TwitterPost* twitterPost = (TwitterPost*)self.post;
        [twitterPost commentsLoadMoreFrom:lastCommentID to:2 withComplationBlock:^(NSError *error) {
            w_self.commentsTable.pullTableIsLoadingMore = NO;
            [w_self.postView updateViewContent];
        }];
    }
    else
    {
        [self.post commentsLoadMoreFrom:[sectionInfo numberOfObjects] to:kMaxCountOfComments withComplationBlock:^(NSError *error) {
            w_self.commentsTable.pullTableIsLoadingMore = NO;
            [w_self.postView updateViewContent];
        }];
    }
}

#pragma mark - Refresh and load more methods

- (void) refreshedTable
{
    self.commentsTable.pullLastRefreshDate = [NSDate date];
    self.commentsTable.pullTableIsRefreshing = NO;
}

- (void) loadedMoreDataToTable
{
    self.commentsTable.pullTableIsLoadingMore = NO;
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
        [self openWebViewWithURL:[NSURL URLWithString:twitterProfileURLString] requiresAuthorization:YES];
    }
    
    else if ([urlString hasPrefix:kInstagramNameURLBase])
    {
        NSString *tag = [urlString substringFromIndex:kInstagramNameURLBase.length];
        NSString *instagramBaseURL = @"http://instagram.com";
        NSString *instagramProfileURLString = [instagramBaseURL stringByAppendingPathComponent:tag];
        [self openWebViewWithURL:[NSURL URLWithString:instagramProfileURLString] requiresAuthorization:YES];
    }
    else
    {
        [self openWebViewWithURL:linkInfo.URL requiresAuthorization:NO];
    }
    
    return NO;
}

- (void)openWebViewWithURL:(NSURL *)url requiresAuthorization:(BOOL)requiresAuthorization
{
    WDDWebViewController *webController = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDWebViewViewController];
    
    if ([url.absoluteString rangeOfString:@"woddl.it/"].location != NSNotFound)
    {
        url = [[WDDURLShorter defaultShorter] fullLinkForURL:url];
    }
    
    webController.url = url;
    webController.sourceNetwork = self.post.subscribedBy.socialNetwork;
    webController.requireAuthorization = requiresAuthorization;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:webController]
                       animated:YES
                     completion:nil];
}

- (void)goToSearchWithTag:(NSString *)tag
{
    tag = [tag stringByReplacingOccurrencesOfString:@"." withString:@" "];
    WDDSearchViewController *searchVC = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDSearchScreen];
    searchVC.searchText = tag;
    [self.navigationController pushViewController:searchVC animated:YES];
}

#pragma mark - Gesture Recognizer

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        CGPoint location = [gestureRecognizer locationInView:[gestureRecognizer view]];
        UIMenuController *menuController = [UIMenuController sharedMenuController];
        
        NSString* menuCopyTitle = NSLocalizedString(@"lskCopyTextOfMenu", "Text Copy");
        
        UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:menuCopyTitle action:@selector(copyAction:)];
        
        [menuController setMenuItems:[NSArray arrayWithObject:menuItem]];
        
        [menuController setTargetRect:CGRectMake(location.x, location.y, 0.0f, 0.0f) inView:[gestureRecognizer view]];
        [menuController setMenuVisible:YES animated:YES];
    }
}

-(void)handleLongPressTable:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        CGPoint p = [gestureRecognizer locationInView:self.commentsTable];
        
        NSIndexPath *indexPath = [self.commentsTable indexPathForRowAtPoint:p];
        if (indexPath)
        {
            copyCommentIndexPath = indexPath;
            CGPoint location = [gestureRecognizer locationInView:[gestureRecognizer view]];
            UIMenuController *menuController = [UIMenuController sharedMenuController];
            
            
            NSString* menuCopyTitle = NSLocalizedString(@"lskCopyTextOfMenu", "Text Copy");
            
            UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:menuCopyTitle action:@selector(copyActionTable:)];
            
            [menuController setMenuItems:[NSArray arrayWithObject:menuItem]];
            
            [menuController setTargetRect:CGRectMake(location.x, location.y, 0.0f, 0.0f) inView:[gestureRecognizer view]];
            [menuController setMenuVisible:YES animated:YES];
        }
    }
}


-(void)copyAction:(id)sender
{
     [[UIPasteboard generalPasteboard] setValue:self.post.text forPasteboardType:(__bridge NSString*)kUTTypeUTF8PlainText];
}

-(void)copyActionTable:(id)sender
{
    WDDCommentCell *cell = (WDDCommentCell *)[self.commentsTable cellForRowAtIndexPath:copyCommentIndexPath];
    
    OHAttributedLabel *label = cell.commentPreviewView.commentLabel;
    
    if (label.text)
    {
        [[UIPasteboard generalPasteboard] setValue:cell.commentPreviewView.commentLabel.text forPasteboardType:(__bridge NSString*)kUTTypeUTF8PlainText];
    }
    else if (label.attributedText)
    {
        [[UIPasteboard generalPasteboard] setValue:cell.commentPreviewView.commentLabel.attributedText.string forPasteboardType:(__bridge NSString*)kUTTypeUTF8PlainText];
    }
    
}

- (BOOL) canPerformAction:(SEL)selector withSender:(id) sender
{
    
    if (selector == @selector(copyAction:) || selector == @selector(copyActionTable:))
    {
        return YES;
    }
    
    return NO;
}

- (BOOL) canBecomeFirstResponder {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - WDDWhoLikedViewControllerDelegate protocol implementation

- (void)contentUpdatedInController:(WDDWhoLikedViewController *)controller
{
    [self.post.managedObjectContext refreshObject:self.post mergeChanges:YES];
    self.postView.post = self.post;
    [self.postView updateViewContent];
    
    CGFloat likersListHeight = controller.post.likedBy.count * 44.f;
    if (likersListHeight < 0.001 || likersListHeight > 220.f)
    {
        likersListHeight = 5.f * 44.f;
    }
    
    CGRect likersListRect = (CGRect){CGPointZero, CGSizeMake(240.f, likersListHeight)};
    controller.view.frame = likersListRect;
    self.popoverViewController.popoverContentSize = likersListRect.size;
}

- (void)dismissController:(WDDWhoLikedViewController *)controller
{
    [self.popoverViewController dismissPopoverAnimated:YES];
}

#pragma mark - WDDAddFriendDelegate
- (void)didAddFriendWithName:(NSString *)friendName
{
    if (friendName.length)
    {
        NSString *formatString = @" %@ ";
        
        if ([self.inputTextview.text isEqualToString:kPlaceholderText])
        {
            self.inputTextview.text = @"";
            formatString = @"%@ ";
        }
        
        NSString *friendNameString = [NSString stringWithFormat:formatString, friendName];
        
        NSMutableAttributedString *friendNameAtrString = [[NSMutableAttributedString alloc] initWithString:friendNameString
                                                                                                attributes:@{ NSFontAttributeName:[UIFont boldSystemFontOfSize:14.f],
                                                                                                              NSForegroundColorAttributeName:[UIColor blackColor] }];
        [friendNameAtrString setAttributes:@{ NSFontAttributeName:[UIFont systemFontOfSize:kPostFontSize ],
                                              NSForegroundColorAttributeName:[UIColor blackColor] }
                                     range:NSMakeRange(friendNameString.length-1 , 1)];
        
        NSMutableAttributedString *compliteAtrString = [[NSMutableAttributedString alloc] initWithAttributedString:self.inputTextview.attributedText];
        [compliteAtrString appendAttributedString:friendNameAtrString];
        self.inputTextview.attributedText = compliteAtrString;
        
        self.activateInputFieldsOnAppear = YES;
        [self updateCounter];
    }
}

@end
