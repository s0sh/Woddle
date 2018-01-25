//
//  NSLocale+Hack.m
//  Woddl
//
//  Created by Petro Korienev on 5/26/14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "NSLocale+Hack.h"

@implementation NSLocale (Hack)

+ (NSArray*)preferredLanguages
{
    return [[NSBundle mainBundle] preferredLocalizations];
}

@end
