//
//  WDDSearchViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDSearchViewController.h"

#import "WDDDataBase.h"
#import "SocialNetwork.h"
#import "Post.h"
#import "Tag.h"
#import "Comment.h"
#import "TwitterPost.h"
#import "SocialNetworkManager.h"
#import "UIImageView+WebCache.h"
#import "WDDMainPostCell.h"
#import "UIImage+ResizeAdditions.h"
#import "NSDate+TimeAgo.h"
#import "WDDConstants.h"
#import <SDWebImage/SDWebImageManager.h>
#import <MediaPlayer/MediaPlayer.h>
#import "IDSEllipseMenu.h"
#import "WDDEllipseMenuFactory.h"
#import "SAMHUDView.h"
#import <MessageUI/MessageUI.h>
#import "ActionSheetStringPicker.h"
#import "WDDTwitterReplyViewController.h"
#import "WDDWriteCommetViewController.h"
#import <MBProgressHUD.h>

static NSString * const kSearchPostMessagesCache              = @"SearchPostMessagesCache";
static NSString * const kSearchPostCellIdentifier             = @"SearchPosts";

@interface WDDSearchViewController () < NSFetchedResultsControllerDelegate, UITableViewDelegate,
                                        UITableViewDataSource, WDDMainPostCellDelegate,
                                        UISearchBarDelegate, IDSEllipseMenuDelegate, MFMailComposeViewControllerDelegate>


@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navbarHeight;

//@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;
@property (strong, nonatomic) NSIndexPath *expandedCellIndexPath;
@property (strong, nonatomic) NSIndexPath *selectedCellIndexPath;

@property (strong, nonatomic) MPMoviePlayerController *mediaPlayer;
@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UIButton *closeButton;

@property (strong, nonatomic) NSPredicate *searchPredicate;
@property (strong, nonatomic) Post *postForMenu;
@property (strong, nonatomic) MBProgressHUD *searchProgressHUD;

@end

@implementation WDDSearchViewController

- (void)setSearchText:(NSString *)searchText
{
    _searchText = searchText;
}

#pragma mark - lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navbarHeight.constant = 0.0f;
    [self setupNavigationBarTitle];
    self.searchBar.text = self.searchText;
    [self setupPredicateWithText:self.searchText];
    
    [self customizeBackButton];
}

- (void)setupCancelButton
{
    UIBarButtonItem *stopButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Stop", @"")
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(finishSearch)];

    self.navigationItem.rightBarButtonItem = stopButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self observeKeyboard:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self observeKeyboard:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [Heatmaps trackScreenWithKey:@"503395516a70d21a-bb960a54"];
    
    [super viewDidAppear:animated];
    [WDDDataBase sharedDatabase].isSearchProduced = YES;
}

#pragma mark - Keyboar events hadling

- (void)observeKeyboard:(BOOL)observe
{
    if (observe)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    }
}

- (void)keyboardWillChangeFrame:(NSNotification*)note
{
    CGRect  frame               = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat animationDuration   = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    CGFloat keyboardHeight      = CGRectGetMaxY([[UIScreen mainScreen] bounds]) - CGRectGetMinY(frame);
    
    self.keyboardHeight.constant = keyboardHeight/* + (([[[UIDevice currentDevice] systemVersion] floatValue] > 6.99f) ? 0.0f : 20.0f)*/;
    
    [UIView animateWithDuration:animationDuration animations:^(void)
     {
         [self.view layoutIfNeeded];
     }];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.searchBar.isFirstResponder)
    {
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (super.fetchedResultsController != nil) {
        return super.fetchedResultsController;
    }
    [self setupFetchedResultController];
    
    return super.fetchedResultsController;
}

- (void)reloadTableContent
{
    [self setupFetchedResultController];
}

- (void)setupFetchedResultController
{
    [NSFetchedResultsController deleteCacheWithName:kSearchPostMessagesCache];
    NSManagedObjectContext *context = [WDDDataBase sharedDatabase].managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Post class]) inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    
    //  Sort descriptors
    NSSortDescriptor *sortDescriptorByTime = [[NSSortDescriptor alloc] initWithKey:kPostTimeKey ascending:NO];
    
    
    NSArray *sortDescriptors = @[sortDescriptorByTime];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    [fetchRequest setPredicate:self.searchPredicate];
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:context
                                                                                                  sectionNameKeyPath:nil
                                                                                                           cacheName:kSearchPostMessagesCache];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        DLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    [self.postsTable reloadData];
}




