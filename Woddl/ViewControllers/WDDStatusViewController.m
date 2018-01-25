//
//  WDDStatusViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 23.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDStatusViewController.h"
#import "WDDDataBase.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WDDLocationManager.h"
#import "SAMHUDView.h"
#import <WYPopoverController.h>
#import "WDDStatusSNAccountsViewController.h"
#import "WDDAddFriendViewController.h"
#import "WDDLocationsListViewController.h"
#import "FoursquareRequest.h"
#import "FacebookRequest.h"

#import "WDDURLShorter.h"
#import "UIImage+ResizeAdditions.h"
#import "NSCharacterSet+Emoji.h"

#define POPOVER_COLOR [UIColor colorWithRed:51.0f/255.0f green:51.0f/255.0f blue:51.0f/255.0f alpha:1.0f]



@interface WDDStatusViewController () < UITextViewDelegate,
                                        UIImagePickerControllerDelegate,
                                        UINavigationControllerDelegate,
                                        UIActionSheetDelegate,
                                        WDDStatusSNAccountsDelegate,
                                        WYPopoverControllerDelegate,
                                        WDDAddFriendDelegate,
                                        WDDLocationsListDelegate    >

//  Views

@property (weak, nonatomic) IBOutlet UITextView *hiddenTextView;
@property (weak, nonatomic) IBOutlet UIButton *linkedInButton;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (weak, nonatomic) IBOutlet UIButton *foursquareButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UILabel *locationNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *charCounterLabel;
@property (weak, nonatomic) IBOutlet UIButton *getLocationButton;

@property (weak, nonatomic) UIActionSheet *photoActionSheet;

@property (weak, nonatomic) IBOutlet UIView *mainView;

@property (weak, nonatomic) IBOutlet UIView *preViewView;

@property (weak, nonatomic) IBOutlet UIImageView *preViewImageView;

// Model
@property (strong, nonatomic) NSMutableArray *imagePickerController;
@property (assign, nonatomic) NSInteger twitterCharactersLeft;

@property (strong, nonatomic) id mediaAttachment;
@property (assign, nonatomic, getter = isCameraMediaSource) BOOL cameraMediaSource;
@property (strong, nonatomic) WDDLocation *currentLocation;

@property (strong, nonatomic) SAMHUDView *progressHUD;

@property (assign, nonatomic, getter = isEnteringTag) BOOL enteringTag;
@property (assign, nonatomic, getter = shouldResetFontToNormal) BOOL resetFontToNormal;
@property (assign, nonatomic, getter = isLastCharacterEmoji) BOOL lastCharacterEmoji;
@property (strong, nonatomic) WYPopoverController *popoverVC;

//Constraint

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewConstraint;



//  Selected social networks
@property (strong, nonatomic) NSArray *linkedInSelectedAccounts;
@property (strong, nonatomic) NSArray *facebookSelectedAccounts;
@property (strong, nonatomic) NSArray *facebookSelectedGroups;
@property (strong, nonatomic) NSArray *foursquareSelectedAccounts;
@property (strong, nonatomic) NSArray *twitterSelectedAccounts;
@property (strong, nonatomic) UISwitch *intentSwitch;

@end

static const NSInteger kSocialNetworkButtonTagBase = 2000;
static const NSInteger kMaxCountOfCharactersInText = 140;
static const NSInteger kTwitterImageLinkLength =  26;

@implementation WDDStatusViewController

@synthesize statusesTaskCounter = _statusesTaskCounter;

