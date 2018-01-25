//
//  NSMutableDictionary+NilLogging.h
//  Woddl
//
//  Created by Oleg Komaristov on 20.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (NilLogging)

- (void)s_setObject:(id)object forKey:(id)key;

@end
