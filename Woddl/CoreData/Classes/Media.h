//
//  Media.h
//  Woddl
//
//  Created by Sergii Gordiienko on 03.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(NSInteger, MediaType)
{
    kMediaUnknown = 0,
    kMediaPhoto,
    kMediaVideo
};

@class Post, Notification;

@interface Media : NSManagedObject

@property (nonatomic, retain) NSString * mediaObjectId;
@property (nonatomic, retain) NSString * mediaURLString;
@property (nonatomic, retain) NSString * previewURLString;
@property (nonatomic, retain) NSNumber * type;
@property (nonatomic, retain) NSSet *post;
@property (nonatomic, retain) NSSet *notifications;
@end

@interface Media (CoreDataGeneratedAccessors)

- (void)addPostObject:(Post *)value;
- (void)removePostObject:(Post *)value;
- (void)addPost:(NSSet *)values;
- (void)removePost:(NSSet *)values;

- (void)addNotificationsObject:(Notification *)value;
- (void)removeNotificationsObject:(Notification *)value;
- (void)addNotifications:(NSSet *)values;
- (void)removeNotifications:(NSSet *)values;

@end
