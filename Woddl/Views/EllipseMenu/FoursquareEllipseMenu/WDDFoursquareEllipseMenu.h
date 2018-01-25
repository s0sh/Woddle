//
//  WDDFoursquareEllipseMenu.h
//  Woddl
//
//  Created by Sergii Gordiienko on 15.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "IDSEllipseMenu.h"

@interface WDDFoursquareEllipseMenu : IDSEllipseMenu

typedef NS_ENUM(NSInteger, FoursquareEllipseMenuButtonTags)
{
    kFoursquareLikeButtonTag          = 6000,
    kFoursquareCommentButtonTag       = 6001,
    kFoursquareShareButtonTag         = 6002,
    kFoursquareMailPostButtonTag      = 6003,
    kFoursquareCopyLinkButtonTag      = 6004
};

@end
