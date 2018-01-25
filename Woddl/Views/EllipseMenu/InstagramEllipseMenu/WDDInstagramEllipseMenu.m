//
//  WDDInstagramEllipseMenu.m
//  Woddl
//
//  Created by Sergii Gordiienko on 15.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDInstagramEllipseMenu.h"

@implementation WDDInstagramEllipseMenu

- (NSArray *)leftSideButtonsImageNames
{
    NSMutableArray *images = [@[kInstagramLikeButtonImageName,
//                                kInstagramCommentButtonImageName,
                                kInstagramBlockButtonImageName,
                                kInstagramMailButtonImageName,
                                kInstagramCopyLinkButtonImageName,
                                kInstagramReadLaterButtonImageName] mutableCopy];
    
    if (self.isSaveImageAvailable)
    {
        [images addObject:kInstagramSaveImageButtonImageName];
    }
    
    return images;
}

- (NSInteger)tagForImageName:(NSString *)imageName
{
    NSInteger tag = [super tagForImageName:imageName];
    if (!tag)
    {
        if ([imageName isEqualToString:kInstagramLikeButtonImageName])
        {
            tag = kEllipseMenuLikeButtonTag;
        }
        else if ([imageName isEqualToString:kInstagramCommentButtonImageName])
        {
            tag = kEllipseMenuCommentButtonTag;
        }
        else if ([imageName isEqualToString:kInstagramMailButtonImageName])
        {
            tag = kEllipseMenuMailButtonTag;
        }
        else if ([imageName isEqualToString:kInstagramCopyLinkButtonImageName])
        {
            tag = kEllipseMenuCopyLinkButtonTag;
        }
        else if ([imageName isEqualToString:kInstagramBlockButtonImageName])
        {
            tag = kEllipseMenuBlockButtonTag;
        }
        else if ([imageName isEqualToString:kInstagramReadLaterButtonImageName])
        {
            tag = kEllipseMenuReadLaterButtonTag;
        }
        else if ([imageName isEqualToString:kInstagramSaveImageButtonImageName])
        {
            tag = kEllipseMenuSaveImageButtonTag;
        }
    }
    
    return tag;
}

@end
