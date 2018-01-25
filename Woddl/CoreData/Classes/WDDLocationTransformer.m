//
//  WDDLocationTransformer.m
//  Woddl
//
//  Created by Sergii Gordiienko on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDLocationTransformer.h"

@implementation WDDLocationTransformer

+ (BOOL)allowsReverseTransformation {
	return YES;
}


+ (Class)transformedValueClass {
	return [NSData class];
}


- (id)transformedValue:(id)value {
    if ([value isKindOfClass:[WDDLocation class]])
    {
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:value];
        return data;
    }
	return nil;
}


- (id)reverseTransformedValue:(id)value {
    if ([value isKindOfClass:[NSData class]])
    {
        NSData *data = (NSData*)value;
        
        return [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
	return nil;
}

@end