#pragma mark - lifecycle methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupButtons];
    self.twitterCharactersLeft = kMaxCountOfCharactersInText;
    [self setupNavigationBarTitle];
    [self setupPopoverAppearance];
    
    UIImage* sendButtonImage = [UIImage imageNamed:@"SendIcon"];
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.bounds = CGRectMake( 0, 0, sendButtonImage.size.width, sendButtonImage.size.height );
    [customButton setImage:sendButtonImage forState:UIControlStateNormal];
    [customButton addTarget:self action:@selector(saveStatusAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.sendButton setCustomView:customButton];
    
    [self customizeBackButton];
    [self updateUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [super viewDidAppear:animated];
    [Heatmaps trackScreenWithKey:@"503395516a70d21a-087c22d3"];
    
    [WDDDataBase sharedDatabase].updatingStatus = YES;
    [self.inputTextview becomeFirstResponder];
}

- (void)setupButtons
{
    [self setupSocialNetworkButtonsTag];
    
    [self setupButtonForSocialNetwork:kSocialNetworkFacebook];
    [self setupButtonForSocialNetwork:kSocialNetworkTwitter];
    [self setupButtonForSocialNetwork:kSocialNetworkLinkedIN];
    [self setupButtonForSocialNetwork:kSocialNetworkFoursquare];
}

- (void)setupSocialNetworkButtonsTag
{
    self.facebookButton.tag = kSocialNetworkButtonTagBase + kSocialNetworkFacebook;
    self.twitterButton.tag = kSocialNetworkButtonTagBase + kSocialNetworkTwitter;
    self.linkedInButton.tag = kSocialNetworkButtonTagBase + kSocialNetworkLinkedIN;
    self.foursquareButton.tag = kSocialNetworkButtonTagBase + kSocialNetworkFoursquare;
}

- (void)setupButtonForSocialNetwork:(SocialNetworkType)type
{
    NSInteger tag = kSocialNetworkButtonTagBase + type;
    UIButton *button = (UIButton *)[self.view viewWithTag:tag];
    
    if ([button isKindOfClass:[UIButton class]])
    {
        NSInteger supportingNetworks = [[WDDDataBase sharedDatabase] availableSocialNetworks];
        if (supportingNetworks & type)
        {
            button.selected = NO;
        }
        else
        {
            button.enabled = NO;
        }
    }
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
        if (self.twitterButton.isEnabled)
        {
            isTwitterButtonEnabled  = self.twitterButton.isEnabled;
            self.twitterButton.enabled = NO;
        }
        
        self.charCounterLabel.textColor = [UIColor redColor];
    }
    else
    {
        if (isTwitterButtonEnabled)
        {
            self.twitterButton.enabled = isTwitterButtonEnabled;
            self.twitterButton.selected = self.twitterSelectedAccounts.count;
        }
        self.charCounterLabel.textColor = [UIColor whiteColor];
    }
    
    self.charCounterLabel.text = [NSString stringWithFormat:@"%d", twitterCharactersLeft];
}

- (void)setMediaAttachment:(id)mediaAttachment
{
//    if (!mediaAttachment && _mediaAttachment)
//    {
//        if(isLinkedinButtonEnabled)
//        {
//            self.linkedInButton.selected = self.linkedInSelectedAccounts.count;;
//        }
//        
//        self.twitterCharactersLeft += kTwitterImageLinkLength;
//    }
//    else
//    {
//        if (self.linkedInButton.isEnabled)
//        {
//            isLinkedinButtonEnabled  = self.linkedInButton.isEnabled;
//            self.linkedInButton.enabled = NO;
//        }
//    }
    _mediaAttachment = mediaAttachment;
}

#pragma mark - Bar items action

