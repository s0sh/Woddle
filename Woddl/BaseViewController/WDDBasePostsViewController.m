//
//  WDDBasePostsViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 06.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDBasePostsViewController.h"
#import "WDDWebViewController.h"
#import "WDDWriteCommetViewController.h"
#import "WDDTwitterReplyViewController.h"
#import "WDDSearchViewController.h"
#import "WDDPhotoPreviewControllerViewController.h"
#import "WDDMapViewController.h"

#import "NSAttributedString+Attributes.h"
#import "WDDMainPostCell.h"
#import "WDDEllipseMenuFactory.h"
#import "ActionSheetStringPicker.h"
#import "WDDAccountSelector.h"

#import "WDDURLShorter.h"

#import "UIImageView+WebCache.h"
#import "UIImage+ResizeAdditions.h"
#import "NSDate+TimeAgo.h"
#import "UIView+ScrollToTopDisabler.h"

#import "WDDDataBase.h"
#import "Post.h"
#import "Tag.h"
#import "Place.h"
#import "TwitterPost.h"
#import "InstagramPost.h"
#import "GooglePlusPost.h"
#import "Group.h"
#import "Link+Additions.h"

#import "SAMHUDView.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "UIImageView+AvatarLoading.h"

#define bgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0)

//#define IOS_7_TABLE_AUTOLAYOUT

#ifdef IOS_7_TABLE_AUTOLAYOUT
    #define CACHE_CELLS
#endif

@interface WDDBasePostsViewController()


@property (strong, nonatomic) NSIndexPath *expandedCellIndexPath;
@property (strong, nonatomic) NSIndexPath *selectedCellIndexPath;
@property (strong, nonatomic) Post *postForMenu;


@property (strong, nonatomic) SAMHUDView *progressHUD;

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) UIButton *closeButton;

@property (strong, nonatomic) NSURL *videoURL2OpenInWebView;

@property (strong, nonatomic) NSMutableDictionary *postMessagesTexts;

@property (nonatomic, assign) BOOL isChangeProcessing;

#ifdef IOS_7_TABLE_AUTOLAYOUT
@property (strong, nonatomic) NSMutableDictionary *cellCache;
#endif


- (void)openWebViewWithURL:(NSURL *)url socialNetowork:(SocialNetwork *)network requireAuthorization:(BOOL)requireAuthorization;

@end

NSString * const kPostTimeKey    = @"time";
static const NSInteger kMaxCommentsNumberInPrevew = 3;

@implementation WDDBasePostsViewController

static UIImage *placeHolderImage = nil;

#pragma mark - HUD methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.videoURL2OpenInWebView = nil;
    self.postMessagesTexts = [NSMutableDictionary new];
#ifdef IOS_7_TABLE_AUTOLAYOUT
    self.cellCache = [NSMutableDictionary new];
#endif
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.isAppeared = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];    

    if (self.needProcessUpdates)
    {
        BOOL showHUD = (self.progressHUD.superview == nil);
        if (showHUD)
        {
            [self showProcessHUDWithText:NSLocalizedString(@"lskUpdating", @"Updating message on main screen HUD")];
        }
        self.fetchedResultsController.delegate = self;
        [self.fetchedResultsController performFetch:nil];
        [self.postsTable reloadData];
        if (showHUD)
        {
            [self removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskUpdated", @"Updated message on main screen HUD")];
        }
        self.needProcessUpdates = NO;
    }
    
    if (self.videoURL2OpenInWebView)
    {
        [self showVideoInWebWithURL:self.videoURL2OpenInWebView];
        self.videoURL2OpenInWebView = nil;
    }
    else
    {
        self.isAppeared = YES;
    }
}

- (void)didReceiveMemoryWarning
{
    [self.postMessagesTexts removeAllObjects];
}

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

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

#ifdef IOS_7_TABLE_AUTOLAYOUT

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 100.0f;
}

#endif

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
#ifdef IOS_7_TABLE_AUTOLAYOUT
    if (indexPath.section >= [[self.fetchedResultsController sections] count] ||
        indexPath.row >= [(id <NSFetchedResultsSectionInfo>)[self.fetchedResultsController sections][indexPath.section] numberOfObjects])
    {
        return 0.f;
    }
    
    WDDMainPostCell *cell = [tableView dequeueReusableCellWithIdentifier:[self cellIdentifier]];
    if (!cell)
    {
        cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([WDDMainPostCell class]) owner:nil options:nil] firstObject];
    }
    
    [self configureCell:cell atIndexPath:indexPath];
    
#ifdef CACHE_CELLS
    self.cellCache[indexPath] = cell;
#else
    self.cellCache[[NSIndexPath indexPathForRow:0 inSection:1]] = cell;
#endif

    
    CGSize size = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    
    return size.height;
    
