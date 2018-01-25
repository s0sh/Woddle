//
//  WDDFoursquareEllipseMenu.m
//  Woddl
//
//  Created by Sergii Gordiienko on 15.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDFoursquareEllipseMenu.h"

@implementation WDDFoursquareEllipseMenu

- (NSArray *)leftSideButtonsImageNames
{
    NSMutableArray *images = [@[kFoursquareLikeButtonImageName,
                                kFoursquareCommentButtonImageName,
                                kFoursquareBlockButtonImageName,
                                kFoursquareMailButtonImageName,
                                kFoursquareReadLaterButtonImageName] mutableCopy];
    
    if (self.isSaveImageAvailable)
    {
        [images addObject:kFoursquareSaveImageButtonImageName];
    }
    
    return images;
}

- (NSInteger)tagForImageName:(NSString *)imageName
{
    NSInteger tag = [super tagForImageName:imageName];
    if (!tag)
    {
        if ([imageName isEqualToString:kFoursquareLikeButtonImageName])
        {
            tag = kEllipseMenuLikeButtonTag;
        }
        else if ([imageName isEqualToString:kFoursquareCommentButtonImageName])
        {
            tag = kEllipseMenuCommentButtonTag;
        }
        else if ([imageName isEqualToString:kFoursquareShareButtonImageName])
        {
            tag = kEllipseMenuShareButtonTag;
        }
        else if ([imageName isEqualToString:kFoursquareMailButtonImageName])
        {
            tag = kEllipseMenuMailButtonTag;
        }
        else if ([imageName isEqualToString:kFoursquareShareButtonImageName])
        {
            tag = kEllipseMenuCopyLinkButtonTag;
        }
        else if ([imageName isEqualToString:kFoursquareBlockButtonImageName])
        {
            tag = kEllipseMenuBlockButtonTag;
        }
        else if ([imageName isEqualToString:kFoursquareReadLaterButtonImageName])
        {
            tag = kEllipseMenuReadLaterButtonTag;
        }
        else if ([imageName isEqualToString:kFoursquareSaveImageButtonImageName])
        {
            tag = kEllipseMenuSaveImageButtonTag;
        }
    }
    
    return tag;
}

@end
