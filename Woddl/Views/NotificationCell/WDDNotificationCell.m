//
//  WDDNotificationCell.m
//  Woddl
//

#import "WDDNotificationCell.h"

#import "Notification.h"
#import "SocialNetwork.h"
#import "UserProfile.h"

#import <NSDate+TimeAgo/NSDate+TimeAgo.h>
#import "NSDate+fromDate.h"
#import "UIImageView+AvatarLoading.h"

@interface WDDNotificationCell ()
{
    BOOL _expanded;
}

@property (weak, nonatomic) IBOutlet UIImageView *notificationObjectPicture;
@property (weak, nonatomic) IBOutlet UIImageView *notificationLogo;
@property (weak, nonatomic) IBOutlet UIImageView *socialNetworkAvatar;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIView *unreadShield;

@end

@implementation WDDNotificationCell

- (void)prepareForReuse
{
    self.expanded = NO;
}

- (void)setNotification:(Notification*)notification
{
    self.titleLabel.text    = notification.title;
    
    NSDateFormatter * formatter=[[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm a"];
    NSString *messageTime = [formatter stringFromDate:notification.date];
    
    self.dateLabel.text   = [NSString stringWithFormat:@"%@ %@", messageTime, [notification.date timeAgoFromToday]];
    
    if (notification.group && notification.group.imageURL.length)
    {
        [self.notificationObjectPicture setImageWithURL:[NSURL URLWithString:notification.group.imageURL]];
    }
    else if (notification.post.media.count && ([[notification.post.media anyObject] previewURLString].length || [[notification.post.media anyObject] mediaURLString].length))
    {
        if ([[notification.post.media anyObject] previewURLString].length)
        {
            [self.notificationObjectPicture setImageWithURL:[NSURL URLWithString:[[notification.post.media anyObject] previewURLString]]];
        }
        else if ([[notification.post.media anyObject] mediaURLString].length)
        {
            [self.notificationObjectPicture setImageWithURL:[NSURL URLWithString:[[notification.post.media anyObject] mediaURLString]]];
        }
    }
    else if (notification.media && ([notification.media previewURLString].length || [notification.media mediaURLString].length))
    {
        if ([notification.media previewURLString].length)
        {
            [self.notificationObjectPicture setImageWithURL:[NSURL URLWithString:notification.media.previewURLString]];
        }
        else if ([notification.media mediaURLString].length)
        {
            [self.notificationObjectPicture setImageWithURL:[NSURL URLWithString:notification.media.mediaURLString]];
        }
    }
    else if (notification.sender)
    {
        [self.notificationObjectPicture setAvatarWithURL:[NSURL URLWithString:notification.sender.avatarRemoteURL]];
    }
    else
    {
        [self.notificationObjectPicture setImageWithURL:[NSURL URLWithString:notification.iconURL]];
    }

    if ([notification.socialNetwork.type integerValue] == kSocialNetworkTwitter || [notification.socialNetwork.type integerValue] == kSocialNetworkLinkedIN)
    {
        [self.notificationLogo setImage:[UIImage imageNamed:notification.socialNetwork.socialNetworkIconName]];
    }
    else
    {
        [self.notificationLogo setImageWithURL:[NSURL URLWithString:notification.iconURL]];
    }
    
    [self.socialNetworkAvatar setAvatarWithURL:[NSURL URLWithString:notification.socialNetwork.profile.avatarRemoteURL]];
    
    self.unreadShield.hidden = !notification.isUnread.boolValue || (notification.isUnread == nil);
}

- (void)blinkUnreadShield
{
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.5f
                          delay:0.1f
                        options:0
                     animations:^()
    {
        weakSelf.unreadShield.alpha = 1.0f;
    }
                     completion:^(BOOL finished)
    {
        [UIView animateWithDuration:0.5f
                              delay:0.1f
                            options:0         
                         animations:^()
        {
            weakSelf.unreadShield.alpha = 0.0f;
        }
                         completion:^(BOOL finished)
        {
            weakSelf.unreadShield.hidden = YES;
        }];
    }];
}

- (BOOL)expanded
{
    return _expanded;
}

- (void)setExpanded:(BOOL)expanded
{
    _expanded = expanded;
    if (expanded)
    {
        [self.titleLabel setNumberOfLines:0];
    }
    else
    {
        [self.titleLabel setNumberOfLines:2];
    }
}

@end
