//
//  LinkedinOthersProfile.h
//  Woddl
//
//  Created by Александр Бородулин on 25.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "LinkedinProfile.h"
#import "LinkedinPost.h"

@class LinkedinPost, LinkedinProfile;

@interface LinkedinOthersProfile : LinkedinProfile

@property (nonatomic, retain) NSNumber * blocked;
@property (nonatomic, retain) NSSet *friendOf;
@property (nonatomic, retain) NSSet *likedPost;
@end

@interface LinkedinOthersProfile (CoreDataGeneratedAccessors)

- (void)addFriendOfObject:(LinkedinProfile *)value;
- (void)removeFriendOfObject:(LinkedinProfile *)value;
- (void)addFriendOf:(NSSet *)values;
- (void)removeFriendOf:(NSSet *)values;

- (void)addLikedPostObject:(LinkedinPost *)value;
- (void)removeLikedPostObject:(LinkedinPost *)value;
- (void)addLikedPost:(NSSet *)values;
- (void)removeLikedPost:(NSSet *)values;

@end
