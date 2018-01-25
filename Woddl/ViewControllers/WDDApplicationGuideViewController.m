//
//  WDDApplicationGuideViewController.m
//  Woddl
//
//  Created by Oleg Komaristov on 08.04.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "WDDApplicationGuideViewController.h"

static const NSInteger GuidePagesCount = 3;

@interface WDDApplicationGuideViewController ()
{
    BOOL isAppeared;
}

@property (weak, nonatomic) IBOutlet UIScrollView *contentView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *previousButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentTopOffset;

@end

@implementation WDDApplicationGuideViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (IS_IOS7)
    {
        self.contentTopOffset.constant = CGRectGetHeight(self.navigationController.navigationBar.frame) + (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) : CGRectGetWidth([UIApplication sharedApplication].statusBarFrame));
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    
    self.contentView.pagingEnabled = YES;
    
    NSInteger iPage;
    
    NSMutableArray *constraints = [NSMutableArray new];
    
    for (iPage = 0; iPage < GuidePagesCount; ++iPage)
    {
        NSString *pageName = ASSET_BY_SCREEN_HEIGHT(([NSString stringWithFormat:@"Guide Screen %ld", iPage + 1]));
        UIImage *pageImage = [UIImage imageNamed:pageName];
        if (!pageImage)
        {
            break;
        }
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:(CGRect){CGPointZero, self.contentView.frame.size}];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.image = pageImage;
        
        NSLayoutConstraint *imageWidth = [NSLayoutConstraint constraintWithItem:imageView
                                                                      attribute:NSLayoutAttributeWidth
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.contentView
                                                                      attribute:NSLayoutAttributeWidth
                                                                     multiplier:1.f
                                                                       constant:0.0f];
        NSLayoutConstraint *imageHeight = [NSLayoutConstraint constraintWithItem:imageView
                                                                      attribute:NSLayoutAttributeHeight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:self.contentView
                                                                      attribute:NSLayoutAttributeHeight
                                                                     multiplier:1.f
                                                                       constant:0.0f];
        [self.contentView addSubview:imageView];
        

        NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:imageView
                                                                attribute:NSLayoutAttributeLeading
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:iPage ? self.contentView.subviews[iPage - 1] : self.contentView
                                                                attribute:iPage ? NSLayoutAttributeTrailing : NSLayoutAttributeLeading
                                                               multiplier:1.0f
                                                                 constant:0.0f];
        
        NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:imageView
                                                               attribute:NSLayoutAttributeTop
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.contentView
                                                               attribute:NSLayoutAttributeTop
                                                              multiplier:1.0f
                                                                constant:0.0f];
        NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:imageView
                                                                  attribute:NSLayoutAttributeBottom
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.contentView
                                                                  attribute:NSLayoutAttributeBottom
                                                                 multiplier:1.0f
                                                                   constant:0.0f];
        
        [constraints addObjectsFromArray:@[imageHeight, imageWidth, left, top, bottom]];
        
        if (iPage == GuidePagesCount)
        {
            NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:imageView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.contentView
                                                                     attribute:NSLayoutAttributeTrailing
                                                                    multiplier:1.0f
                                                                      constant:0.0f];
            [constraints addObject:right];
        }
    }
    
    [self.contentView addConstraints:constraints];
    
    self.previousButton.title = NSLocalizedString(@"lskPrev", @"Application guide previous page");
    self.nextButton.title = NSLocalizedString(@"lskNext", @"Application guide next page");
    [self updateButtonsState];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark - User actions processing

- (IBAction)previousPageAction:(id)sender
{
    NSInteger iPage = self.contentView.contentOffset.x / CGRectGetWidth([UIScreen mainScreen].bounds);
    if (iPage > 0)
    {
        [self.contentView setContentOffset:CGPointMake(--iPage * CGRectGetWidth([UIScreen mainScreen].bounds), 0.f)
                                  animated:YES];
    }
}

- (IBAction)nextPageAction:(id)sender
{
    NSInteger iPage = self.contentView.contentOffset.x / CGRectGetWidth([UIScreen mainScreen].bounds);
    if (iPage < (GuidePagesCount - 1))
    {
        [self.contentView setContentOffset:CGPointMake(++iPage * CGRectGetWidth([UIScreen mainScreen].bounds), 0.f)
                                  animated:YES];
    }
    else
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kFirstStartUserDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self performSegueWithIdentifier:kStoryboardSegueIDMainSlidingScreenAfterAfterGuide sender:nil];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self updateButtonsState];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self updateButtonsState];
}

#pragma mark - Utility methods

- (void)updateButtonsState
{
    NSInteger iPage = self.contentView.contentOffset.x / CGRectGetWidth([UIScreen mainScreen].bounds);
    self.previousButton.enabled = (iPage != 0);
    
    if (iPage == (GuidePagesCount - 1))
    {
        self.nextButton.title = NSLocalizedString(@"lskDone", @"");
    }
    else
    {
        self.nextButton.title = NSLocalizedString(@"lskNext", @"Application guide next page");
    }
}

@end
