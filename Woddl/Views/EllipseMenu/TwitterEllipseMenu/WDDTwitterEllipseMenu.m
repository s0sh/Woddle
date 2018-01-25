//
//  WDDTwitterEllipseMenu.m
//  Woddl
//
//  Created by Sergii Gordiienko on 15.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDTwitterEllipseMenu.h"

@implementation WDDTwitterEllipseMenu


- (NSArray *)leftSideButtonsImageNames
{
    NSMutableArray *images = [@[kTwitterFavoriteButtonImageName,
                                kTwitterRetweetButtonImageName,
                                kTwitterReplyButtonImageName,
                                kTwitterBlockButtonImageName,
                                kTwitterMailButtonImageName,
                                kTwitterCopyLinkButtonImageName,
                                kTwitterReadLaterButtonImageName] mutableCopy];
    
    if (self.isSaveImageAvailable)
    {
        [images addObject:kTwitterSaveImageButtonImageName];
    }
    
    return images;
}

- (NSInteger)tagForImageName:(NSString *)imageName
{
    NSInteger tag = [super tagForImageName:imageName];
    if (!tag)
    {
        if ([imageName isEqualToString:kTwitterFavoriteButtonImageName])
        {
            tag = kEllipseMenuLikeButtonTag;
        }
        else if ([imageName isEqualToString:kTwitterRetweetButtonImageName])
        {
            tag = kEllipseMenuTwitterRetweetButtonTag;
        }
        else if ([imageName isEqualToString:kTwitterQouteButtonImageName])
        {
            tag = kEllipseMenuTwitterQouteButtonTag;
        }
        else if ([imageName isEqualToString:kTwitterReplyButtonImageName])
        {
            tag = kEllipseMenuTwitterReplyButtonTag;
        }
        else if ([imageName isEqualToString:kTwitterMailButtonImageName])
        {
            tag = kEllipseMenuMailButtonTag;
        }
        else if ([imageName isEqualToString:kTwitterCopyLinkButtonImageName])
        {
            tag = kEllipseMenuCopyLinkButtonTag;
        }
        else if ([imageName isEqualToString:kTwitterBlockButtonImageName])
        {
            tag = kEllipseMenuBlockButtonTag;
        }
        else if ([imageName isEqualToString:kTwitterReadLaterButtonImageName])
        {
            tag = kEllipseMenuReadLaterButtonTag;
        }
        else if ([imageName isEqualToString:kTwitterSaveImageButtonImageName])
        {
            tag = kEllipseMenuSaveImageButtonTag;
        }
    }
    
    return tag;
}

@end