#else
    if (indexPath.section >= [[self.fetchedResultsController sections] count] ||
        indexPath.row >= [(id <NSFetchedResultsSectionInfo>)[self.fetchedResultsController sections][indexPath.section] numberOfObjects])
    {
        return 0.f;
    }
    
    Post *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    CellMode mode = CellModeNormal;
    if ([self.expandedCellIndexPath isEqual:indexPath])
    {
        mode = CellModeExpanded;
    }
    else if ([post.type  isEqual: @(kPostTypeEvent)])
    {
        mode = CellModeEvent;
    }
    
    __block NSMutableAttributedString *postMessage = [self.postMessagesTexts objectForKey:post.postID];
    __block NSString *postText = postMessage ? postMessage.string : post.text;

    CGFloat rowHeight = 0.f;

    NSMutableArray *links = [[NSMutableArray alloc] initWithCapacity:post.links.count];
    if (!post.isLinksProcessed.boolValue)
    {
        for (Link *link in post.links)
        {
            if (!link.isShortLink)
            {
                NSURL *linkURL = [NSURL URLWithString:link.url];
                NSURL *cachedLink = [[WDDURLShorter defaultShorter] cachedLinkForURL:linkURL];

                if (cachedLink)
                {
                    if (postMessage.string.length)
                    {
                        [postMessage.mutableString replaceOccurrencesOfString:link.url
                                                                   withString:cachedLink.absoluteString
                                                                      options:NSCaseInsensitiveSearch
                                                                        range:NSMakeRange(0, postMessage.mutableString.length)];
                    }
                    else
                    {
                        postText = [postText stringByReplacingOccurrencesOfString:link.url
                                                                       withString:cachedLink.absoluteString];
                        [links addObject:cachedLink.absoluteString];
                    }
                }
                else
                {
                    if (linkURL.absoluteString)
                    {
                        [links addObject:linkURL.absoluteString];
                    }
                    
                    [[WDDURLShorter defaultShorter] getLinkForURL:linkURL withCallback:nil];
                }
            }
            else
            {
                if (link.url)
                {
                    [links addObject:link.url];
                }
            }

        }
    }
    else if (!postMessage)
    {
        for (Link *link in post.links)
        {
            if (link.url)
            {
                [links addObject:link.url];
            }
        }
    }
    
   
    //  Add group name
    if (!postMessage.length && [post.group.type isEqual:@(kGroupTypeGroup)])
    {
        NSString *fromGroupStringBase = NSLocalizedString(@"lskFromGroupBase", @"From group base string");
        NSString *groupNameTitle =   [NSString stringWithFormat:@"%@: %@\n\r", fromGroupStringBase, post.group.name];
        postText = [groupNameTitle stringByAppendingString:postText];
    }
    
    if (!postMessage.length && [post.group.type isEqual:@(kGroupTypePage)])
    {
        NSString *fromGroupStringBase = NSLocalizedString(@"lskFromPageBase", @"From page base string");
        NSString *groupNameTitle =   [NSString stringWithFormat:@"%@: %@\n\r", fromGroupStringBase, post.group.name];
        postText = [groupNameTitle stringByAppendingString:postText];
    }
    
    if (!postMessage && postText.length)
    {
        postMessage = [[NSMutableAttributedString alloc] initWithString:postText attributes:@{NSFontAttributeName : [WDDMainPostCell messageTextFont]}];
        
        for (NSString *linkString in links)
        {
            NSRange range = [postMessage.string rangeOfString:linkString];
            if (range.location != NSNotFound)
            {
                [postMessage addAttribute:NSFontAttributeName value:[WDDMainPostCell boldMessageTextFont] range:range];
            }
        }
    }
    
    rowHeight = [WDDMainPostCell calculateCellHeightForText:postMessage
                                                  withMedia:post.media.count
                                               withComments:[self getRecentCommentsForPost:post]
                                                     inMode:mode
                                         shouldPreviewLinks:NO/*![post isKindOfClass:[TwitterPost class]]*/];
    
    return rowHeight;
#endif
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
#ifdef IOS_7_TABLE_AUTOLAYOUT
    WDDMainPostCell *cell = self.cellCache[indexPath];
    
    if (!cell)
    {
#else
        WDDMainPostCell *
#endif
        cell = [tableView dequeueReusableCellWithIdentifier:[self cellIdentifier]];
        
        if (!cell)
        {
            cell = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([WDDMainPostCell class]) owner:nil options:nil] firstObject];
        }
        
        [self configureCell:cell atIndexPath:indexPath];
#ifdef IOS_7_TABLE_AUTOLAYOUT
    }
#endif
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Post *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
//    if ([post isKindOfClass:[TwitterPost class]])
//    {
//        [self goToTwitterReplyWithPost:post shouldQoute:NO];
//    }
//    else
//    {
        [self goToCommentScreenWithPost:post];
//    }
    
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - Fetched results controller

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.postsTable beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.postsTable insertRowsAtIndexPaths:@[newIndexPath]
                                   withRowAnimation:UITableViewRowAnimationAutomatic];
        break;
            
        case NSFetchedResultsChangeDelete:
            [self.postsTable deleteRowsAtIndexPaths:@[indexPath]
                                   withRowAnimation:UITableViewRowAnimationAutomatic];
        break;
            
        case NSFetchedResultsChangeMove:
            [self.postsTable moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
        break;
            
        case NSFetchedResultsChangeUpdate:
            [self.postsTable reloadRowsAtIndexPaths:@[indexPath]
                                   withRowAnimation:UITableViewRowAnimationNone];
        break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.postsTable insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                           withRowAnimation:UITableViewRowAnimationAutomatic];
        break;
            
        case NSFetchedResultsChangeDelete:
            [self.postsTable deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                           withRowAnimation:UITableViewRowAnimationAutomatic];
        break;
            
            
        case NSFetchedResultsChangeUpdate:
            [self.postsTable reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                           withRowAnimation:UITableViewRowAnimationAutomatic];
        break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.postsTable endUpdates];
    DLog(@"Feed controller did change content!");
}

#pragma mark - Predicates

- (NSPredicate *)availableNetworksPredicate
{
    NSPredicate *socialNetworksPredicate;
    
    NSArray *availableNetworksPredicates = [self predicatesOfAvailableSocialNetworks];
    if (availableNetworksPredicates.count)
    {
        socialNetworksPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:availableNetworksPredicates];
    }
    else
    {
        socialNetworksPredicate = [self predicateIfSocialNetworkAvailableWithType:kSocialNetworkUnknown];
    }
    return socialNetworksPredicate;
}

