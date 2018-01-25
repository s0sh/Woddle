//
//  TwitterLoadMoreCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 03.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol TwitterLoadMoreCommentOperationDelegate;
@interface TwitterLoadMoreCommentOperation : NSOperation
{
    id <TwitterLoadMoreCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* userID;
@property (nonatomic, strong) NSString* userName;
@property (nonatomic, strong) NSString* from;
@property (nonatomic, assign) NSInteger to;

-(id)initTwitterLoadMoreCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID andUserName:(NSString*)userName from:(NSString*)from to:(NSInteger)to withDelegate:(id)delegate_;

@end

@protocol TwitterLoadMoreCommentOperationDelegate<NSObject>
-(void)twitterLoadMoreCommentDidFinishWithComments:(NSArray*)comments;
@end
