//
//  WDDLinkedInEllipseMenu.m
//  Woddl
//
//  Created by Sergii Gordiienko on 15.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDLinkedInEllipseMenu.h"

@implementation WDDLinkedInEllipseMenu

- (NSArray *)leftSideButtonsImageNames
{
    NSMutableArray *images = [[NSMutableArray alloc] init];
    if (self.isLikeAvailable)
    {
        [images addObject:kLinkedInLikeButtonImageName];
    }
    
    if (self.isCommentAvailable)
    {
        [images addObject:kLinkedInCommentButtonImageName];
    }
    
    [images addObjectsFromArray:@[kLinkedInBlockButtonImageName,
                                  kLinkedInMailButtonImageName,
                                  kLinkedInCopyLinkButtonImageName,
                                  kLinkedInReadLaterButtonImageName]];
    
    if (self.isSaveImageAvailable)
    {
        [images addObject:kLinkedInSaveImageButtonImageName];
    }
    
    return images;
}

- (NSInteger)tagForImageName:(NSString *)imageName
{
    NSInteger tag = [super tagForImageName:imageName];
    if (!tag)
    {
        if ([imageName isEqualToString:kLinkedInLikeButtonImageName])
        {
            tag = kEllipseMenuLikeButtonTag;
        }
        else if ([imageName isEqualToString:kLinkedInCommentButtonImageName])
        {
            tag = kEllipseMenuCommentButtonTag;
        }
        else if ([imageName isEqualToString:kLinkedInShareButtonImageName])
        {
            tag = kEllipseMenuShareButtonTag;
        }
        else if ([imageName isEqualToString:kLinkedInMailButtonImageName])
        {
            tag = kEllipseMenuMailButtonTag;
        }
        else if ([imageName isEqualToString:kLinkedInCopyLinkButtonImageName])
        {
            tag = kEllipseMenuCopyLinkButtonTag;
        }
        else if ([imageName isEqualToString:kLinkedInBlockButtonImageName])
        {
            tag = kEllipseMenuBlockButtonTag;
        }
        else if ([imageName isEqualToString:kLinkedInReadLaterButtonImageName])
        {
            tag = kEllipseMenuReadLaterButtonTag;
        }
        else if ([imageName isEqualToString:kLinkedInSaveImageButtonImageName])
        {
            tag = kEllipseMenuSaveImageButtonTag;
        }
    }
    
    return tag;
}

@end