- (NSArray *)predicatesOfAvailableSocialNetworks
{
    NSMutableArray *availableNetworksPredicates = [[NSMutableArray alloc] init];
    NSPredicate *availableSNPredicate;
    
    availableSNPredicate = [self predicateIfSocialNetworkAvailableWithType:kSocialNetworkFacebook];
    if (availableSNPredicate)
    {
        [availableNetworksPredicates addObject:availableSNPredicate];
        availableSNPredicate = nil;
    }
    
    availableSNPredicate = [self predicateIfSocialNetworkAvailableWithType:kSocialNetworkFoursquare];
    if (availableSNPredicate)
    {
        [availableNetworksPredicates addObject:availableSNPredicate];
        availableSNPredicate = nil;
    }
    
    availableSNPredicate = [self predicateIfSocialNetworkAvailableWithType:kSocialNetworkGooglePlus];
    if (availableSNPredicate)
    {
        [availableNetworksPredicates addObject:availableSNPredicate];
        availableSNPredicate = nil;
    }
    
    availableSNPredicate = [self predicateIfSocialNetworkAvailableWithType:kSocialNetworkInstagram];
    if (availableSNPredicate)
    {
        [availableNetworksPredicates addObject:availableSNPredicate];
        availableSNPredicate = nil;
    }
    
    availableSNPredicate = [self predicateIfSocialNetworkAvailableWithType:kSocialNetworkTwitter];
    if (availableSNPredicate)
    {
        [availableNetworksPredicates addObject:availableSNPredicate];
        availableSNPredicate = nil;
    }
    
    availableSNPredicate = [self predicateIfSocialNetworkAvailableWithType:kSocialNetworkLinkedIN];
    if (availableSNPredicate)
    {
        [availableNetworksPredicates addObject:availableSNPredicate];
        availableSNPredicate = nil;
    }
    
    return availableNetworksPredicates;
}

- (NSPredicate *)predicateIfSocialNetworkAvailableWithType:(NSInteger)type
{
    NSPredicate *predicate;
    if ([[WDDDataBase sharedDatabase] activeSocialNetworkOfType:type])
    {
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[[NSPredicate predicateWithFormat:@"SELF.subscribedBy.socialNetwork.type == %@",@(type)],
                                                                         [NSPredicate predicateWithFormat:@"SELF.subscribedBy.socialNetwork.activeState == %@",@YES]]];
    }
    return predicate;
}

#pragma mark - Configure cell
static CGFloat const kAvatarCornerRadious = 2.0f;

