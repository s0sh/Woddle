//
//  TwitterProfile.h
//  Woddl
//
//  Created by Sergii Gordiienko on 28.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "UserProfile.h"

@class TwitterOthersProfile;

@interface TwitterProfile : UserProfile

@property (nonatomic, retain) NSSet *following;
@end

@interface TwitterProfile (CoreDataGeneratedAccessors)

- (void)addFollowingObject:(TwitterOthersProfile *)value;
- (void)removeFollowingObject:(TwitterOthersProfile *)value;
- (void)addFollowing:(NSSet *)values;
- (void)removeFollowing:(NSSet *)values;

@end
