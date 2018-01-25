//
//  TwitterRefreshCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 03.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol TwitterRefreshCommentOperationDelegate;
@interface TwitterRefreshCommentOperation : NSOperation
{
    id <TwitterRefreshCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* userID;
@property (nonatomic, strong) NSString* userName;
@property (nonatomic, strong) NSString* sinceID;

-(id)initTwitterRefreshCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID userName:(NSString*)userName sinceID:(NSString*)sinceID withDelegate:(id)delegate_;

@end

@protocol TwitterRefreshCommentOperationDelegate<NSObject>
-(void)twitterRefreshCommentDidFinishWithComments:(NSArray*)comments;
@end
