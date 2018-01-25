//
//  InstagramCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 26.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol InstagramCommentOperationDelegate;
@interface InstagramCommentOperation : NSOperation
{
    id <InstagramCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* userID;

-(id)initInstagramCommentOperationWithMesage:(NSString*)message_ andToken:(NSString*)token_ andPostID:(NSString*)postID withDelegate:(id)delegate_;
@end

@protocol InstagramCommentOperationDelegate<NSObject>
-(void)instagramCommentDidFinishWithCommentID:(NSString*)commentID;
-(void)instagramCommentDidFinishWithFail;
@end
