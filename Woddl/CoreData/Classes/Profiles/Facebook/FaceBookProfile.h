//
//  FaceBookProfile.h
//  Woddl
//
//  Created by Sergii Gordiienko on 28.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "UserProfile.h"

@class FaceBookOthersProfile;

@interface FaceBookProfile : UserProfile

@property (nonatomic, retain) NSSet *friends;
@end

@interface FaceBookProfile (CoreDataGeneratedAccessors)

- (void)addFriendsObject:(FaceBookOthersProfile *)value;
- (void)removeFriendsObject:(FaceBookOthersProfile *)value;
- (void)addFriends:(NSSet *)values;
- (void)removeFriends:(NSSet *)values;

@end
