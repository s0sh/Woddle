//
//  NSManagedObject+setValuesFromDataDictionary.h
//
//  Created by Oleg Komaristov on 01/04/14.
//  Copyright (c) 2011 Atomic Bird, LLC. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface NSManagedObject (setValuesFromDataDictionary)

- (void)setValuesFromDataDictionary:(NSDictionary *)dictionary;

@end
