//
//  FacebookLoadMoreCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 10.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FacebookLoadMoreCommentOperationDelegate;
@interface FacebookLoadMoreCommentOperation : NSOperation
{
    id <FacebookLoadMoreCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* userID;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, assign) NSUInteger offset;

-(id)initFacebookLoadMoreCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID andCount:(NSUInteger)count offset:(NSUInteger)offset withDelegate:(id)delegate_;

@end

@protocol FacebookLoadMoreCommentOperationDelegate<NSObject>
-(void)facebookLoadMoreCommentDidFinishWithComments:(NSArray*)comments;
@end
