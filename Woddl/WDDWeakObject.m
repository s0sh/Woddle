//
//  WDDWeakObject.m
//  Woddl
//
//  Created by Oleg Komaristov on 11/30/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDWeakObject.h"

@interface WDDWeakObject ()

@property (nonatomic, weak) id originalObject;

@end

@implementation WDDWeakObject

+ (instancetype)weekObjectWithObject:(id)object
{
    WDDWeakObject *weekObject = [[WDDWeakObject alloc] init];
    weekObject.originalObject = object;
    
    return weekObject;
}

- (BOOL)isEqual:(id)object
{
    return ([object isKindOfClass:[WDDWeakObject class]] && [[object object] isEqual:self.object]);
}

- (id)object
{
    return self.originalObject;
}

@end
