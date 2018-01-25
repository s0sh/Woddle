//
//  Tag.h
//  Woddl
//
//  Created by Sergii Gordiienko on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Comment, Post;

@interface Tag : NSManagedObject

@property (nonatomic, retain) NSString * tag;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *posts;
@end

@interface Tag (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(Comment *)value;
- (void)removeCommentsObject:(Comment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addPostsObject:(Post *)value;
- (void)removePostsObject:(Post *)value;
- (void)addPosts:(NSSet *)values;
- (void)removePosts:(NSSet *)values;

@end