- (IBAction)saveStatusAction:(UIBarButtonItem *)sender
{
    if (![APP_DELEGATE isInternetConnected])
    {
        [[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"lskConnectInternet", @"") delegate:nil cancelButtonTitle:NSLocalizedString(@"lskOK", @"") otherButtonTitles:nil] show];
       return ;
    }
    
    NSArray *allAvailableSelectedAccounts = [self formAllAvailableSelectedAccountsList];
    NSArray *allAvailableSelectedGruops = [self fromAllAvailableSelectedGroupsList];
    
    if (!self.inputTextview.text.length)
    {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"lsEnterStatusUpdate", @"No SN selected")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"lskOK", @"OK button")
                          otherButtonTitles:nil] show];
        return ;
    }
    
    if (!allAvailableSelectedAccounts.count && !allAvailableSelectedGruops.count)
    {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"lskSelectNetwork", @"No SN selected")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"lskOK", @"OK button")
                          otherButtonTitles:nil] show];
        return ;
    }
    
    
    __weak WDDStatusViewController *wSelf = self;
    
    self.statusesTaskCounter++;
    [self processLinksInText:self.inputTextview.attributedText.mutableCopy
                 withOptions:ProcessLinksAtLastPosition
                  complition:^(BOOL isChanged, NSAttributedString *text)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            DLog(@"Status will be updated for %d accounts", allAvailableSelectedAccounts.count);
            for (SocialNetwork *sn in allAvailableSelectedAccounts)
            {
                wSelf.statusesTaskCounter++;
                NSManagedObjectID *userID = sn.profile.objectID;
                
                DLog(@"Update status for social network %@ type %@", sn.type, sn.profile.name);
                [sn addStatusWithMessage:text.string
                               andImages:(wSelf.mediaAttachment ? @[wSelf.mediaAttachment] : nil)
                             andLocation:wSelf.currentLocation
                     withCompletionBlock:^(NSError *error) {
                         
                         if (error)
                         {
                             [wSelf showStatusErrorForAcccountWithID:userID];
                             
                             DLog(@"Error: %@", [error localizedDescription]);
                         }
                         else
                         {
                             wSelf.statusesTaskCounter--;
                         }
                    }];
            }
            
            for (Group *group in allAvailableSelectedGruops)
            {
                for (UserProfile *user in group.managedBy)
                {
                    wSelf.statusesTaskCounter++;
                    NSManagedObjectID *userID = user.objectID;
                    
                    [user.socialNetwork addStatusWithMessage:text.string
                                                   andImages:(wSelf.mediaAttachment ? @[wSelf.mediaAttachment] : nil)
                                                 andLocation:wSelf.currentLocation
                                                     toGroup:group
                                         withCompletionBlock:^(NSError *error) {
                             
                                             if (error)
                                             {
                                                 [wSelf showStatusErrorForAcccountWithID:userID];
                                                 
                                                 DLog(@"Error: %@", [error localizedDescription]);
                                             }
                                             else
                                             {
                                                 wSelf.statusesTaskCounter--;
                                             }
                                         }];
                }
            }
            
            self.statusesTaskCounter--;
        });
    }];
}

const NSInteger kStatusUpdateErrorAlertTag = 4321;

- (void)showStatusErrorForAcccountWithID:(NSManagedObjectID *)profileID
{
    if (!profileID)
    {
        DLog(@"Try to show error with nil profileID");
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        UserProfile *profile = (UserProfile *)[[WDDDataBase sharedDatabase].managedObjectContext objectWithID:profileID];
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"lskStatusUpdateError", @"Sataus change error message"), profile.name];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"lskError", @"")
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"lskClose", @"")
                                              otherButtonTitles:nil];
        alert.tag = kStatusUpdateErrorAlertTag;
        [alert show];
    });
}

- (NSArray *)fromAllAvailableSelectedGroupsList
{
    NSMutableArray *allSelectedGroups = [[NSMutableArray alloc] init];
    
    if (self.facebookSelectedGroups.count)
    {
        [allSelectedGroups addObjectsFromArray:self.facebookSelectedGroups];
    }
    
    return [allSelectedGroups copy];
}

- (NSArray *)formAllAvailableSelectedAccountsList
{
    NSMutableArray *allSelectedAccounts = [[NSMutableArray alloc] init];
    
    
    if (self.twitterSelectedAccounts.count && self.twitterCharactersLeft >= 0 && self.twitterButton.isEnabled)
    {
        [allSelectedAccounts addObjectsFromArray:self.twitterSelectedAccounts];
    }
    if (self.facebookSelectedAccounts.count)
    {
        [allSelectedAccounts addObjectsFromArray:self.facebookSelectedAccounts];
    }
    if (self.foursquareSelectedAccounts.count && self.foursquareButton.isEnabled)
    {
        [allSelectedAccounts addObjectsFromArray:self.foursquareSelectedAccounts];
    }
    if (self.linkedInSelectedAccounts.count && self.linkedInButton.isEnabled)
    {
        [allSelectedAccounts addObjectsFromArray:self.linkedInSelectedAccounts];
    }
    
    return [allSelectedAccounts copy];
}

#pragma mark - Appearance methods

- (void)dismiss
{
    dispatch_async(dispatch_get_main_queue(), ^{
    
        [self.presentingViewController dismissViewControllerAnimated:YES
                                                  completion:nil];
    });
}

#pragma mark - Actions

