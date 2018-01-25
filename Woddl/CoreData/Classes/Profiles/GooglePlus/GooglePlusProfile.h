//
//  GooglePlusProfile.h
//  Woddl
//
//  Created by Oleg Komaristov on 05.02.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "UserProfile.h"

@class GoogleCircle, GoogleOthersProfile;

@interface GooglePlusProfile : UserProfile

@property (nonatomic, retain) NSString * pageId;
@property (nonatomic, retain) NSSet *circles;
@property (nonatomic, retain) NSSet *friends;
@end

@interface GooglePlusProfile (CoreDataGeneratedAccessors)

- (void)addCirclesObject:(GoogleCircle *)value;
- (void)removeCirclesObject:(GoogleCircle *)value;
- (void)addCircles:(NSSet *)values;
- (void)removeCircles:(NSSet *)values;

- (void)addFriendsObject:(GoogleOthersProfile *)value;
- (void)removeFriendsObject:(GoogleOthersProfile *)value;
- (void)addFriends:(NSSet *)values;
- (void)removeFriends:(NSSet *)values;

@end
