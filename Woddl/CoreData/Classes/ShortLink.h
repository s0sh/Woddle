//
//  ShortLink.h
//  Woddl
//
//  Created by Oleg Komaristov on 2/19/14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ShortLink : NSManagedObject

@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSNumber * fullURLHash;
@property (nonatomic, retain) NSString * fullURL;

@end
