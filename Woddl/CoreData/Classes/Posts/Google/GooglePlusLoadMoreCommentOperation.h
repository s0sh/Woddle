//
//  GooglePlusLoadMoreCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 09.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol GooglePlusLoadMoreCommentOperationDelegate;
@interface GooglePlusLoadMoreCommentOperation : NSOperation
{
    id <GooglePlusLoadMoreCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* userID;
@property (nonatomic, assign) NSUInteger count;

-(id)initGooglePlusLoadMoreCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID andCount:(NSUInteger)count withDelegate:(id)delegate_;

@end

@protocol GooglePlusLoadMoreCommentOperationDelegate<NSObject>
-(void)googlePlusLoadMoreCommentDidFinishWithComments:(NSArray*)comments;
@end
