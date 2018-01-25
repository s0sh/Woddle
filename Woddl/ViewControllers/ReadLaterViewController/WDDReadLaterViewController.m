//
//  WDDReadLaterViewController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 14.04.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "WDDReadLaterViewController.h"
#import "WDDMainScreenViewController.h"
#import "WDDDataBase.h"

@interface WDDReadLaterViewController ()

//@property (strong, nonatomic) NSFetchedResultsController * fetchedResultsController;

@end

@implementation WDDReadLaterViewController

#pragma mark - Lifecircle
#pragma mark

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupBackButton];
    [self setupNavigationBarTitle];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Heatmaps trackScreenWithKey:@"503395516a70d21a-31180221"];
}

#pragma mark - Setup methods
#pragma mark

- (void)setupBackButton
{
    UIImage *backButtonImage = [UIImage imageNamed:kBackButtonArrowImageName];
    
    UIButton *customBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customBackButton.bounds = CGRectMake( 0, 0, backButtonImage.size.width, backButtonImage.size.height );
    [customBackButton setImage:backButtonImage forState:UIControlStateNormal];
    [customBackButton addTarget:self.mainScreenViewController
                         action:@selector(showMainScreenAction:)
               forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:customBackButton];
}

#pragma mark - Accessories
#pragma mark

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (super.fetchedResultsController != nil) {
        return super.fetchedResultsController;
    }
    
    [NSFetchedResultsController deleteCacheWithName:kPostMessagesCache];
    NSManagedObjectContext *context = [WDDDataBase sharedDatabase].managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([Post class]) inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    [fetchRequest setFetchBatchSize:20];
    
    //  Sort descriptors
    NSSortDescriptor *sortDescriptorByTime = [[NSSortDescriptor alloc] initWithKey:kPostTimeKey ascending:NO];
    
    
    NSArray *sortDescriptors = @[sortDescriptorByTime];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSPredicate *predicate = [self formPredicate];
    [fetchRequest setPredicate:predicate];
    
    
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:context
                                                                                                  sectionNameKeyPath:nil
                                                                                                           cacheName:kPostMessagesCache];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        DLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return super.fetchedResultsController;
}

- (NSPredicate *)formPredicate
{
    NSPredicate *finalPredicate;
    
    NSPredicate *authorPredicate= [NSPredicate predicateWithFormat:@"SELF.author.isBlocked == %@ AND SELF.group == nil", @NO];
    NSPredicate *groupPredicate = [NSPredicate predicateWithFormat:@"SELF.group.isGroupBlock == %@ AND SELF.group != nil", @NO];
    finalPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[ authorPredicate, groupPredicate ]];
    
    NSPredicate *readLaterPredicate = [NSPredicate predicateWithFormat:@"SELF.isReadLater == %@", @YES];
    
    finalPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[ readLaterPredicate, finalPredicate ]];
    
    return finalPredicate;
}

#pragma mark - WDDMainPostCell delegate
#pragma mark

- (void)deleteFromReadLaterListFromCell:(WDDMainPostCell *)cell
{
    NSIndexPath *indexPath = [self.postsTable indexPathForCell:cell];
    Post *post = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    post.isReadLater = @NO;
    
    [[WDDDataBase sharedDatabase] save];
    
    DLog(@"Post at index path: %@ was deleted from reading list", indexPath);
}

#pragma mark - Methods for overloading in WDDBasePostViewController
#pragma mark

- (NSString *)goToCommentsScreenSegueIdentifier
{
    return kStoryboardSegueIDWriteCommentFromReadLater;
}

- (BOOL)shouldShowCellDeleteButton
{
    return YES;
}

@end
