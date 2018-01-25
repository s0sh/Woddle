//
//  Link+Additions.m
//  Woddl
//
//  Created by Oleg Komaristov on 03.07.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "Link+Additions.h"

@implementation Link (Additions)

- (BOOL)isShortLink
{
    return [Link isURLStringShort:self.url];
}

+ (BOOL)isURLShort:(NSURL *)url
{
    return [self isURLStringShort:url.absoluteString];
}

+ (BOOL)isURLStringShort:(NSString *)url
{
    BOOL isTwitterLink = ([url rangeOfString:@"t.co/"].location != NSNotFound);
    BOOL isWoddlLink = ([url rangeOfString:@"woddl.it/"].location != NSNotFound);
    BOOL isBitly = ([url rangeOfString:@"bit.ly/"].location != NSNotFound);
    
    return isTwitterLink || isWoddlLink || isBitly;
}

@end
