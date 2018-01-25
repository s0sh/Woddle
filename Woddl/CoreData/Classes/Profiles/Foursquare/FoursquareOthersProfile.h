//
//  FoursquareOthersProfile.h
//  Woddl
//
//  Created by Александр Бородулин on 25.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FoursqaureProfile.h"

@class FoursqaureProfile, FoursquarePost;

@interface FoursquareOthersProfile : FoursqaureProfile

@property (nonatomic, retain) NSNumber * blocked;
@property (nonatomic, retain) NSSet *friendOf;
@property (nonatomic, retain) NSSet *likedPost;
@end

@interface FoursquareOthersProfile (CoreDataGeneratedAccessors)

- (void)addFriendOfObject:(FoursqaureProfile *)value;
- (void)removeFriendOfObject:(FoursqaureProfile *)value;
- (void)addFriendOf:(NSSet *)values;
- (void)removeFriendOf:(NSSet *)values;

- (void)addLikedPostObject:(FoursquarePost *)value;
- (void)removeLikedPostObject:(FoursquarePost *)value;
- (void)addLikedPost:(NSSet *)values;
- (void)removeLikedPost:(NSSet *)values;

@end
