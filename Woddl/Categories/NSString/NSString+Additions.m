//
//  NSString+Additions.m
//  Woddl
//
//  Created by Sergii Gordiienko on 06.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "NSString+Additions.h"

@implementation NSString (Additions)

- (BOOL)isEndsWithNewlineCharacter
{
    NSUInteger stringLength = [self length];
    if (stringLength == 0)
    {
        return NO;
    }
    unichar lastChar = [self characterAtIndex:stringLength-1];
    return [[NSCharacterSet newlineCharacterSet] characterIsMember:lastChar];
}
@end
