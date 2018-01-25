//
//  InstagramOthersProfile.h
//  Woddl
//
//  Created by Александр Бородулин on 25.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "InstagramProfile.h"

@class InstagramPost, InstagramProfile;

@interface InstagramOthersProfile : InstagramProfile

@property (nonatomic, retain) NSNumber * blocked;
@property (nonatomic, retain) NSSet *friendOf;
@property (nonatomic, retain) NSSet *likedPost;
@end

@interface InstagramOthersProfile (CoreDataGeneratedAccessors)

- (void)addFriendOfObject:(InstagramProfile *)value;
- (void)removeFriendOfObject:(InstagramProfile *)value;
- (void)addFriendOf:(NSSet *)values;
- (void)removeFriendOf:(NSSet *)values;

- (void)addLikedPostObject:(InstagramPost *)value;
- (void)removeLikedPostObject:(InstagramPost *)value;
- (void)addLikedPost:(NSSet *)values;
- (void)removeLikedPost:(NSSet *)values;

@end
