//
//  FoursqaureProfile.h
//  Woddl
//
//  Created by Sergii Gordiienko on 05.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "UserProfile.h"

@class FoursquareOthersProfile;

@interface FoursqaureProfile : UserProfile

@property (nonatomic, retain) NSSet *friends;

@end

@interface FoursqaureProfile (CoreDataGeneratedAccessors)

- (void)addFriendsObject:(FoursquareOthersProfile *)value;
- (void)removeFriendsObject:(FoursquareOthersProfile *)value;
- (void)addFriends:(NSSet *)values;
- (void)removeFriends:(NSSet *)values;

@end
