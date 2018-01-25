//
//  WDDGroupsTableController.m
//  Woddl
//
//  Created by Sergii Gordiienko on 27.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDGroupsTableController.h"
#import "WDDGroupCell.h"

#import "Group.h"
#import "WDDDataBase.h"
#import "WDDEventsSideMenuCell.h"

static NSString * const kStateChecked = @"Sidebar_account_enabled";
static NSString * const kStateUnchecked = @"Sidebar_account_disabled";

const CGFloat kGroupCellHeight = 30.0f;
const CGFloat kSectionHeight = 30.0f;
const CGFloat kSectionButtonWidth = 320.0f;
static CGFloat kSectionButtonTitleLeftOffset = 0.0f;
static CGFloat kSectionButtonTitleLeftInset = 40.0f;
static CGFloat kSectionButtonImageLeftInset = 120.0f;

@interface WDDGroupsTableController() <WDDGroupCellDelegate>

@property (strong, nonatomic) NSArray *events;
@property (strong, nonatomic) NSArray *groups;
@property (strong, nonatomic) NSArray *pages;
@property (strong, nonatomic) NSMutableArray *states;

@property (strong, nonatomic) UITableView *tableView;

@property (assign, nonatomic) NSUInteger expandedSections;
@end

@implementation WDDGroupsTableController

#pragma mark - Instance public methods
- (void)    setEvents:(NSArray *)events
               groups:(NSArray *)groups
                pages:(NSArray *)pages
     expandedSections:(NSUInteger)expanedSections
       sectionsStates:(NSArray *)states
         forTableView:(UITableView *)tableView
{
    self.events = events;
    self.groups = groups;
    self.pages = pages;
    self.states = [states mutableCopy];
    
    self.expandedSections = expanedSections;
    self.tableView = tableView;
    if (tableView)
    {
        tableView.delegate = self;
        tableView.dataSource = self;
        [tableView reloadData];
    }
    
    if ([[NSLocale preferredLanguages].firstObject isEqualToString:@"ru"])
    {
        kSectionButtonTitleLeftOffset = 0.0f;
        kSectionButtonTitleLeftInset = 40.0f;
        kSectionButtonImageLeftInset = 145.0f;
    }
}

- (CGFloat)heightForTableView
{
    return [WDDGroupsTableController heightForEvents:self.events
                                              groups:self.groups
                                               pages:self.pages
                                withExpandedSections:self.expandedSections];
}

- (NSUInteger)numberOfSections
{
    NSUInteger numberOfSections = 0;
#if FB_EVENTS_SUPPORT == ON
    if (self.events.count)
    {
        numberOfSections ++;
    }
#endif
    
//#if FB_GROUPS_SUPPORT == ON
    if (self.groups.count)
    {
        numberOfSections ++;
    }
    if (self.pages.count)
    {
        numberOfSections ++;
    }
//#endif
    
    return numberOfSections;
}

#pragma mark - Class methods

+ (CGFloat)heightForEvents:(NSArray *)events
                    groups:(NSArray *)groups
                     pages:(NSArray *)pages
      withExpandedSections:(NSUInteger)expanedSections;

{
    CGFloat height = 0.0f;
    if (events.count)
    {
        height += kSectionHeight;
        if (expanedSections & kGroupTableEvents)
        {
            for (Post *event in events)
            {
                height += [WDDEventsSideMenuCell calculateCellHeightForText:event.text];
            }
        }
    }
    if (groups.count)
    {
        height += kSectionHeight;
        height += ( expanedSections & kGroupTableGroups ? kGroupCellHeight*groups.count : 0 );
    }
    if (pages.count)
    {
        height += kSectionHeight;
        height += ( expanedSections & kGroupTablePages ? kGroupCellHeight*pages.count : 0 );
    }
    
    return height;
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSections = [self numberOfSections];
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *objectsInSection = [self objectsForSection:section];
    
    NSInteger numberOfRows = 0;
    if (objectsInSection == self.events)
    {
        numberOfRows = [self numberOfRowsForSection:kGroupTableEvents withObjects:objectsInSection];
    }
    else if (objectsInSection == self.groups)
    {
        numberOfRows = [self numberOfRowsForSection:kGroupTableGroups withObjects:objectsInSection];
    }
    else if (objectsInSection == self.pages)
    {
        numberOfRows = [self numberOfRowsForSection:kGroupTablePages withObjects:objectsInSection];
    }
    
    return numberOfRows;
}

