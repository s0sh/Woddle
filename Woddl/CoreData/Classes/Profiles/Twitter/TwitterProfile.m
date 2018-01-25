//
//  TwitterProfile.m
//  Woddl
//
//  Created by Sergii Gordiienko on 28.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "TwitterProfile.h"
#import "TwitterOthersProfile.h"


@implementation TwitterProfile

@dynamic following;

- (NSString *)socialNetworkIconName
{
    return kTwitterIconImageName;
}

@end
