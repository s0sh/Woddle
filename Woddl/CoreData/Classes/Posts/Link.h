//
//  Link.h
//  Woddl
//
//  Created by Oleg Komaristov on 05.03.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Post;

@interface Link : NSManagedObject

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) Post *post;

@end