- (NSInteger)numberOfRowsForSection:(GroupTableMasks)sectionType withObjects:(NSArray *)objectsInSection
{
    return ( self.expandedSections & sectionType ? objectsInSection.count : 0 );
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat rowHeight = kGroupCellHeight;
    
    NSArray *objects = [self objectsForSection:indexPath.section];
    if (objects == self.events)
    {
        Post *event = objects[indexPath.row];
        NSString *preview = event.text;
        NSRange previewRange = [preview rangeOfString:@"\n"];
        if (previewRange.location != NSNotFound)
        {
            preview = [preview substringToIndex:previewRange.location];
        }
        rowHeight = [WDDEventsSideMenuCell calculateCellHeightForText:preview];
    }
    
    return rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kSectionHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(tableView.frame), kSectionHeight)];
    view.backgroundColor = [UIColor whiteColor];
    [view setUserInteractionEnabled:YES];
    
   
    UIButton *sectionButton = [self sectionButtonForSection:section];
    [view addSubview:sectionButton];
    
    return view;
}

- (UIButton *)sectionButtonForSection:(NSInteger)section
{
    NSString *buttonTitle;
    BOOL isExpanded;
    NSString *iconName = nil;
    SEL buttonAction;
    BOOL isEnabled;
    
    NSArray *objects = [self objectsForSection:section];
    if (objects == self.events)
    {
        buttonTitle = NSLocalizedString(@"lskEventsSideMenuButton", @"Button title");
        isExpanded = ( self.expandedSections & kGroupTableEvents ? YES : NO );
        buttonAction = @selector(eventsSectionButtonPressed:);
        iconName = @"EventIcon";
        isEnabled = [self.states[0] integerValue];
    }
    else if (objects == self.groups)
    {
        buttonTitle = NSLocalizedString(@"lskGroupsSideMenuButton", @"Button title");
        isExpanded = ( self.expandedSections & kGroupTableGroups ? YES : NO );
        buttonAction = @selector(groupsSectionButtonPressed:);
        iconName = @"GroupIcon";
        isEnabled = [self.states[1] integerValue];
    }
    else // pages
    {
        buttonTitle = NSLocalizedString(@"lskPagesSideMenuButton", @"Button title");
        isExpanded = ( self.expandedSections & kGroupTablePages ? YES : NO );
        buttonAction = @selector(pagesSectionButtonPressed:);
        iconName = @"PageIcon";
        isEnabled = [self.states[2] integerValue];
    }
    
    UIButton *sectionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [sectionButton addTarget:self action:buttonAction forControlEvents:UIControlEventTouchUpInside];
    sectionButton.frame = CGRectMake(kSectionButtonTitleLeftOffset, 0.0f, kSectionButtonWidth, kSectionHeight);
    
    [sectionButton setImage:[UIImage imageNamed:@"ArrowRight"] forState:UIControlStateNormal];
    [sectionButton setImage:[UIImage imageNamed:@"ArrowDown"] forState:UIControlStateSelected];
    
    [sectionButton setTitle:buttonTitle forState:UIControlStateNormal];
    [sectionButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    
    sectionButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];;
    sectionButton.selected = isExpanded;
    sectionButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    sectionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    sectionButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, kSectionButtonTitleLeftInset, 0.0f, 0.0f);
    sectionButton.imageEdgeInsets = UIEdgeInsetsMake(0.0f, kSectionButtonImageLeftInset, 0.0f, 0.0f);

    sectionButton.backgroundColor = [UIColor whiteColor];
    sectionButton.opaque = YES;
    
    UIImage *iconImage = [UIImage imageNamed:iconName];
    UIImageView *icon = [[UIImageView alloc] initWithImage:iconImage];
    icon.center = CGPointMake(27.f, CGRectGetHeight(sectionButton.frame) / 2.f);
    icon.backgroundColor = [UIColor whiteColor];
    icon.opaque = YES;
    [sectionButton addSubview:icon];
    
    UIButton *checkbox = [UIButton buttonWithType:UIButtonTypeCustom];
    [checkbox setImage:[UIImage imageNamed:@"SidebarGroupDisabled"]
              forState:UIControlStateNormal];
    [checkbox setImage:[UIImage imageNamed:@"SidebarGroupEnabled"]
              forState:UIControlStateSelected];
    checkbox.frame = (CGRect){CGPointZero, CGSizeMake(35.f, 35.f)};
    checkbox.center = CGPointMake(225.f, CGRectGetHeight(sectionButton.frame) / 2.f);
    [checkbox addTarget:self action:@selector(gruopSwitcher:) forControlEvents:UIControlEventTouchUpInside];
    checkbox.tag = section;
    checkbox.selected = isEnabled;
    checkbox.backgroundColor = [UIColor whiteColor];
    checkbox.opaque = YES;
    [sectionButton addSubview:checkbox];

    return sectionButton;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString * const kGroupCellIdentifier = @"WDDGroupCell";
    static NSString * const kEventCellIdentifier = @"WDDEventsSideMenuCell";
    
    UITableViewCell *cell;
    
    NSArray *objects = [self objectsForSection:indexPath.section];
    id object = objects[indexPath.row];
    
    if (objects == self.events)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:kEventCellIdentifier forIndexPath:indexPath];
        id event = object;
        [self configureEventsCell:(WDDEventsSideMenuCell *)cell forEvent:event];
    }
    else if (objects == self.groups)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:kGroupCellIdentifier forIndexPath:indexPath];
        Group *group = object;
        [self configureGroupCell:(WDDGroupCell*)cell forGroup:group];
    }
    else if (objects == self.pages)
    {
        //  TODO: implement here Page logicm if there will be difference with Group logic
        cell = [tableView dequeueReusableCellWithIdentifier:kGroupCellIdentifier forIndexPath:indexPath];
        Group *page = object;
        [self configurePageCell:cell forPage:page];
    }
    
    return cell;
}

