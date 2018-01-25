//
//  Comment.h
//  Woddl
//
//  Created by Sergii Gordiienko on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class UserProfile;
@class Post;

@interface Comment : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * commentID;
@property (nonatomic, retain) UserProfile *author;
@property (nonatomic, retain) NSSet *tags;
@property (nonatomic, retain) Post *post;
@property (nonatomic, retain) NSSet *likedBy;
@property (nonatomic, retain) NSNumber *likesCount;
@property (nonatomic, retain) NSNumber *isLinksProcessed;

@end

@interface Comment (CoreDataGeneratedAccessors)

- (void)addTagsObject:(NSManagedObject *)value;
- (void)removeTagsObject:(NSManagedObject *)value;
- (void)addTags:(NSSet *)values;
- (void)removeTags:(NSSet *)values;

- (void)addLikedByObject:(UserProfile *)value;
- (void)removeLikedByObject:(UserProfile *)value;
- (void)addLikedBy:(NSSet *)values;
- (void)removeLikedBy:(NSSet *)values;

@end
