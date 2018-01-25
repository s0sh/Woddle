//
//  WDDWhoLikedViewController.m
//  Woddl
//
//  Created by Oleg Komaristov on 15.02.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "WDDWhoLikedViewController.h"
#import "WDDWebViewController.h"
#import "WDDStatusSNAccountCell.h"

#import "Post.h"
#import "UserProfile.h"

#import "UIImage+ResizeAdditions.h"
#import "UIImageView+WebCache.h"
#import <SDWebImage/SDWebImageManager.h>

static const CGFloat kAvatarCornerRadious = 2.0f;

@interface WDDWhoLikedViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, retain) NSArray *sortedUsersList;

@property (weak, nonatomic) IBOutlet UITableView *usersTable;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end

@implementation WDDWhoLikedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.sortedUsersList = [self.post.likedBy sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
    
    if (self.sortedUsersList.count != self.post.likesCount.integerValue)
    {
        __weak WDDWhoLikedViewController *wSelf = self;
        [self.post refreshLikedUsersWithComplitionBlock:^(BOOL success) {
            
            [wSelf.post.managedObjectContext refreshObject:wSelf.post mergeChanges:YES];
            wSelf.sortedUsersList = [wSelf.post.likedBy sortedArrayUsingDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
            
            [wSelf.delegate contentUpdatedInController:wSelf];
            
            [wSelf.activityIndicator stopAnimating];
            [wSelf.usersTable reloadData];
        }];
    }
    
    if (!self.sortedUsersList.count)
    {
        [self.activityIndicator startAnimating];
    }
    
    [self.usersTable reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UITableViewDataSource protocol implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sortedUsersList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WDDStatusSNAccountCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UserProfileCell"
                                                                   forIndexPath:indexPath];
    
    UserProfile *user = [self.sortedUsersList objectAtIndex:indexPath.row];
    
    cell.usernameLabel.text = (user.name.length ? user.name : NSLocalizedString(@"lskUnnamed", @"Name for users with empty name field"));
    [self setupAvatarImageInCell:cell forPost:user];
    
    return cell;
}

- (void)setupAvatarImageInCell:(WDDStatusSNAccountCell *)cell forPost:(UserProfile *)user
{
    static UIImage *placeHolderImage = nil;
    static dispatch_queue_t imageResizeQueue = nil;
    
    CGFloat width = cell.avatarImageView.frame.size.width * [UIScreen mainScreen].scale;
    __weak WDDStatusSNAccountCell *wCell = cell;
    
    if(!placeHolderImage)
    {
        placeHolderImage = [[UIImage imageNamed:kAvatarPlaceholderImageName] thumbnailImage:width
                                                                          transparentBorder:1.0f
                                                                               cornerRadius:kAvatarCornerRadious
                                                                       interpolationQuality:kCGInterpolationDefault];
    }
    
    if (!imageResizeQueue)
    {
        imageResizeQueue = dispatch_queue_create("image resize queue", DISPATCH_QUEUE_CONCURRENT);
    }
    
    UIImage* placeHolderImageRes = [UIImage imageWithCGImage:placeHolderImage.CGImage];
    NSURL *avatarURL = [NSURL URLWithString:user.avatarRemoteURL];
    
    SDWebImageCompletedBlock completion = ^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        __block UIImage* resImage = image;
        if (!error)
        {
            dispatch_async(imageResizeQueue, ^{
                resImage = [resImage thumbnailImage:width
                                  transparentBorder:1.0f
                                       cornerRadius:kAvatarCornerRadious
                               interpolationQuality:kCGInterpolationMedium];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.avatarImageView.image = resImage;
                });
            });
        }
    };

    dispatch_async(dispatch_get_main_queue(), ^{
        [wCell.avatarImageView setImageWithURL:avatarURL
                             placeholderImage:placeHolderImageRes
                                      options:SDWebImageRefreshCached
                                    completed:completion];
    });
    
    cell.avatarImageView.layer.masksToBounds = YES;
    [cell.avatarImageView.layer setCornerRadius:kAvatarCornerRadious];
}

#pragma mark - UITableViewDelegate protocol implementation

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserProfile *user = [self.sortedUsersList objectAtIndex:indexPath.row];
    
    WDDWebViewController *webController = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDWebViewViewController];
    webController.url = [NSURL URLWithString:user.profileURL];
    webController.sourceNetwork = self.post.subscribedBy.socialNetwork;
    webController.requireAuthorization = YES;
    
    if ([self.delegate isKindOfClass:[UIViewController class]])
    {
        [(UIViewController *)self.delegate presentViewController:[[UINavigationController alloc] initWithRootViewController:webController]
                                                        animated:YES
                                                      completion:nil];
        [self.delegate dismissController:self];
    }
}

@end