- (void)configureEventsCell:(WDDEventsSideMenuCell *)cell forEvent:(Post *)event
{
    NSString *preview = event.text;
    NSRange previewRange = [preview rangeOfString:@"\n"];
    if (previewRange.location != NSNotFound)
    {
        preview = [preview substringToIndex:previewRange.location];
    }
    
    cell.eventInformationLabel.text = preview;
}

- (void)configureGroupCell:(WDDGroupCell *)cell forGroup:(Group *)group
{
    cell.delegate = self;
    cell.groupNameLabel.text = group.name;
    NSString *stateImageName = ([group.isGroupBlock boolValue] ? kStateUnchecked : kStateChecked);
    [cell.groupStatusButton setImage:[UIImage imageNamed:stateImageName] forState:UIControlStateNormal];
}

- (void)configurePageCell:(id)cell forPage:(id)event
{
    //  TODO: implement here Page logicm if there will be difference with Group logic
    [self configureGroupCell:cell forGroup:event];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *objects = [self objectsForSection:indexPath.section];
    id object = objects[indexPath.row];
    
    if (objects == self.events)
    {
        [self actionOnSelectionForEvent:object];
    }
    else if (objects == self.groups)
    {
        [self actionOnSelectionForGroup:object];
    }
    else if (objects == self.pages)
    {
        //  TODO: implement here Page logicm if there will be difference with Group logic
        [self actionOnSelectionForPage:object];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationRefetchMainSreenTable
                                                        object:nil];
    
    [tableView beginUpdates];
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [tableView endUpdates];
}

