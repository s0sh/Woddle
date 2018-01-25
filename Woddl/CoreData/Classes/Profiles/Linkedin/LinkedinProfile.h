//
//  LinkedinProfile.h
//  Woddl
//
//  Created by Sergii Gordiienko on 05.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "UserProfile.h"

@class LinkedinOthersProfile;

@interface LinkedinProfile : UserProfile

@property (nonatomic, retain) NSSet *friends;

@end

@interface LinkedinProfile (CoreDataGeneratedAccessors)

- (void)addFriendsObject:(LinkedinOthersProfile *)value;
- (void)removeFriendsObject:(LinkedinOthersProfile *)value;
- (void)addFriends:(NSSet *)values;
- (void)removeFriends:(NSSet *)values;

@end