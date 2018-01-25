//
//  WDDEllipseMenuFactory.h
//  Woddl
//
//  Created by Sergii Gordiienko on 15.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDConstants.h"

#import "IDSEllipseMenu.h"
#import "WDDTwitterEllipseMenu.h"
#import "WDDFacebookEllipseMenu.h"
#import "WDDGooglePlusEllipseMenu.h"
#import "WDDInstagramEllipseMenu.h"
#import "WDDLinkedInEllipseMenu.h"
#import "WDDFoursquareEllipseMenu.h"

@interface WDDEllipseMenuFactory : IDSEllipseMenu

+ (IDSEllipseMenu *)ellipseMenuForSocialNetworkType:(SocialNetworkType)type inRect:(CGRect)rect;

@end
