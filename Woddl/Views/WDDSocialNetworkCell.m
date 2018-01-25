//
//  WDDCell.m
//  Woddl
//
//  Created by Sergii Gordiienko on 30.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDSocialNetworkCell.h"
#import "UIImageView+WebCache.h"

static NSString * const kStateChecked = @"Sidebar_account_enabled";
static NSString * const kStateUnchecked = @"Sidebar_account_disabled";

const CGFloat kShowGroupsButtonHeight = 30.0f;

@interface WDDSocialNetworkCell () <WDDGroupsTableControllerDelegate>

@property (nonatomic, assign) BOOL isExpanded;
@property (weak, nonatomic) IBOutlet UIView *slidingView;
@property (strong, nonatomic) WDDGroupsTableController *groupsContoller;
@end

@implementation WDDSocialNetworkCell

- (void)awakeFromNib
{
    UIButton *settingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    settingsButton.frame = CGRectMake(/*-30.f*/10.f, 0.f, 30.f, 40.f);
    settingsButton.userInteractionEnabled = YES;
    [settingsButton setImage:[UIImage imageNamed:@"SettingsIcon"] forState:UIControlStateNormal];
    [settingsButton addTarget:self action:@selector(settingsPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self.contentView addSubview:settingsButton];
    [self.contentView sendSubviewToBack:settingsButton];
    
    
    if (IS_IOS7)
    {
        id superView = [self.contentView superview];
        
        if ([superView isKindOfClass:[UIScrollView class]])
        {
            UIScrollView * scrollView = superView;
            
            [scrollView setScrollEnabled:NO];
        }
    }
    
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showSettingsButton:)];
    rightSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self addGestureRecognizer:rightSwipe];
    
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showSettingsButton:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self addGestureRecognizer:leftSwipe];
    
    [self.stateButton addTarget:self action:@selector(stateChanged:) forControlEvents:UIControlEventTouchUpInside];
    
    self.groupsTableView.delegate = self.groupsContoller;
    self.groupsTableView.dataSource = self.groupsContoller;
    self.groupsTableView.scrollsToTop = NO;
    
    self.groupsButtonHeightConstraint.constant = 0.0f;
    self.groupsTableViewHeightConstraint.constant = 0.0f;
    self.groupsButton.hidden = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.groupsTableViewHeightConstraint.constant =  ([self.groupsContoller numberOfSections] ? [self.groupsContoller heightForTableView] : 0);
}

- (WDDGroupsTableController *)groupsContoller
{
    if (!_groupsContoller)
    {
        _groupsContoller = [[WDDGroupsTableController alloc] init];
    }
    return _groupsContoller;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (!self.isExpanded)
    {
        [super setSelected:selected animated:animated];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (!self.isExpanded)
    {
        [super setHighlighted:highlighted animated:animated];
    }
}

- (void)prepareForReuse
{
    [self resetAllControls];
    [self setExpanded:NO animated:NO];
    self.delegate = nil;
    self.groupsContoller = nil;
    self.groupsButtonHeightConstraint.constant = 0.0f;
    self.groupsTableViewHeightConstraint.constant = 0.0f;
    self.expandedSections = kGroupTableNone;
    self.groupsButton.hidden = YES;
    
    [super prepareForReuse];
}

- (void)resetAllControls
{
    self.displayName.text = nil;
    self.avatarImage.image = nil;

}

#pragma mark - Instance methods

- (void)setExpanded:(BOOL)isExpanded animated:(BOOL)animated
{
    CGRect contentFrame = self.slidingView.frame;
    
    if (self.isExpanded && !isExpanded)
    {
        contentFrame.origin.x = 0.f;
    }
    else if (!self.isExpanded && isExpanded)
    {
        contentFrame.origin.x = 40.f;
    }
    
    if (animated)
    {
        [UIView animateWithDuration:0.15 animations:^{

            self.slidingView.frame = contentFrame;
        }];
    }
    else
    {
        self.slidingView.frame = contentFrame;
    }

    self.isExpanded = isExpanded;
}

- (void)    setEvents:(NSArray *)events
               groups:(NSArray *)groups
                pages:(NSArray *)pages
     expandedSections:(NSUInteger)expanedSections
       sectionsStates:(NSArray *)states
{
    self.expandedSections = expanedSections;

    [self.groupsContoller setEvents:events
                             groups:groups
                              pages:pages
                   expandedSections:expanedSections
                     sectionsStates:states
                       forTableView:self.groupsTableView];
    self.groupsContoller.delegate = self;
}

#pragma mark - Gesture Recognizers methods

- (void)showSettingsButton:(UISwipeGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.direction == UISwipeGestureRecognizerDirectionRight)
    {
        [self setExpanded:YES animated:YES];
    }
    else
    {
        [self setExpanded:NO animated:YES];
    }
}

#pragma mark - Class methods

+ (CGFloat)calculateCellHeightForEvents:(NSArray *)events
                                 groups:(NSArray *)groups
                                  pages:(NSArray *)pages
                   withExpandedSections:(NSUInteger)expanedSections
{
    CGFloat finalHeight = kCellBaseHeight;
//#if FB_GROUPS_SUPPORT == ON
    CGFloat groupsHeight = [WDDGroupsTableController heightForEvents:events
                                                          groups:groups
                                                           pages:pages
                                            withExpandedSections:expanedSections];
    finalHeight += groupsHeight;
//#endif
    
    return finalHeight;
}

#pragma mark - Actions

- (IBAction)expandGroupsAction
{
    //   TODO: change implementation
    self.groupsButton.selected = !self.groupsButton.selected;
    
    if ([self.delegate respondsToSelector:@selector(expandGroupsForCell:)])
    {
        [self.delegate expandGroupsForCell:self];
    }
}

- (void)settingsPressed
{
    if ([self.delegate respondsToSelector:@selector(settingsButtonPressedForCell:)])
    {
        [self.delegate settingsButtonPressedForCell:self];
    }
}

- (void)stateChanged:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(accountStatusChangesForCell:)])
    {
        [self.delegate accountStatusChangesForCell:self];
    }
}

#pragma mark - WDDGroupsTableControllerDelegate

- (void)didEventsSectionPressed
{
    if ([self.delegate respondsToSelector:@selector(expandEventsForCell:)])
    {
        [self.delegate expandEventsForCell:self];
    }
}

- (void)didGroupsSectionPressed
{
    if ([self.delegate respondsToSelector:@selector(expandGroupsForCell:)])
    {
        [self.delegate expandGroupsForCell:self];
    }
}

- (void)didPagesSectionPressed
{
    if ([self.delegate respondsToSelector:@selector(expandPagesForCell:)])
    {
        [self.delegate expandPagesForCell:self];
    }
}

- (void)showEventInformationForEvent:(Post *)event
{
    if ([self.delegate respondsToSelector:@selector(showEventInformationForCell:withEvent:)])
    {
        [self.delegate showEventInformationForCell:self withEvent:event];
    }
}

- (void)didSelectGroup:(Group *)group
{
    if ([self.delegate respondsToSelector:@selector(filterWithGroup:)])
    {
        [self.delegate filterWithGroup:group];
    }
}

- (void)didBlockUnblockGroup:(Group *)group
{
    [self.delegate filterWithGroup:nil];
}

- (void)didChangeStateForEvents:(BOOL)state
{
    [self.delegate didChangeStateForEvents:state inCell:self];
}

- (void)didChangeStateForGroups:(BOOL)state
{
    [self.delegate didChangeStateForGroups:state inCell:self];
}

- (void)didChangeStateForPages:(BOOL)state
{
    [self.delegate didChangeStateForPages:state inCell:self];
}

@end
