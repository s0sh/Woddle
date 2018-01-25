//
//  Link+Additions.h
//  Woddl
//
//  Created by Oleg Komaristov on 03.07.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "Link.h"

@interface Link (Additions)

- (BOOL)isShortLink;
+ (BOOL)isURLShort:(NSURL *)url;
+ (BOOL)isURLStringShort:(NSString *)url;

@end