- (IBAction)setActiveNetwork:(UIButton *)sender
{
    SocialNetworkType type = sender.tag - kSocialNetworkButtonTagBase;
    NSArray *accounts = [[WDDDataBase sharedDatabase] fetchSocialNetworksAscendingWithType:type];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.accessToken != nil"];
    accounts = [accounts filteredArrayUsingPredicate:predicate];
//    NSSet *myGroups = [[[accounts firstObject] groups] filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"isManagedByMe == %@", @YES]];
    
    if (accounts.count > 1 || [[[accounts firstObject] profile] manageGroups].count)
    {
        WDDStatusSNAccountsViewController *accountsVC = [self.storyboard instantiateViewControllerWithIdentifier:kStoryboardIDStatusSNAccountsViewController];
        accountsVC.socialNetworkType = type;
        accountsVC.delegate = self;
        accountsVC.selectedAccounts = [[self selectedAccountsForSocialNetworkType:type] mutableCopy];
        accountsVC.selectedGroups = [[self selectedGroupsForSocialNetworkType:type] mutableCopy];
        
        WYPopoverController *popover = [[WYPopoverController alloc] initWithContentViewController:accountsVC];
        popover.popoverContentSize = accountsVC.view.frame.size;
       
        popover.delegate = self;
        self.popoverVC = popover;
        
        [popover presentPopoverFromRect:sender.bounds
                                 inView:sender
               permittedArrowDirections:WYPopoverArrowDirectionDown
                               animated:YES];
    }
    else
    {
        if ([self selectedAccountsForSocialNetworkType:type].count)
        {
            [self setSelectedAccounts:@[] andGroups:@[] forType:type];
        }
        else
        {
            [self setSelectedAccounts:accounts andGroups:@[] forType:type];
        }
        [self updateUI];
    }
}

- (NSArray *)selectedAccountsForSocialNetworkType:(SocialNetworkType)type
{
    NSArray *accounts;
    if (type == kSocialNetworkFacebook)
    {
        accounts = self.facebookSelectedAccounts;
    }
    else if (type == kSocialNetworkLinkedIN)
    {
        accounts = self.linkedInSelectedAccounts;
    }
    else if (type == kSocialNetworkFoursquare)
    {
        accounts = self.foursquareSelectedAccounts;
    }
    else if (type == kSocialNetworkTwitter)
    {
        accounts = self.twitterSelectedAccounts;
    }
    
    return accounts;
}

- (NSArray *)selectedGroupsForSocialNetworkType:(SocialNetworkType)type
{
    NSArray *groups;
    if (type == kSocialNetworkFacebook)
    {
        groups = self.facebookSelectedGroups;
    }
    
    return groups;
}

- (IBAction)takeMedia:(id)sender
{
    if (self.cameraButton.selected)
    {
        self.mediaAttachment = nil;
        [self updateUI];
    }
    else
    {
        [self showPhotoActionSheet];
    }
}

- (IBAction)getLocation:(UIButton *)sender
{
    if (self.currentLocation)
    {
        self.currentLocation = nil;
    }
    else
    {
        GetLocationBlock resultBlock = ^(WDDLocation *location, NSError *error)
        {
            if (!error)
            {
                NSArray *sns = [[WDDDataBase sharedDatabase] fetchAllSocialNetworks];
                sns = [sns filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"accessToken != nil && type == 1"]];
                [[FacebookRequest new] getLocationsWithLocation:location
                                                    accessToken:[sns.firstObject accessToken]
                                                     completion:^(NSArray *locations)
                 {
                     dispatch_async(dispatch_get_main_queue(), ^{
                         
                         if (locations)
                         {
                             [self presentLocationsListPopoverWithLocations:locations
                                                                   fromView:sender];
                         }
                         else
                         {
                             DLog(@"error");
                         }
                     });
                     
                 }];

#ifdef DEBUG
                DLog(@"%@", location);
#endif
            }
            else
            {
#ifdef DEBUG
                DLog(@"%@", [error localizedDescription]);
#endif
            }
        };
        [[WDDLocationManager sharedLocationManager] getCurrentLocationInComplition:resultBlock];
    }
    [self updateUI];
}