- (void)configureCell:(WDDMainPostCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
#ifdef IOS_7_TABLE_AUTOLAYOUT
    cell.currentIndexPath = indexPath;

    __weak typeof(self) weakSelf = self;
    [cell setReuseBlock:^(NSIndexPath *reusingIndexPath)
    {
        if (reusingIndexPath)
        {
            [weakSelf.cellCache removeObjectForKey:reusingIndexPath];
        }
    }];
#endif
    Post *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSString *subscribedByUserId    = post.subscribedBy.userID;
    NSString *postId                = post.postID;
    
    __block NSString *processdText = post.text;
    __block NSMutableAttributedString *postMessage = [self.postMessagesTexts objectForKey:postId];
    
    [self setupAvatarImageInCell:cell forPost:post];
    
    NSMutableArray *linksRanges = [NSMutableArray new];
    NSMutableArray *links = [[NSMutableArray alloc] initWithCapacity:post.links.count];
    
    BOOL allLinksFound = YES;
    NSMutableDictionary *linkPairs = [[NSMutableDictionary alloc] initWithCapacity:post.links.count];
    
    if (!post.isLinksProcessed.boolValue)
    {
        for (Link *link in post.links)
        {
            if (!link.isShortLink)
            {
                NSURL *linkURL = [NSURL URLWithString:link.url];
                NSURL *cachedLink = [[WDDURLShorter defaultShorter] cachedLinkForURL:linkURL];

                if (cachedLink)
                {
                    [linkPairs setObject:cachedLink.absoluteString forKey:link.objectID];
                    
                    if (post.subscribedBy.socialNetwork.type.integerValue != kSocialNetworkTwitter)
                    {
                        [links addObject:cachedLink.absoluteString];
                    }
                    else
                    {
                        if ([Link isURLShort:cachedLink])
                        {
                            [links addObject:cachedLink.absoluteString];
                        }
                    }
                    
                    if (postMessage.string.length)
                    {
                        [postMessage.mutableString replaceOccurrencesOfString:link.url
                                                                   withString:cachedLink.absoluteString
                                                                      options:NSCaseInsensitiveSearch
                                                                        range:NSMakeRange(0, postMessage.mutableString.length)];
                        [postMessage setLink:cachedLink range:[postMessage.mutableString rangeOfString:cachedLink.absoluteString]];
                    }
                    else
                    {
                        processdText = [processdText stringByReplacingOccurrencesOfString:link.url
                                                                               withString:cachedLink.absoluteString];
                    }
                }
                else
                {
                    allLinksFound = NO;
                    if (post.subscribedBy.socialNetwork.type.integerValue != kSocialNetworkTwitter)
                    {
                        [links addObject:link.url];
                    }
                    else
                    {
                        if (link.isShortLink)
                        {
                            [links addObject:link.url];
                        }
                    }
                }
            }
            else
            {
                if (post.subscribedBy.socialNetwork.type.integerValue != kSocialNetworkTwitter)
                {
                    [links addObject:link.url];
                }
                else
                {
                    if ([link.url rangeOfString:@"t.co/"].location != NSNotFound)
                    {
                        [links addObject:link.url];
                    }
                }

            }
        }
        
        if (allLinksFound)
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^()
            {
                NSManagedObjectContext *objectContext = /*[[WDDDataBase sharedDatabase] managedObjectContext];*/[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
                objectContext.parentContext = [WDDDataBase masterObjectContext];
                
                BOOL linksProcessed = YES;
                
                NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([Post class])];
                fr.fetchLimit = 1;
                fr.predicate = [NSPredicate predicateWithFormat:@"subscribedBy.userID = %@ AND postID == %@", subscribedByUserId, postId];
                Post *localPost = (Post *)[[objectContext executeFetchRequest:fr error:nil] firstObject];
                
                for (NSManagedObjectID *linkID in linkPairs.allKeys)
                {
                    NSError *error = nil;
                    Link *link = (Link *)[objectContext existingObjectWithID:linkID
                                                                       error:&error];
                    if (error)
                    {
                        DLog(@"Can't find link in local context because of %@", error.localizedDescription);
                        linksProcessed = NO;
                        break;
                    }
                    link.url = linkPairs[linkID];
                }
                
                if (linksProcessed)
                {
                    NSError *error = nil;
//                    Post *localPost = (Post *)[objectContext existingObjectWithID:post.objectID
//                                                                            error:&error];
                    if (!error)
                    {
                        localPost.text = postMessage ? postMessage.string : processdText;
                        localPost.isLinksProcessed = @YES;
                        
                        error = nil;
                        [objectContext save:&error];
                        if (!error)
                        {
                            [objectContext.parentContext performBlock:^{
                                
                                NSError *error = nil;
                                [objectContext.parentContext save:&error];
                                
                                if (error)
                                {
                                    DLog(@"Can't save master context because of %@", error.localizedDescription);
                                }
                            }];
                        }
                        else
                        {
                            DLog(@"Can't save local context because of %@", error.localizedDescription);
                        }
                    }
                    else
                    {
                        DLog(@"Can't find post in local context because of %@", error.localizedDescription);
                    }
                }
                
            });
        }
    }
    else
    {
        links = [[NSMutableArray alloc] initWithCapacity:post.links.count];
        for (Link *link in post.links)
        {
            if (post.subscribedBy.socialNetwork.type.integerValue != kSocialNetworkTwitter)
            {
                [links addObject:link.url];
            }
            else
            {
                if (link.isShortLink)
                {
                    [links addObject:link.url];
                }
            }
        }
    }
    
    if (!postMessage.string.length)
    {
        if (processdText.length)
        {
            postMessage = [[NSMutableAttributedString alloc] initWithString:processdText
                                                                 attributes:@{NSFontAttributeName : [WDDMainPostCell messageTextFont]}];
        }
        else
        {
            postMessage = [[NSMutableAttributedString alloc] initWithString:@""
                                                                 attributes:@{NSFontAttributeName : [WDDMainPostCell messageTextFont]}];
        }
        
        for (NSString *link in links)
        {
            NSRange linkRange = [processdText rangeOfString:link];
            if (linkRange.location != NSNotFound)
            {
                [linksRanges addObject:[NSTextCheckingResult spellCheckingResultWithRange:linkRange]];
            }
        }
    
        for (NSTextCheckingResult *link in linksRanges)
        {
            [postMessage setLink:[NSURL URLWithString:[postMessage.string substringWithRange:link.range]]
                        range:link.range];
        }
        for (Tag *tag in post.tags)
        {
            NSString *regexString = [NSString stringWithFormat:@"%@([^\\w]|$)", tag.tag];
            NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:nil];
            NSArray *matches = [regex matchesInString:postMessage.string options:0 range:NSMakeRange(0, [postMessage.string length])];
            for (NSTextCheckingResult *match in matches)
            {
                NSRange matchRange = [match range];
                NSString *tagString = [tag.tag stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [postMessage setLink:[NSURL URLWithString:[kTagURLBase stringByAppendingString:tagString]]
                            range:matchRange];
            }
        }
        for (Place *place in post.places)
        {
            NSString *regexString = [NSString stringWithFormat:@"%@([^\\w]|$)", place.name];
            NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:nil];
            NSArray *matches = [regex matchesInString:postMessage.string options:0 range:NSMakeRange(0, [postMessage.string length])];
            for (NSTextCheckingResult *match in matches)
            {
                NSRange matchRange = [match range];
                NSString *placeLink = [NSString stringWithFormat:@"%@%@_%@", kPlaceURLBase, place.networkType.stringValue, place.placeId];
                NSURL *placeURL = [NSURL URLWithString:placeLink];
                [postMessage setLink:placeURL range:matchRange];
            }
        }
        
        [self highlightNamesInText:postMessage inPost:post];
        
        //  Add group name
        if ([post.group.type isEqual:@(kGroupTypeGroup)])
        {
            NSString *fromGroupStringBase = NSLocalizedString(@"lskFromGroupBase", @"From group base string");
            NSMutableAttributedString *groupNameTitle =  [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n\r", fromGroupStringBase, post.group.name]];
            [groupNameTitle appendAttributedString:postMessage];
            postMessage = groupNameTitle;
        }
        
        if ([post.group.type isEqual:@(kGroupTypePage)])
        {
            NSString *fromGroupStringBase = NSLocalizedString(@"lskFromPageBase", @"From page base string");
            NSMutableAttributedString *groupNameTitle =  [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %@\n\r", fromGroupStringBase, post.group.name]];
            [groupNameTitle appendAttributedString:postMessage];
            postMessage = groupNameTitle;
        }
        
        [self.postMessagesTexts s_setObject:postMessage forKey:postId];
    }
    
    cell.snPost = post;
    cell.authorProfileURLString = post.author.profileURL;
    //cell.textMessage.attributedText = postText;
    cell.isExpanded = [indexPath isEqual:self.expandedCellIndexPath];
    cell.fullMessageText = postMessage;
    cell.delegate = self;
    
    
    cell.socialNetworkIcon.image = [UIImage imageNamed:post.socialNetworkIconName];
    cell.authorNameLabel.text = post.author.name;
    cell.timeAgoLabel.text = [post.time timeAgo];
    
    cell.likeIconImageName = [post socialNetworkLikesIconName];
    [cell setNumberOfLikes:([post.isLikable boolValue] ? post.likesCount : nil)];
    
    cell.commentsIconImageName = [post socialNetworkCommentsIconName];
    [cell setNumberOfComments:([post.isCommentable boolValue] ? post.commentsCount : nil)];
    
    NSNumber *numberOfRetweets = nil;
    if ([post respondsToSelector:@selector(retweetsCount)])
    {
        numberOfRetweets = [post performSelector:@selector(retweetsCount)];
    }
    [cell setNumberOfRetweets:numberOfRetweets];
    
    cell.previewLinksAsMedia = !([post isKindOfClass:[TwitterPost class]] || [post isKindOfClass:[InstagramPost class]]);
    [cell setMediasList:post.media];
    [cell setRecentCommets:[self getRecentCommentsForPost:post]];
    
    if ([post.type  isEqual: @(kPostTypeEvent)])
    {
        cell.isEvent = YES;
    }
    
    [cell deleteButtonEnable:[self shouldShowCellDeleteButton]];
    
    //  Long pressed gesture
    [self setupLongTapGestureForCell:cell];
}

