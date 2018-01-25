//
//  GooglePlusProfile.m
//  Woddl
//
//  Created by Oleg Komaristov on 05.02.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "GooglePlusProfile.h"
#import "GoogleCircle.h"
#import "GoogleOthersProfile.h"


@implementation GooglePlusProfile

@dynamic pageId;
@dynamic circles;
@dynamic friends;

- (NSString *)socialNetworkIconName
{
    return kGoogleIconImageName;
}

@end
