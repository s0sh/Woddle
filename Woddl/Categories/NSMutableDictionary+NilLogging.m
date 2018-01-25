//
//  NSMutableDictionary+NilLogging.m
//  Woddl
//
//  Created by Oleg Komaristov on 20.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "NSMutableDictionary+NilLogging.h"
#import <objc/runtime.h>

@implementation NSMutableDictionary (NilLogging)

- (void)s_setObject:(id)object forKey:(id)key
{
    if ([object isKindOfClass:[NSNull class]])
    {
        NSLog(@"Try to insert NSNull value for key: %@", key);
    }
    else if (nil == object)
    {
        NSLog(@"Try to insert nil value for key: %@", key);
    }
    else
    {
        [self setObject:object forKey:key];
    }
}


@end