- (IBAction)addSharp:(id)sender
{
    
    NSRange cursorPostion = self.inputTextview.selectedRange;
    self.inputTextview.text = [self.inputTextview.text stringByReplacingCharactersInRange:cursorPostion withString:@"#"];
    cursorPostion.location += 1;
    self.inputTextview.selectedRange = cursorPostion;
}

#pragma mark - Location help methods
#pragma mark 

- (void)presentLocationsListPopoverWithLocations:(NSArray *)locations fromView:(UIView *)view
{
    WDDLocationsListViewController *locationVC = [self.storyboard instantiateViewControllerWithIdentifier:WDDLocationsListViewControllerIdentifier];
    
    locationVC.locations = locations;
    locationVC.delegate = self;
    
    WYPopoverController *popover = [[WYPopoverController alloc] initWithContentViewController:locationVC];
    popover.popoverContentSize = locationVC.view.frame.size;
    
    popover.delegate = self;
    self.popoverVC = popover;
    
    [popover presentPopoverFromRect:[view bounds]
                             inView:view
           permittedArrowDirections:WYPopoverArrowDirectionDown
                           animated:YES];
}

#pragma mark - TextView delegate
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
            [self performSegueWithIdentifier:kStoryboardSegueIDAddFriendsScreen sender:self];
            return NO;
        }
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    [super textViewDidChange:textView];
    
    //  Save cursor position - prevent jumping cursor after highlighting tags and usernames
    NSRange cursorPostion = textView.selectedRange;
    
    [self highlightTagsInText:[textView.attributedText mutableCopy]];
    
    if (textView.text.length && self.shouldResetFontToNormal && !self.isLastCharacterEmoji)
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
        [text setAttributes:@{ NSFontAttributeName:[UIFont boldSystemFontOfSize:kPostFontSize ],
                                           NSForegroundColorAttributeName:[UIColor blackColor] }
                      range:matchRange];
        self.inputTextview.attributedText = text;
    }
}

#pragma mark - Image picker controller delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage* imageFromPicker = [self getMediaWithInfo:info];
    
    if(imageFromPicker)
    {
        //[self setupImagePreView:imageFromPicker];
        self.preViewImageView.image = [imageFromPicker thumbnailImage:25.f
                                                    transparentBorder:0.f
                                                         cornerRadius:1.f
                                                 interpolationQuality:kCGInterpolationDefault];
    }

    [self updateUI];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Save media to camera roll

- (UIImage *)getMediaWithInfo:(NSDictionary *)info
{
    if ([info[UIImagePickerControllerMediaType] isEqualToString:(NSString *)kUTTypeImage])
    {
        self.mediaAttachment = [self getImageAndSaveToCameraRollWithInfo:info];
        DLog(@"Photo size for status update is %lu bytes", (unsigned long)[(NSData *)self.mediaAttachment length]);
        UIImage *image = [UIImage imageWithData:self.mediaAttachment];
        
        return image;
    }
    return nil;
}

