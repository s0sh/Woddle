//
//  WDDBasePostsViewController.h
//  Woddl
//
//  Created by Sergii Gordiienko on 06.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <OHAttributedLabel.h>
#import "WDDMainPostCell.h"
#import "IDSEllipseMenu.h"
#import <MessageUI/MessageUI.h>

static NSString * const kPostMessagesCache              = @"PostMessagesCache";
extern NSString * const kPostTimeKey;

@interface WDDBasePostsViewController : UIViewController <NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate, OHAttributedLabelDelegate, WDDMainPostCellDelegate, IDSEllipseMenuDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *postsTable;

@property (assign, nonatomic) BOOL isAppeared;
@property (nonatomic, assign) BOOL needProcessUpdates;

@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;

//  HUD representation methods
- (void)showProcessHUDWithText:(NSString *)text;
- (void)removeProcessHUDOnSuccessLoginHUDWithText:(NSString *)text;
- (void)removeProcessHUDOnFailLoginHUDWithText:(NSString *)text;

//  Predicate based on SN settings logic
- (NSPredicate *)availableNetworksPredicate;
- (void)reloadTableContent;

+ (void)addPhotoToGallery:(UIImage *)image;

@end
