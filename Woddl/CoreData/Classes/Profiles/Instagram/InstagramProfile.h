//
//  InstagramProfile.h
//  Woddl
//
//  Created by Sergii Gordiienko on 05.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "UserProfile.h"

@class InstagramOthersProfile;

@interface InstagramProfile : UserProfile

@property (nonatomic, retain) NSSet *friends;

@end

@interface InstagramProfile (CoreDataGeneratedAccessors)

- (void)addFriendsObject:(InstagramOthersProfile *)value;
- (void)removeFriendsObject:(InstagramOthersProfile *)value;
- (void)addFriends:(NSSet *)values;
- (void)removeFriends:(NSSet *)values;

@end