const CGFloat kPhotoWidthMax = 1024.0f;
- (NSData *)getImageAndSaveToCameraRollWithInfo:(NSDictionary *)info
{
    UIImage *tempImage = info[UIImagePickerControllerOriginalImage];
    
    if (self.isCameraMediaSource)
    {
        self.cameraMediaSource = NO;
        UIImageWriteToSavedPhotosAlbum(tempImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
    
    CGSize size = tempImage.size;
    if (size.width > kPhotoWidthMax)
    {
        CGFloat proportion = kPhotoWidthMax/size.width;
        size = CGSizeMake( kPhotoWidthMax, size.height * proportion);
        tempImage = [tempImage resizedImage:size interpolationQuality:kCGInterpolationNone];
    }
    
    return UIImageJPEGRepresentation(tempImage, 0.8);
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

#pragma mark - Update UI methods

- (void)updateUI
{
    [self updateCounter];
    [self updateCameraButton];
    [self updateLocationUI];
    [self updateSocialNetworkButtons];
}

- (void)updateCounter
{
    self.twitterCharactersLeft = kMaxCountOfCharactersInText - self.inputTextview.text.length - (self.mediaAttachment ? kTwitterImageLinkLength : 0);
}

- (void)updateCameraButton
{
    self.cameraButton.selected = (self.mediaAttachment ? YES : NO);
    self.preViewView.hidden = (self.mediaAttachment ? NO : YES);
}

- (void)updateLocationUI
{
    [self updateLocationLabel];
    [self updateLocationButton];
}

- (void)updateLocationLabel
{
    if (self.currentLocation.name)
    {
        if (isFoursquareButtonEnabled)
        {
            self.foursquareButton.enabled  = isFoursquareButtonEnabled;
            self.foursquareButton.selected = self.foursquareSelectedAccounts.count;
        }
    }
    else
    {
        if (self.foursquareButton.isEnabled)
        {
            isFoursquareButtonEnabled  = self.foursquareButton.isEnabled;
            
            self.foursquareButton.enabled = NO;
        }
    }
    
    self.locationNameLabel.hidden = (self.currentLocation.name ? NO : YES);
    self.locationNameLabel.text = self.currentLocation.name;
}

- (void)updateLocationButton
{
    self.getLocationButton.selected = (self.currentLocation ? YES : NO);
}

- (void)updateSocialNetworkButtons
{
    self.linkedInButton.selected = (self.linkedInSelectedAccounts.count ? YES : NO);
    self.facebookButton.selected = ((self.facebookSelectedAccounts.count || self.facebookSelectedGroups.count)? YES : NO);
    self.foursquareButton.selected = (self.foursquareSelectedAccounts.count ? YES : NO);
    self.twitterButton.selected = (self.twitterSelectedAccounts.count ? YES : NO);
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
    self.photoActionSheet = actionSheet;
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
                imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                self.cameraMediaSource = YES;
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
                imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                self.cameraMediaSource = NO;
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

#pragma mark - UIAlertView
#pragma mark 

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == kStatusUpdateErrorAlertTag)
    {
        self.statusesTaskCounter--;
    }
}

#pragma mark - Setters and getters

-(NSInteger)statusesTaskCounter
{
    @synchronized(self)
    {
        return _statusesTaskCounter;
    }
}

-(void)setStatusesTaskCounter:(NSInteger)statusesTaskCounter
{
    @synchronized(self)
    {
        if(_statusesTaskCounter == 0 && statusesTaskCounter == 1)
        {
            [self showProcessHUDWithText:NSLocalizedString(@"lskProcessing", @"")];
        }
        else if(_statusesTaskCounter == 1 && statusesTaskCounter == 0)
        {
            [self removeProcessHUDOnSuccessLoginHUDWithText:NSLocalizedString(@"lskComplete", @"")];
            [self dismiss];
        }
        _statusesTaskCounter = statusesTaskCounter;
    }
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

#pragma mark - WDDSocialNetworkAccounts VC delegate
- (void)didSelectSocialNetworkAccounts:(NSArray *)selectedAccounts andGroups:(NSArray *)groups forType:(SocialNetworkType)type
{
    [self setSelectedAccounts:selectedAccounts  andGroups:groups forType:type];
    [self updateUI];
}

- (void)setSelectedAccounts:(NSArray *)accounts andGroups:(NSArray *)groups forType:(SocialNetworkType)type
{
    if (type == kSocialNetworkFacebook)
    {
        self.facebookSelectedAccounts = accounts;
        self.facebookSelectedGroups = groups;
    }
    else if (type == kSocialNetworkLinkedIN)
    {
        self.linkedInSelectedAccounts = accounts;
    }
    else if (type == kSocialNetworkFoursquare)
    {
        self.foursquareSelectedAccounts  = accounts;
    }
    else if (type == kSocialNetworkTwitter)
    {
        self.twitterSelectedAccounts  = accounts;
    }
}

- (void)popoverControllerDidDismissPopover:(WYPopoverController *)popoverController
{
    self.popoverVC = nil;
}

#pragma mark - Storyboard
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kStoryboardSegueIDAddFriendsScreen])
    {
        UINavigationController *navVC = segue.destinationViewController;
        WDDAddFriendViewController *addFriendVC = [navVC.viewControllers firstObject];
        
        //  User [self formAllAvailableSelectedAccountsList] for showing friends just for selected SN.
        //  If nil - shows all friends from all networks
        addFriendVC.socialNetworks = nil;//[self formAllAvailableSelectedAccountsList];
        addFriendVC.delegate = self;
    }
}

