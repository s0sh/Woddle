//
//  GoogleOthersProfile.h
//  Woddl
//
//  Created by Sergii Gordiienko on 28.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "GooglePlusProfile.h"

@class GooglePlusPost, GooglePlusProfile;

@interface GoogleOthersProfile : GooglePlusProfile

@property (nonatomic, retain) NSNumber * blocked;
@property (nonatomic, retain) NSSet *friendOf;
@property (nonatomic, retain) NSSet *likedPost;
@end

@interface GoogleOthersProfile (CoreDataGeneratedAccessors)

- (void)addFriendOfObject:(GooglePlusProfile *)value;
- (void)removeFriendOfObject:(GooglePlusProfile *)value;
- (void)addFriendOf:(NSSet *)values;
- (void)removeFriendOf:(NSSet *)values;

- (void)addLikedPostObject:(GooglePlusPost *)value;
- (void)removeLikedPostObject:(GooglePlusPost *)value;
- (void)addLikedPost:(NSSet *)values;
- (void)removeLikedPost:(NSSet *)values;

@end
