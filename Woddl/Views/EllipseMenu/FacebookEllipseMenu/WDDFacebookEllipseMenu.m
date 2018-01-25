//
//  WDDFacebookEllipseMenu.m
//  Woddl
//
//  Created by Sergii Gordiienko on 15.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDFacebookEllipseMenu.h"

@implementation WDDFacebookEllipseMenu

- (NSArray *)leftSideButtonsImageNames
{
    NSMutableArray *images = [@[kFacebookLikeButtonImageName,
                                kFacebookCommentButtonImageName,
                                kFacebookShareButtonImageName,
                                kFacebookBlockButtonImageName,
                                kFacebookMailButtonImageName,
                                kFacebookCopyLinkButtonImageName,
                                kFacebookReadLaterButtonImageName] mutableCopy];
    
    if (self.isSaveImageAvailable)
    {
        [images addObject:kFacebookSaveImageButtonImageName];
    }
    
    return images;
}

- (NSInteger)tagForImageName:(NSString *)imageName
{
    NSInteger tag = [super tagForImageName:imageName];
    if (!tag)
    {
        if ([imageName isEqualToString:kFacebookLikeButtonImageName])
        {
            tag = kEllipseMenuLikeButtonTag;
        }
        else if ([imageName isEqualToString:kFacebookCommentButtonImageName])
        {
            tag = kEllipseMenuCommentButtonTag;
        }
        else if ([imageName isEqualToString:kFacebookShareButtonImageName])
        {
            tag = kEllipseMenuShareButtonTag;
        }
        else if ([imageName isEqualToString:kFacebookMailButtonImageName])
        {
            tag = kEllipseMenuMailButtonTag;
        }
        else if ([imageName isEqualToString:kFacebookCopyLinkButtonImageName])
        {
            tag = kEllipseMenuCopyLinkButtonTag;
        }
        else if ([imageName isEqualToString:kFacebookBlockButtonImageName])
        {
            tag = kEllipseMenuBlockButtonTag;
        }
        else if ([imageName isEqualToString:kFacebookReadLaterButtonImageName])
        {
            tag = kEllipseMenuReadLaterButtonTag;
        }
        else if ([imageName isEqualToString:kFacebookSaveImageButtonImageName])
        {
            tag = kEllipseMenuSaveImageButtonTag;
        }
    }
    
    return tag;
}

@end