#pragma mark - WDDAddFriendDelegate
- (void)didAddFriendWithName:(NSString *)friendName
{
    if (friendName.length)
    {
        NSString *friendNameString = [NSString stringWithFormat:@" %@ ", friendName];

        NSMutableAttributedString *friendNameAtrString = [[NSMutableAttributedString alloc] initWithString:friendNameString
                                                                                                attributes:@{ NSFontAttributeName:[UIFont boldSystemFontOfSize:kPostFontSize ],
                                                                                                       NSForegroundColorAttributeName:[UIColor blackColor] }];
        [friendNameAtrString setAttributes:@{ NSFontAttributeName:[UIFont systemFontOfSize:kPostFontSize ],
                                              NSForegroundColorAttributeName:[UIColor blackColor] }
                                     range:NSMakeRange(friendNameString.length-1 , 1)];
        
        NSMutableAttributedString *compliteAtrString = [[NSMutableAttributedString alloc] initWithAttributedString:self.inputTextview.attributedText];
        [compliteAtrString appendAttributedString:friendNameAtrString];
        self.inputTextview.attributedText = compliteAtrString;
        [self updateUI];
    }
}

#pragma mark - WDDLocationsListDelegate
#pragma mark 

- (void)didSelectLocataion:(WDDLocation *)location
{
    self.currentLocation = location;
    [self updateUI];
    [self.popoverVC dismissPopoverAnimated:YES];
    
    __weak typeof(self) weakSelf = self;
    
    [FoursquareRequest requestNearestPlacesInBackgroundForLatitude:location.latidude
                                                         longitude:location.longitude
                                                          accuracy:location.accuracy
                                                            intent:@"browse"
                                                      searchString:location.name
                                                    withCompletion:^(NSArray *results, NSError *error)
     {
         if (weakSelf.currentLocation == location && !error)
         {
             NSInteger index = [results indexOfObjectPassingTest:^BOOL(WDDLocation *locationFourSquare, NSUInteger idx, BOOL *stop)
                                {
                                    return ([location.name caseInsensitiveCompare:locationFourSquare.name] == NSOrderedSame);
                                }];
             
             if (index != NSNotFound)
             {
                 weakSelf.currentLocation.foursquareID = [results[index] foursquareID];
             }
             else
             {
                 results = [results sortedArrayUsingComparator:^NSComparisonResult(WDDLocation *location1, WDDLocation *location2)
                            {
                                double sqr1 = (location1.latidude - location.latidude) * (location1.latidude - location.latidude) + (location1.longitude - location.longitude) * (location1.longitude - location.longitude);
                                double sqr2 = (location2.latidude - location.latidude) * (location2.latidude - location.latidude) + (location2.longitude - location.longitude) * (location2.longitude - location.longitude);
                                if (sqr1 < sqr2)
                                {
                                    return NSOrderedAscending;
                                }
                                else if (sqr1 > sqr2)
                                {
                                    return NSOrderedDescending;
                                }
                                else return NSOrderedSame;
                            }];
                 weakSelf.currentLocation.foursquareID = [results.firstObject foursquareID];
             }
         }
     }];
}

#pragma mark - Image View User Choose
/*
-(void)setupImagePreView:(UIImage *)image
{
    const int kPicWidth = 40;
    const int kPicHeight = 40;
    const int kDistBetwTextAndImage = 5;
    
    int updatedTextHeight = self.inputTextview.frame.size.height - kPicHeight - kDistBetwTextAndImage;
    
    DLog(@"frame = %f", self.inputTextview.frame.size.height);
    [self.mainView layoutSubviews];
    
    self.textViewConstraint.constant = self.textViewConstraint.constant + kPicHeight + kDistBetwTextAndImage;
    
    UIImageView* preViewImageView = [[UIImageView alloc] init];
    
    preViewImageView.image = image;
    
    preViewImageView.frame = CGRectMake(self.inputTextview.frame.origin.x, updatedTextHeight + kDistBetwTextAndImage + kDistBetwTextAndImage, kPicWidth, kPicHeight);
    
    [self.mainView addSubview:preViewImageView];
    
    //self.textViewHeightConstraint.constant = textView.contentSize.height
}
 */

@end
