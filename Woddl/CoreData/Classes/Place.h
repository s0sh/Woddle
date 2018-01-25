//
//  Place.h
//  Woddl
//
//  Created by Oleg Komaristov on 1/5/14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Post;

@interface Place : NSManagedObject

@property (nonatomic, retain) NSString * placeId;
@property (nonatomic, retain) NSNumber * networkType;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSNumber * checkinsCount;
@property (nonatomic, retain) NSNumber * verified;
@property (nonatomic, retain) NSString * countryCode;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) Post *posts;

@end