- (void)highlightNamesInText:(NSMutableAttributedString *)text inPost:(Post *)post
{
    NSString *regexString = [NSString stringWithFormat:@"(?:(?<=\\s)|^)@(\\w*[0-9A-Za-z_]+\\w*)"];
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
        
        NSString *urlBase;
        if  ([post isKindOfClass:[TwitterPost class]])
        {
            urlBase = kTwitterNameURLBase;
        }
        else if ([post isKindOfClass:[InstagramPost class]])
        {
            urlBase = kInstagramNameURLBase;
        }
        else
        {
            urlBase = kTagURLBase;
        }
        [text setLink:[NSURL URLWithString:[urlBase stringByAppendingString:username]]
                range:matchRange];
    }
}

- (void)setupAvatarImageInCell:(WDDMainPostCell *)cell forPost:(Post *)post
{
    NSURL *avatarURL = [NSURL URLWithString:post.author.avatarRemoteURL];
    [cell.avatarImageView setAvatarWithURL:avatarURL];
}

- (NSArray *)getRecentCommentsForPost:(Post *)post
{
    NSSortDescriptor *sortByDateDesctiptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    NSArray *comments = [post.comments sortedArrayUsingDescriptors:@[sortByDateDesctiptor]];
    
    if ([comments count] > kMaxCommentsNumberInPrevew )
    {
        comments = [comments subarrayWithRange:NSMakeRange([comments count]-kMaxCommentsNumberInPrevew, kMaxCommentsNumberInPrevew)];
    }
    return comments;
}

#pragma mark - Long press gesture recognizer
- (void)setupLongTapGestureForCell:(UITableViewCell *)cell
{
    UILongPressGestureRecognizer * longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressedOnCell:)];
    cell.gestureRecognizers = @[longPressGestureRecognizer];
}

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
        
//        NSSet *images = [post.media filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", @(kMediaPhoto)]];
        menu.saveAvailable = NO;//(images.count > 0);
        
        CGRect cellFrame = [self.postsTable rectForRowAtIndexPath:indexPath];
        cellFrame = CGRectOffset(cellFrame, -self.postsTable.contentOffset.x, -self.postsTable.contentOffset.y - 6.f /*  cells separator height */);
        menu.clearAreaRect = cellFrame;
        menu.startPosition = CGPointMake(CGRectGetMidX(cellFrame), CGRectGetMidY(cellFrame));
        menu.delegate = self;
        
        menu.availableSocialNetworks = [[WDDDataBase sharedDatabase] availableSocialNetworks];
        [self.view addSubview:menu];
        
        [menu showMenuForView:self.postsTable];
    }
}

#pragma mark - Ellipse menu delegate

- (void)didPressedButtonWithTag:(NSInteger)tag inMenu:(IDSEllipseMenu *)menu
{
    [menu hideMenu];
    [self menuActionForButtonWithTag:tag];
    
}

#pragma mark - Ellipse menu logic


- (void)menuActionForButtonWithTag:(NSInteger)tag
{
    if (tag < 1000)
    {
        [self rightSideMenuActionForButtonWithTag:tag];
    }
    else
    {
        [self leftSideMenuActionForButtonWithTag:tag];
    }
    
}

- (void)rightSideMenuActionForButtonWithTag:(NSInteger)tag
{
    switch (tag) {
        case kSocialNetworkFacebook:
            [self postMessageToSocialNetworksWithType:kSocialNetworkFacebook];
            break;
        case kSocialNetworkTwitter:
            [self postMessageToSocialNetworksWithType:kSocialNetworkTwitter];
            break;
        case kSocialNetworkLinkedIN:
            [self postMessageToSocialNetworksWithType:kSocialNetworkLinkedIN];
            break;
        case kSocialNetworkGooglePlus:
            DLog(@"G+ qoute");
            break;
        case kSocialNetworkInstagram:
            DLog(@"Inst qoute");
            break;
        case kSocialNetworkFoursquare:
            DLog(@"4S qoute");
            break;
            
        default:
            DLog(@"Something wrong");
            break;
    }
}