- (void)actionOnSelectionForEvent:(Post *)event
{
    if ([self.delegate respondsToSelector:@selector(showEventInformationForEvent:)])
    {
        [self.delegate showEventInformationForEvent:event];
    }
}

- (void)actionOnSelectionForGroup:(Group *)group
{
    if ([self.delegate respondsToSelector:@selector(didSelectGroup:)])
    {
        [self.delegate didSelectGroup:group];
    }
}

- (void)actionOnSelectionForPage:(id)page
{
    //  TODO: implement here Page logicm if there will be difference with Group logic
    [self actionOnSelectionForGroup:page];
}

#pragma mark - Logic methods

- (NSArray *)objectsForSection:(NSInteger)section
{
    NSArray *objects;
    switch ([self numberOfSections])
    {
        case 3:
            objects = [self objectsFromThreeSectionsForSection:section];
            break;
        case 2:
            objects = [self objectsFromTwoSectionsForSection:section];
            break;
        case 1:
            objects = [self objectsFromOneSectionsForSection:section];
            break;
    }
    return objects;
}

- (NSArray *)objectsFromThreeSectionsForSection:(NSInteger)section
{
    NSArray *objects;
    switch (section)
    {
        case 0:
            objects = self.events;
            break;
        case 1:
            objects = self.groups;
            break;
        case 2:
            objects = self.pages;
            break;
    }
    return objects;
}

- (NSArray *)objectsFromTwoSectionsForSection:(NSInteger)section
{
    NSArray *objects;
    
    if (self.events.count && self.groups.count)
    {
        if (0 == section)
        {
            objects = self.events;
        }
        else
        {
            objects = self.groups;
        }
    }
    else if (self.events.count && self.pages.count)
    {
        if (0 == section)
        {
            objects = self.events;
        }
        else
        {
            objects = self.pages;
        }
    }
    else if (self.groups.count && self.pages.count)
    {
        if (0 == section)
        {
            objects = self.groups;
        }
        else
        {
            objects = self.pages;
        }
    }
    
    return objects;
}

- (NSArray *)objectsFromOneSectionsForSection:(NSInteger)section
{
    NSArray *objects;
    
    if (self.events.count)
    {
        objects = self.events;
    }
    else if (self.groups.count)
    {
        objects = self.groups;
    }
    else if (self.pages.count)
    {
        objects = self.pages;
    }
    
    return objects;
}

#pragma mark - Sections' actions

- (void)eventsSectionButtonPressed:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(didEventsSectionPressed)])
    {
        [self.delegate didEventsSectionPressed];
    }
}

- (void)groupsSectionButtonPressed:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(didGroupsSectionPressed)])
    {
        [self.delegate didGroupsSectionPressed];
    }
}

- (void)pagesSectionButtonPressed:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(didPagesSectionPressed)])
    {
        [self.delegate didPagesSectionPressed];
    }
}

- (void)groupCelldidTapGroupStatusButton:(WDDGroupCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    NSArray *objects = [self objectsForSection:indexPath.section];
    Group* group = objects[indexPath.row];

    BOOL newState = ![group.isGroupBlock boolValue];
    group.isGroupBlock = [NSNumber numberWithBool:newState];
    [[WDDDataBase sharedDatabase] save];
    
    [self.delegate didBlockUnblockGroup:group];
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)gruopSwitcher:(UIButton *)sender
{
    NSInteger section = sender.tag;
    NSArray *objects = [self objectsForSection:section];
    
    sender.selected = !sender.selected;
    NSInteger index = -1;
    
    if (objects == self.events)
    {
        index = 0;
        [self.delegate didChangeStateForEvents:sender.selected];
    }
    else if (objects == self.groups)
    {
        index = 1;
        [self.delegate didChangeStateForGroups:sender.selected];
    }
    else // pages
    {
        index = 2;
        [self.delegate didChangeStateForPages:sender.selected];
    }
    
    [self.states replaceObjectAtIndex:index withObject:@(sender.selected)];
}

@end