#pragma mark - Search bar delegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
	searchBar.showsScopeBar = YES;
	[searchBar sizeToFit];
    
	[searchBar setShowsCancelButton:YES animated:YES];
    
	return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar
{
    searchBar.showsScopeBar = NO;
    [searchBar sizeToFit];
    
    [searchBar setShowsCancelButton:NO animated:YES];

    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self setupPredicateWithText:searchText];
    [self setupFetchedResultController];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.searchProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    self.searchProgressHUD.removeFromSuperViewOnHide = YES;
    self.searchProgressHUD.labelText = NSLocalizedString(@"lskSearching", @"Searching posts in internet and in local base");
    
    [self.view addSubview:self.searchProgressHUD];
    [self.searchProgressHUD show:YES];
    
    [self setupCancelButton];
    
    [[SocialNetworkManager sharedManager] searchPostWithText:searchBar.text completionBlock:^{
        
        [self finishSearch];
    }];
    
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = nil;
    [self setupPredicateWithText:nil];
    [self setupFetchedResultController];
    [searchBar resignFirstResponder];
}

- (void)setupPredicateWithText:(NSString *)text
{
    if (!text)
    {
        text = @"";
    }
    
    NSPredicate *predicateAuthorName = [NSPredicate predicateWithFormat:@"SELF.author.name contains[cd] %@", text];
    NSPredicate *predicateTags = [NSPredicate predicateWithFormat:@"SELF.tags.tag CONTAINS[cd] %@", text];
    NSPredicate *predicateText = [NSPredicate predicateWithFormat:@"SELF.text CONTAINS[cd] %@", text];
    NSPredicate *predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[predicateAuthorName,
                                                                                 predicateTags,
                                                                                 predicateText]];
    
    NSPredicate *socialNetworksPredicate = [self availableNetworksPredicate];
    if (socialNetworksPredicate)
    {
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, socialNetworksPredicate]];
    }
                     
    self.searchPredicate = predicate;
}

- (void)enableSearchBar
{
    [self.searchBar setUserInteractionEnabled:YES];
}

- (void)disableSearchBar
{
    [self.searchBar setUserInteractionEnabled:NO];
    [self.searchBar resignFirstResponder];
}

- (void)finishSearch
{
    self.navigationItem.rightBarButtonItem = nil;
    self.searchProgressHUD.labelText = NSLocalizedString(@"lskDone", @"Search is finished");
    [self.searchProgressHUD hide:YES];
    
    self.searchProgressHUD = nil;
}

#pragma mark - Long press gesture recognizer

- (void)didLongPressedOnCell:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateBegan)
    {
#ifdef DEBUG
        DLog(@"LongPressed");
#endif
        UITableViewCell *cell = (UITableViewCell *)sender.view;
        
        NSIndexPath *indexPath = [self.postsTable indexPathForCell:cell];
        Post *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
        self.postForMenu = post;
        
        IDSEllipseMenu *menu = [WDDEllipseMenuFactory ellipseMenuForSocialNetworkType:[post.subscribedBy.socialNetwork.type integerValue]
                                                                               inRect:self.postsTable.frame];
        menu.likeAvailable = [post.isLikable boolValue];
        menu.commentAvailable = [post.isCommentable boolValue];
        
        CGRect cellFrame = [self.postsTable rectForRowAtIndexPath:indexPath];
        cellFrame = CGRectOffset(cellFrame, -self.postsTable.contentOffset.x, -self.postsTable.contentOffset.y);
        menu.clearAreaRect = cellFrame;
        menu.startPosition = CGPointMake(CGRectGetMidX(cellFrame), CGRectGetMidY(cellFrame));
        menu.delegate = self;
        
        menu.availableSocialNetworks = [[WDDDataBase sharedDatabase] availableSocialNetworks];
        [self.view addSubview:menu];
        
        [self disableSearchBar];
        [menu showMenuForView:self.postsTable];
    }
}

#pragma mark - Methods for overloading in WDDBasePostViewController

- (NSString *)goToCommentsScreenSegueIdentifier
{
    return kStoryboardSegueIDWriteCommentFromSearch;
}

- (NSString *)goToTwitterReplyScreenSegueIdentifier
{
    return kStoryboardSegueIDTwitterReplyFromSearch;
}

static NSString * const kPostCellIdentifier = @"SearchPosts";
- (NSString *)cellIdentifier
{
    return kPostCellIdentifier;
}

- (void)goToSearchWithTag:(NSString *)tag
{
    if (![tag isEqualToString:self.searchBar.text])
    {
        WDDSearchViewController *searchVC = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDSearchScreen];
        searchVC.searchText = tag;
        [self.navigationController pushViewController:searchVC animated:YES];
    }
}

@end