- (void)leftSideMenuActionForButtonWithTag:(NSInteger)tag
{
    switch (tag) {
        case kEllipseMenuLikeButtonTag:
            [self likePost:self.postForMenu];
            break;
        case kEllipseMenuCommentButtonTag:
            [self goToCommentScreenWithPost:self.postForMenu];
            break;
        case kEllipseMenuShareButtonTag:
            [self sharePost:self.postForMenu];
            break;
        case kEllipseMenuMailButtonTag:
            [self showMailViewControllerForPost:self.postForMenu];
            break;
        case kEllipseMenuCopyLinkButtonTag:
            [self copyToClipboardURLFromPost:self.postForMenu];
            break;
        case kEllipseMenuTwitterReplyButtonTag:
            [self goToCommentScreenWithPost:self.postForMenu];
            //[self goToTwitterReplyWithPost:self.postForMenu shouldQoute:NO];
            break;
        case kEllipseMenuTwitterRetweetButtonTag:
            [self retweet:self.postForMenu];
            break;
        case kEllipseMenuTwitterQouteButtonTag:
            [self goToTwitterReplyWithPost:self.postForMenu shouldQoute:YES];
            break;
        case kEllipseMenuBlockButtonTag:
            [self blockActionForPost:self.postForMenu];
            break;
        case kEllipseMenuReadLaterButtonTag:
            [self addToReadLaterListPost:self.postForMenu];
            break;
        case kEllipseMenuSaveImageButtonTag:
            [self saveImagesFromPost:self.postForMenu];
            break;
        default:
            DLog(@"Something wrong");
            break;
    }
}

- (void)postMessageToSocialNetworksWithType:(SocialNetworkType)type
{
    AccountsSelected selectedBlock = ^(NSArray *accounts, NSArray *groups, WDDAccountSelector *selector) {
        
        [selector hide];
        [self showProcessHUDWithText:NSLocalizedString(@"lskSending", @"")];
        
        __block NSInteger cOperations = accounts.count + groups.count;
        __block BOOL isSuccess = YES;
        __block NSManagedObjectID *userId = nil;
        
        ComplationPostBlock postComplition = ^(NSError *error) {
          
            if (error)
            {
                [self showSharingErrorForAcccountWithID:userId];
            }
            
            isSuccess &= !error;
            if (!--cOperations)
            {
                self.postForMenu = nil;
                
                if (!isSuccess)
                {
                    [self removeProcessHUDOnFailLoginHUDWithText:NSLocalizedString(@"lskFail", @"")];
                }
                else
                {
                    [self removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskSuccess", @"")];
                }
            }
        };
        
        for (SocialNetwork *socialNetwork in accounts)
        {
            userId = socialNetwork.profile.objectID;
            [socialNetwork postToWallWithMessage:nil andPost:self.postForMenu withCompletionBlock:postComplition];
        }
        for (Group *group in groups)
        {
            userId = [group.managedBy.anyObject objectID];
            [[group.managedBy.anyObject socialNetwork] postToWallWithMessage:nil post:self.postForMenu toGroup:group withCompletionBlock:postComplition];
        }

    };
    
    AccountsSelectionCanceled canceledBlock = ^(WDDAccountSelector *selector) {
        
        [selector hide];
    };
    
    WDDAccountSelector *selector = [WDDAccountSelector selectorWithSocialNetworkType:type
                                                              selectionCompleteBlock:selectedBlock
                                                              selectionCanceledBlock:canceledBlock];
    selector.title = NSLocalizedString(@"lskSelectNetwork", @"Social network selector on Base controller");
    [selector show];
}

- (void)showSharingErrorForAcccountWithID:(NSManagedObjectID *)profileID
{
    if (!profileID)
    {
        DLog(@"Try to show error with nil profileID");
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UserProfile *profile = (UserProfile *)[[WDDDataBase sharedDatabase].managedObjectContext objectWithID:profileID];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"lskPostSharingError", @"Post sharing error message"), profile.name];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"lskError", @"")
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"lskClose", @"")
                                              otherButtonTitles:nil];
        [alert show];
    });
}

- (void)showMailViewControllerForPost:(Post *)post
{
    if ([MFMailComposeViewController canSendMail])
    {
        
        MFMailComposeViewController *mailViewController = [[MFMailComposeViewController alloc] init];
        mailViewController.mailComposeDelegate = self;
        
        [mailViewController setSubject:NSLocalizedString(@"lksPositInteresting", @"")];
        DLog(@"%@", self.postForMenu.linkURLString);
        NSString *message = [NSString stringWithFormat:@"%@ \r\nURL: %@",(self.postForMenu.text ? self.postForMenu.text : @"" ),self.postForMenu.linkURLString];
        
        [mailViewController setMessageBody:message isHTML:NO];
        
        [self presentViewController:mailViewController animated:YES completion:nil];
    }
    
    else {
        [UIAlertView showAlertWithMessage:NSLocalizedString(@"lskNoOneEmailAccountExist", @"On fail send e-mail")];
        DLog(@"Device is unable to send email in its current state");
    }
}

- (void)blockActionForPost:(Post *)post
{
    if (post.group)
    {
        [self blockGroup:post.group];
    }
    else
    {
        [self blockAuthor:post.author];
    }
    
    [self reloadTableContent];
}

- (void)blockGroup:(Group *)group
{
    BOOL newState = ![group.isGroupBlock boolValue];
    group.isGroupBlock = [NSNumber numberWithBool:newState];
    [[WDDDataBase sharedDatabase] save];
}

- (void)blockAuthor:(UserProfile *)profile
{
    BOOL isBlocked = ![profile.isBlocked boolValue];
    profile.isBlocked = [NSNumber numberWithBool:isBlocked];
    [[WDDDataBase sharedDatabase] save];
}

