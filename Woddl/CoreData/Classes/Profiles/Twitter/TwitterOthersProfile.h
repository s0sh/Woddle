//
//  TwitterOthersProfile.h
//  Pods
//
//  Created by Sergii Gordiienko on 02.12.13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TwitterProfile.h"

@class TwitterPost, TwitterProfile;

@interface TwitterOthersProfile : TwitterProfile

@property (nonatomic, retain) NSSet *friendOf;
@property (nonatomic, retain) NSSet *retweetedFromMePosts;
@end

@interface TwitterOthersProfile (CoreDataGeneratedAccessors)

- (void)addFriendOfObject:(TwitterProfile *)value;
- (void)removeFriendOfObject:(TwitterProfile *)value;
- (void)addFriendOf:(NSSet *)values;
- (void)removeFriendOf:(NSSet *)values;

- (void)addRetweetedFromMePostsObject:(TwitterPost *)value;
- (void)removeRetweetedFromMePostsObject:(TwitterPost *)value;
- (void)addRetweetedFromMePosts:(NSSet *)values;
- (void)removeRetweetedFromMePosts:(NSSet *)values;

@end
