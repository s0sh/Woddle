//
//  WDDGooglePlusEllipseMenu.m
//  Woddl
//
//  Created by Sergii Gordiienko on 15.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDGooglePlusEllipseMenu.h"

@implementation WDDGooglePlusEllipseMenu


- (NSArray *)leftSideButtonsImageNames
{
    NSMutableArray *images = [@[/*kGooglePlusLikeButtonImageName,
                                 kGooglePlusCommentButtonImageName,
                                 kGooglePlusShareButtonImageName,*/
                                kGooglePlusBlockButtonImageName,
                                kGooglePlusMailButtonImageName,
                                kGooglePlusCopyLinkButtonImageName,
                                kGooglePlusReadLaterButtonImageName] mutableCopy];
    
    if (self.isSaveImageAvailable)
    {
        [images addObject:kGooglePlusSaveImageButtonImageName];
    }
    
    return images;
}

- (NSInteger)tagForImageName:(NSString *)imageName
{
    NSInteger tag = [super tagForImageName:imageName];
    if (!tag)
    {
        if ([imageName isEqualToString:kGooglePlusLikeButtonImageName])
        {
            tag = kEllipseMenuLikeButtonTag;
        }
        else if ([imageName isEqualToString:kGooglePlusCommentButtonImageName])
        {
            tag = kEllipseMenuCommentButtonTag;
        }
        else if ([imageName isEqualToString:kGooglePlusShareButtonImageName])
        {
            tag = kEllipseMenuShareButtonTag;
        }
        else if ([imageName isEqualToString:kGooglePlusMailButtonImageName])
        {
            tag = kEllipseMenuMailButtonTag;
        }
        else if ([imageName isEqualToString:kGooglePlusCopyLinkButtonImageName])
        {
            tag = kEllipseMenuCopyLinkButtonTag;
        }
        else if ([imageName isEqualToString:kGooglePlusBlockButtonImageName])
        {
            tag = kEllipseMenuBlockButtonTag;
        }
        else if ([imageName isEqualToString:kGooglePlusReadLaterButtonImageName])
        {
            tag = kEllipseMenuReadLaterButtonTag;
        }
        else if ([imageName isEqualToString:kGooglePlusSaveImageButtonImageName])
        {
            tag = kEllipseMenuSaveImageButtonTag;
        }
    }
    
    return tag;
}

@end
