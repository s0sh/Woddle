//
//  WDDWeakObject.h
//  Woddl
//
//  Created by Oleg Komaristov on 11/30/13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WDDWeakObject : NSObject

@property (nonatomic, readonly) id object;

+ (instancetype)weekObjectWithObject:(id)object;

@end
