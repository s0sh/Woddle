//
//  GooglePlusRefreshCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 09.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FoursquareRefreshCommentOperationDelegate;
@interface FoursquareRefreshCommentOperation : NSOperation
{
    id <FoursquareRefreshCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* userID;

-(id)initFoursquareRefreshCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID withDelegate:(id)delegate_;

@end

@protocol FoursquareRefreshCommentOperationDelegate<NSObject>
-(void)foursquareRefreshCommentDidFinishWithComments:(NSArray*)comments;
@end