- (void)likePost:(Post *)post
{
    [self showProcessHUDWithText:NSLocalizedString(@"lskProcessing", @"Progress hud info")];
    void (^completion)(BOOL) = ^(BOOL isLiked)
    {
        [self removeProcessHUDOnSuccessLoginHUDWithText:( isLiked ? NSLocalizedString(@"lskLiked", @"Progress hud info") : NSLocalizedString(@"lskUnliked", @"Progress hud info") )];
    };
    
    void (^errorBlock)(NSError *) = ^(NSError *error)
    {
        if([[error localizedFailureReason] isEqualToString:@"Throttle limit for calls to this resource is reached."])
        {
            [UIAlertView showAlertWithMessage:NSLocalizedString(@"lskEnterRequestsNumber", @"")];
        }
        [self removeProcessHUDOnFailLoginHUDWithText:NSLocalizedString(@"lskFail", @"Progress hud info")];
    };
    
    [self.postForMenu addLikeWithCompletionBlock:completion
                                    andFailBlock:errorBlock];
}

- (void)sharePost:(Post *)post
{
    [self showProcessHUDWithText:NSLocalizedString(@"lskProcessing", @"Progress hud info")];
    [post shareWithCompletionBlock:^(NSError *error) {
        if(!error)
        {
            [self removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskShared", @"Progress hud info")];
        }
        else
        {
            [self removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskFail", @"Progress hud info")];
        }
    }];
}

- (void)retweet:(Post *)post
{
    TwitterPost* twitterPost = (TwitterPost*)post;
    [self showProcessHUDWithText:NSLocalizedString(@"lskProcessing", @"Progress hud info")];
    [twitterPost retweetWithCompletionBlock:^(NSError *error) {
        if(!error)
        {
            [self removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskRetweetSuccess", @"Progress hud info")];
        }
        else
        {
            [self removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskFail", @"Progress hud info")];
        }
    }];
}

- (void)copyToClipboardURLFromPost:(Post *)post
{
    [self showProcessHUDWithText:NSLocalizedString(@"lskProcessing", @"Progress hud info")];
    if (post.linkURLString)
    {
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.URL = [NSURL URLWithString:post.linkURLString];
        [self removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskLinkCopied", @"Progress hud info")];
    }
    else
    {
        [self removeProcessHUDOnFailLoginHUDWithText:NSLocalizedString(@"lskFail", @"Progress hud info")];
    }
}

- (void)addToReadLaterListPost:(Post *)post
{
    post.isReadLater = @YES;
    [[WDDDataBase sharedDatabase] save];
    DLog(@"Post saved to read later list!");
}

- (void)saveImagesFromPost:(Post *)post
{
    NSSet *images = [post.media filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"type == %@", @(kMediaPhoto)]];
    
    [self showProcessHUDWithText:NSLocalizedString(@"lskSaving", @"")];
    
    
    __weak WDDBasePostsViewController *w_self = self;
    __block NSInteger imagesToSave = images.count;
    
    for (Media *media in images)
    {
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:[NSURL URLWithString:media.mediaURLString]
                                                              options:SDWebImageDownloaderHighPriority
                                                             progress:nil
                                                            completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                
                                                                if (finished && !error)
                                                                {
                                                                    [WDDBasePostsViewController addPhotoToGallery:image];
                                                                }
                                                                
                                                                if (!--imagesToSave)
                                                                {
                                                                    [w_self removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskDone", @"")];
                                                                }
                                                            }];
    }
}

+ (void)addPhotoToGallery:(UIImage *)image
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library writeImageToSavedPhotosAlbum:image.CGImage
                              orientation:(ALAssetOrientation)image.imageOrientation
                          completionBlock:^(NSURL* assetURL, NSError* error)
     {
         if (error != nil)
         {
             DLog(@"Error writing to photo album: %@", error.description);
             return;
         }
     }];
}

#pragma mark - Mail compose delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error
{
    if (result == MFMailComposeResultFailed)
    {
        [UIAlertView showAlertWithMessage:NSLocalizedString(@"lskFailedEmail", @"Send e-mail error on base controller")];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Message cell delegate protocol implementation

- (void)showFullImageWithURL:(NSURL *)url previewURL:(NSURL *)previewURL fromCell:(WDDMainPostCell *)cell
{
    WDDPhotoPreviewControllerViewController *previewController = [[WDDPhotoPreviewControllerViewController alloc] initWithImageURL:url previewURL:previewURL];
    previewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.navigationController presentViewController:previewController animated:YES completion:nil];
}

- (void)showVideoInWebWithURL:(NSURL *)url
{
    WDDWebViewController *webController = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDWebViewViewController];
    
    if ([url.absoluteString rangeOfString:@"woddl.it/"].location != NSNotFound)
    {
        url = [[WDDURLShorter defaultShorter] fullLinkForURL:url];
    }
    webController.url = url;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:webController]
                       animated:YES
                     completion:nil];
}

- (void)showFullVideoWithURL:(NSURL *)url fromCell:(WDDMainPostCell *)cell
{
    if([[url absoluteString] rangeOfString:@"www.youtube.com"].location != NSNotFound)
    {
        [self showVideoInWebWithURL:url];
    }
    else
    {
        MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
        player.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        self.videoURL2OpenInWebView = url;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playbackFinished:)
                                                     name:MPMoviePlayerPlaybackDidFinishNotification
                                                   object:player.moviePlayer];
        
        [self.navigationController presentViewController:player animated:YES completion:nil];
    }
}

- (void)playbackFinished:(NSNotification *)notificaiton
{
    if ([notificaiton.userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue] != MPMovieFinishReasonPlaybackError)
    {
        self.videoURL2OpenInWebView = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:notificaiton.object];
}

