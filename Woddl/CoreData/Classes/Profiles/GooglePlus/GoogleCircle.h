//
//  GoogleCircle.h
//  Woddl
//
//  Created by Sergii Gordiienko on 28.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GooglePlusProfile;

@interface GoogleCircle : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *people;
@end

@interface GoogleCircle (CoreDataGeneratedAccessors)

- (void)addPeopleObject:(GooglePlusProfile *)value;
- (void)removePeopleObject:(GooglePlusProfile *)value;
- (void)addPeople:(NSSet *)values;
- (void)removePeople:(NSSet *)values;

@end
