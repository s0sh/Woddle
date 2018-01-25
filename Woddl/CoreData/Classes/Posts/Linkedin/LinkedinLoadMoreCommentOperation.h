//
//  LinkedinLoadMoreCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 09.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol LinkedinLoadMoreCommentOperationDelegate;
@interface LinkedinLoadMoreCommentOperation : NSOperation
{
    id <LinkedinLoadMoreCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* userID;
@property (nonatomic, assign) NSInteger from;
@property (nonatomic, assign) NSInteger to;
@property (nonatomic, assign) BOOL isGroupPost;

-(id)initLinkedinLoadMoreCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID from:(NSInteger)from to:(NSInteger)to isGroupPost:(BOOL)isGroupPost withDelegate:(id)delegate_;

@end

@protocol LinkedinLoadMoreCommentOperationDelegate<NSObject>
-(void)linkedinLoadMoreCommentDidFinishWithComments:(NSArray*)comments;
@end
