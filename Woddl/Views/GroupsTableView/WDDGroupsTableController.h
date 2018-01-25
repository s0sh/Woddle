//
//  WDDGroupsTableController.h
//  Woddl
//
//  Created by Sergii Gordiienko on 27.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, GroupTableMasks)
{
    kGroupTableNone       = 0,
    kGroupTableEvents     = 1 << 0,
    kGroupTableGroups     = 1 << 1,
    kGroupTablePages      = 1 << 2
};

@class Post, Group;

@protocol WDDGroupsTableControllerDelegate <NSObject>
//  Section buttons actions
- (void)didEventsSectionPressed;
- (void)didGroupsSectionPressed;
- (void)didPagesSectionPressed;

//  Cell actions
- (void)showEventInformationForEvent:(Post *)event;
- (void)didSelectGroup:(Group *)group;
- (void)didBlockUnblockGroup:(Group *)group;

- (void)didChangeStateForEvents:(BOOL)state;
- (void)didChangeStateForGroups:(BOOL)state;
- (void)didChangeStateForPages:(BOOL)state;

@end

@interface WDDGroupsTableController : NSObject <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) id<WDDGroupsTableControllerDelegate> delegate;

- (void)    setEvents:(NSArray *)events
               groups:(NSArray *)groups
                pages:(NSArray *)pages
     expandedSections:(NSUInteger)expanedSections
       sectionsStates:(NSArray *)states
         forTableView:(UITableView *)tableView;

- (NSUInteger)numberOfSections;
- (CGFloat)heightForTableView;

+ (CGFloat)heightForEvents:(NSArray *)events
                    groups:(NSArray *)groups
                     pages:(NSArray *)pages
      withExpandedSections:(NSUInteger)expanedSections;

@end