- (void)hideWebView
{
    [_webView removeFromSuperview];
    _webView = nil;
    [_closeButton removeFromSuperview];
    _closeButton = nil;
}

- (void)showUserPageWithURL:(NSURL *)url fromCell:(WDDMainPostCell *)cell
{
    [self openWebViewWithURL:url socialNetowork:cell.snPost.subscribedBy.socialNetwork requireAuthorization:YES];
}

- (void)showLinkWithURL:(NSURL *)url fromCell:(WDDMainPostCell *)cell
{
    [self openWebViewWithURL:url socialNetowork:cell.snPost.subscribedBy.socialNetwork requireAuthorization:NO];
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

- (void)shouldBeExpanded:(WDDMainPostCell *)cell
{
    NSIndexPath *indexPath = [self.postsTable indexPathForCell:cell];
    BOOL selfExpand = [self.expandedCellIndexPath isEqual:indexPath];
    
    if (self.expandedCellIndexPath)
    {
        WDDMainPostCell *expandedCell = (WDDMainPostCell *)[self.postsTable cellForRowAtIndexPath:self.expandedCellIndexPath];
        [self.postsTable beginUpdates];
        expandedCell.isExpanded = NO;
        expandedCell.textMessage.attributedText = expandedCell.shortMessageText;
        [self.postsTable endUpdates];
        self.selectedCellIndexPath = nil;
    }
    
    if (cell.isExpandable && !selfExpand)
    {
        [self.postsTable beginUpdates];
        cell.isExpanded = YES;
        cell.textMessage.attributedText = cell.fullMessageText;
        self.expandedCellIndexPath = indexPath;
        [self.postsTable endUpdates];
        [self.postsTable scrollToRowAtIndexPath:indexPath
                               atScrollPosition:UITableViewScrollPositionTop
                                       animated:YES];
    }
}

- (void)showEventWithEventURL:(NSURL *)url fromCell:(WDDMainPostCell *)cell
{
    [self openWebViewWithURL:url socialNetowork:cell.snPost.subscribedBy.socialNetwork requireAuthorization:YES];
}

#pragma mark - Media viewver controll methods

- (void)hideImageViewer:(UIGestureRecognizer *)sender
{
    [UIView animateWithDuration:0.1 animations:^{
        
        [sender.view removeFromSuperview];
    }];
}

#pragma mark - Storyboard

//  Storyboard
- (void)goToCommentScreenWithPost:(Post *)post
{
    [self performSegueWithIdentifier:[self goToCommentsScreenSegueIdentifier]
                              sender:post];
}

- (void)goToTwitterReplyWithPost:(Post *)post shouldQoute:(BOOL)shouldQoute
{
    self.postForMenu = post;
    [self performSegueWithIdentifier:[self goToTwitterReplyScreenSegueIdentifier]
                              sender:[NSNumber numberWithBool:shouldQoute]];
}

- (void)goToSearchWithTag:(NSString *)tag
{
    tag = [tag stringByReplacingOccurrencesOfString:@"." withString:@" "];
    WDDSearchViewController *searchVC = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDSearchScreen];
    searchVC.searchText = tag;
//    [searchVC performSelector:@selector(searchBarSearchButtonClicked:) withObject:nil];
    [self.navigationController pushViewController:searchVC animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    Post* post = sender;
    if ([segue.identifier isEqualToString:[self goToCommentsScreenSegueIdentifier]])
    {
        UINavigationController *navVC = segue.destinationViewController;
        WDDWriteCommetViewController *commentVC = [navVC.viewControllers firstObject];
        
        commentVC.post = post;
    }
    else if([segue.identifier isEqualToString:[self goToTwitterReplyScreenSegueIdentifier]])
    {
        UINavigationController *navVC = segue.destinationViewController;
        WDDTwitterReplyViewController *replyVC = [navVC.viewControllers firstObject];
        
        replyVC.post = self.postForMenu;
        NSNumber *shouldQuote = (NSNumber *)post;
        if ([shouldQuote boolValue])
        {
            replyVC.additionalText = self.postForMenu.text;
        }
    }
    else if ([segue.identifier isEqualToString:kStoryboardSegueIDSearch])
    {
        self.fetchedResultsController.delegate = nil;
    }
}

#pragma mark - Methods for overloading in sub classes

- (NSString *)goToCommentsScreenSegueIdentifier
{
    NSAssert([self class] != [WDDBasePostsViewController class], @"Method should be overloaded in subclass");
    return nil;
}

- (NSString *)goToTwitterReplyScreenSegueIdentifier
{
    NSAssert([self class] != [WDDBasePostsViewController class], @"Method should be overloaded in subclass");
    return nil;
}

- (NSString *)cellIdentifier
{
    NSAssert([self class] != [WDDBasePostsViewController class], @"Method should be overloaded in subclass");
    return nil;
}

- (BOOL)shouldShowCellDeleteButton
{
    return NO;
}

#pragma mark - Utility methods

- (void)openWebViewWithURL:(NSURL *)url socialNetowork:(SocialNetwork *)network requireAuthorization:(BOOL)requireAuthorization
{
    WDDWebViewController *webController = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDWebViewViewController];
    
    if ([url.absoluteString rangeOfString:@"woddl.it/"].location != NSNotFound)
    {
        url = [[WDDURLShorter defaultShorter] fullLinkForURL:url];
    }
    
    webController.url = url;
    webController.sourceNetwork = network;
    webController.requireAuthorization = requireAuthorization;
    [self presentViewController:[[UINavigationController alloc] initWithRootViewController:webController]
                       animated:YES
                     completion:nil];
}

- (void)reloadTableContent
{
    DLog(@"Method should be defined in concreate subclass");
    abort();
}

@end
