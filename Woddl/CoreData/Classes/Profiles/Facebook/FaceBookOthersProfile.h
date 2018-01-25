//
//  FaceBookOthersProfile.h
//  Woddl
//
//  Created by Sergii Gordiienko on 28.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "FaceBookProfile.h"

@class FaceBookPost, FaceBookProfile;

@interface FaceBookOthersProfile : FaceBookProfile

@property (nonatomic, retain) NSNumber * blocked;
@property (nonatomic, retain) NSSet *friendOf;
@property (nonatomic, retain) NSSet *likedPosts;
@end

@interface FaceBookOthersProfile (CoreDataGeneratedAccessors)

- (void)addFriendOfObject:(FaceBookProfile *)value;
- (void)removeFriendOfObject:(FaceBookProfile *)value;
- (void)addFriendOf:(NSSet *)values;
- (void)removeFriendOf:(NSSet *)values;

- (void)addLikedPostsObject:(FaceBookPost *)value;
- (void)removeLikedPostsObject:(FaceBookPost *)value;
- (void)addLikedPosts:(NSSet *)values;
- (void)removeLikedPosts:(NSSet *)values;

@end
