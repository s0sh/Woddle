//
//  WDDPhotoPreviewControllerViewController.m
//  Woddl
//
//  Created by Oleg Komaristov on 19.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDPhotoPreviewControllerViewController.h"
#import "WDDBasePostsViewController.h"

#import "UIImage+ResizeAdditions.h"
#import "SAMHUDView.h"

#import <SDWebImage/SDWebImageManager.h>

@interface WDDPhotoPreviewControllerViewController () <UIActionSheetDelegate, UIScrollViewDelegate>

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) NSURL *previewURL;

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIActivityIndicatorView *progressIndicator;
@property (nonatomic, strong) SAMHUDView *progressHUD;

@property (nonatomic, assign) BOOL fullImageLoaded;

@property (nonatomic, strong) UIActionSheet *menuSheet;

@end

@implementation WDDPhotoPreviewControllerViewController

- (id)initWithImageURL:(NSURL *)url previewURL:(NSURL *)previewURL
{
    if (self = [super init])
    {
        self.imageURL = url;
        self.previewURL = previewURL;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];
    self.view.alpha = 0.9f;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:(CGRect){CGPointZero, self.view.frame.size}];
    self.scrollView.delegate = self;
    self.scrollView.minimumZoomScale=0.5;
    self.scrollView.maximumZoomScale=6.0;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];
    
    self.imageView = [[UIImageView alloc] initWithFrame:(CGRect){CGPointZero, self.view.frame.size}];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.imageView.userInteractionEnabled = NO;
    [self.scrollView addSubview:self.imageView];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:0 views:@{@"view" : self.scrollView}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:0 views:@{@"view" : self.scrollView}]];
    
    self.progressIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.progressIndicator.center = CGPointMake(CGRectGetWidth(self.view.frame) / 2.f, CGRectGetHeight(self.view.frame) / 2.f);
    self.progressIndicator.hidesWhenStopped = YES;
    [self.progressIndicator startAnimating];
    [self.view addSubview:self.progressIndicator];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closePreview:)];
    [self.view addGestureRecognizer:tapRecognizer];
    
    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu:)];
    [self.view addGestureRecognizer:longPressRecognizer];
    
    __weak WDDPhotoPreviewControllerViewController *w_self = self;
    
    [[SDWebImageManager sharedManager] downloadWithURL:self.previewURL
                                               options:SDWebImageHighPriority | SDWebImageRetryFailed
                                              progress:nil
                                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {
                                                 
                                                 if (!w_self.fullImageLoaded && image)
                                                 {
                                                     [w_self showImage:image];
                                                 }
                                             }];
    
    [[SDWebImageManager sharedManager] downloadWithURL:self.imageURL
                                               options:SDWebImageLowPriority | SDWebImageRetryFailed
                                              progress:nil
                                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished) {

                                                 if (finished)
                                                 {
                                                     [w_self.progressIndicator stopAnimating];
                                                     
                                                     if (error)
                                                     {
                                                         DLog(@"Fail to load image with url: %@", self.imageURL);
                                                         if (!w_self.imageView.image)
                                                         {
                                                             w_self.imageView.image = [UIImage imageNamed:@"ImageLoadinFailedIcon"];
                                                         }
                                                     }
                                                     else
                                                     {
                                                         [w_self showImage:image];
                                                     }
                                                 }
                                             }];
}

- (void)showImage:(UIImage *)image
{
    CGFloat witdthSF = CGRectGetWidth(self.scrollView.frame) / image.size.width;
    CGFloat heightSF = CGRectGetHeight(self.scrollView.frame) / image.size.height;
    CGFloat scaleFactor = MIN(witdthSF, heightSF);
    
    self.imageView.frame = (CGRect){CGPointZero, image.size};
    
    self.scrollView.zoomScale = 1.f;
    self.scrollView.contentSize = CGSizeMake(image.size.width * [UIScreen mainScreen].scale,
                                             image.size.height * [UIScreen mainScreen].scale);
    //UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? image.size
    self.imageView.image = image;
    self.scrollView.minimumZoomScale = scaleFactor;
    self.scrollView.zoomScale = scaleFactor;
    [self.scrollView layoutSubviews];
    
    [self performSelector:@selector(scrollViewDidZoom:)
               withObject:self.scrollView
               afterDelay:0.05];
    
    self.fullImageLoaded = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Rotation support

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

#pragma mark UIActionSheetDelegate protocol implementation

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex)
    {
        self.progressHUD = [[SAMHUDView alloc] initWithTitle:NSLocalizedString(@"lskSaving", @"")];
        [self.progressHUD show];
        
        __weak WDDPhotoPreviewControllerViewController *w_self = self;
        [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:self.imageURL
                                                              options:SDWebImageDownloaderHighPriority
                                                             progress:nil
                                                            completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                                                                
                                                                if (finished && !error)
                                                                {
                                                                    [WDDBasePostsViewController addPhotoToGallery:image];
                                                                }
                                                                
                                                                [w_self.progressHUD completeAndDismissWithTitle:NSLocalizedString(@"lskDone", @"")];
                                                                w_self.progressHUD = nil;
                                                            }];
    }
    
    self.menuSheet = nil;
}

#pragma mark - User actions processing

- (void)closePreview:(UITapGestureRecognizer *)recognizer
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)showMenu:(UILongPressGestureRecognizer *)recognizer
{
    if (self.menuSheet)
    {
        return;
    }
    
    self.menuSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"lskPhoto", @"")
                                                 delegate:self
                                        cancelButtonTitle:NSLocalizedString(@"lskCancel", @"")
                                   destructiveButtonTitle:nil
                                        otherButtonTitles:NSLocalizedString(@"lskSaveToGallery", @""), nil];
    [self.menuSheet showInView:self.view];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

-(void)scrollViewDidZoom:(UIScrollView *)pScrollView
{
    self.imageView.frame = (CGRect){CGPointZero, self.imageView.frame.size};
    
    CGRect innerFrame = self.imageView.frame;
    CGRect scrollerBounds = pScrollView.bounds;
    
//    if ( ( innerFrame.size.width < scrollerBounds.size.width ) || ( innerFrame.size.height < scrollerBounds.size.height ) )
//    {
//        CGFloat tempx = self.imageView.center.x - ( scrollerBounds.size.width / 2 );
//        CGFloat tempy = self.imageView.center.y - ( scrollerBounds.size.height / 2 );
//        CGPoint myScrollViewOffset = CGPointMake( tempx, tempy);
//        
//        pScrollView.contentOffset = myScrollViewOffset;
//        
//    }
    
    UIEdgeInsets anEdgeInset = { 0, 0, 0, 0};
    if ( scrollerBounds.size.width > innerFrame.size.width )
    {
        anEdgeInset.left = (scrollerBounds.size.width - innerFrame.size.width) / 2;
        anEdgeInset.right = -anEdgeInset.left;  // I don't know why this needs to be negative, but that's what works
    }
    if ( scrollerBounds.size.height > innerFrame.size.height )
    {
        anEdgeInset.top = (scrollerBounds.size.height - innerFrame.size.height) / 2;
        anEdgeInset.bottom = -anEdgeInset.top;  // I don't know why this needs to be negative, but that's what works
    }
    pScrollView.contentInset = anEdgeInset;
}

#pragma mark - Rotation support

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:duration/3.f animations:^{
        
        self.imageView.alpha = 0.f;
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self showImage:self.imageView.image];
    
    [UIView animateWithDuration:0.075 animations:^{
        
        self.imageView.alpha = 1.f;
    }];
}

@end
