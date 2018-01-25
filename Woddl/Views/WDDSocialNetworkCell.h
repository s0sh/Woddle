//
//  WDDCell.h
//  Woddl
//
//  Created by Sergii Gordiienko on 30.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SocialNetwork.h"
#import "WDDGroupsTableController.h"

typedef NS_ENUM(NSInteger, SocialNetworkCellMode)
{
    NormalModeCell,
    ExpandedModeCell
};

static CGFloat const kCellBaseHeight = 44.0f;

@class WDDSocialNetworkCell;

@protocol WDDSocialNetworkCellDelegate <NSObject>

- (void)settingsButtonPressedForCell:(WDDSocialNetworkCell *)cell;
- (void)accountStatusChangesForCell:(WDDSocialNetworkCell *)cell;

- (void)expandEventsForCell:(WDDSocialNetworkCell *)cell;
- (void)expandGroupsForCell:(WDDSocialNetworkCell *)cell;
- (void)expandPagesForCell:(WDDSocialNetworkCell *)cell;

- (void)showEventInformationForCell:(WDDSocialNetworkCell *)cell withEvent:(Post *)event;
- (void)filterWithGroup:(Group *)group;

- (void)didChangeStateForEvents:(BOOL)state inCell:(WDDSocialNetworkCell *)cell;
- (void)didChangeStateForGroups:(BOOL)state inCell:(WDDSocialNetworkCell *)cell;
- (void)didChangeStateForPages:(BOOL)state inCell:(WDDSocialNetworkCell *)cell;

@end

@interface WDDSocialNetworkCell : UITableViewCell

//  Views
@property (weak, nonatomic) IBOutlet UILabel *displayName;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImage;
@property (weak, nonatomic) IBOutlet UIButton *stateButton;
@property (weak, nonatomic) IBOutlet UITableView *groupsTableView;
@property (weak, nonatomic) IBOutlet UIButton *groupsButton;

// Constaints
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupsButtonHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *groupsTableViewHeightConstraint;

@property (nonatomic, readonly) BOOL isExpanded;
@property (assign, nonatomic) NSInteger expandedSections;

@property (nonatomic, weak) id <WDDSocialNetworkCellDelegate> delegate;

- (void)setExpanded:(BOOL)isExpanded animated:(BOOL)animated;

- (void)    setEvents:(NSArray *)events
               groups:(NSArray *)groups
                pages:(NSArray *)pages
     expandedSections:(NSUInteger)expanedSections
       sectionsStates:(NSArray *)states;

+ (CGFloat)calculateCellHeightForEvents:(NSArray *)events
                                 groups:(NSArray *)groups
                                  pages:(NSArray *)pages
                   withExpandedSections:(NSUInteger)expanedSections;

@end
