//
//  NSManagedObject+setValuesFromDataDictionary.m
//
//  Created by Oleg Komaristov on 01/04/14.
//  Copyright (c) 2011 Atomic Bird, LLC. All rights reserved.
//


#import "NSManagedObject+setValuesFromDataDictionary.h"

@implementation NSManagedObject (setValuesFromDataDictionary)

- (void)setValuesFromDataDictionary:(NSDictionary *)dictionary
{
    for (NSString *key in [[[self entity] attributesByName] allKeys])
    {
        NSString *value = [dictionary valueForKey:key];
        if (value)
        {
            [self setValue:value forKey:key];
        }
    }
}

@end
