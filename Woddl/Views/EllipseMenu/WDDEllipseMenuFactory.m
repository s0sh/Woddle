//
//  WDDEllipseMenuFactory.m
//  Woddl
//
//  Created by Sergii Gordiienko on 15.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDEllipseMenuFactory.h"

@implementation WDDEllipseMenuFactory

+ (IDSEllipseMenu *)ellipseMenuForSocialNetworkType:(SocialNetworkType)type inRect:(CGRect)rect
{
    IDSEllipseMenu * ellipseMenu = [[IDSEllipseMenu alloc] initWithFrame:rect];
    
    switch (type) {
        case kSocialNetworkFacebook:
            ellipseMenu = [[WDDFacebookEllipseMenu alloc] initWithFrame:rect];
            break;
        case kSocialNetworkTwitter:
            ellipseMenu = [[WDDTwitterEllipseMenu alloc] initWithFrame:rect];
            break;
        case kSocialNetworkGooglePlus:
            ellipseMenu = [[WDDGooglePlusEllipseMenu alloc] initWithFrame:rect];
            break;
        case kSocialNetworkInstagram:
            ellipseMenu = [[WDDInstagramEllipseMenu alloc] initWithFrame:rect];
            break;
        case kSocialNetworkLinkedIN:
            ellipseMenu = [[WDDLinkedInEllipseMenu alloc] initWithFrame:rect];
            break;
        case kSocialNetworkFoursquare:
            ellipseMenu = [[WDDFoursquareEllipseMenu alloc] initWithFrame:rect];
            break;
            
        case kSocialNetworkUnknown:
            ellipseMenu = nil;
            break;
    }
    
    return ellipseMenu;
}


@end
