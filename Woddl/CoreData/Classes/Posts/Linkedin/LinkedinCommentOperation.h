//
//  LinkedinCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 26.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol LinkedinCommentOperationDelegate;
@interface LinkedinCommentOperation : NSOperation
{
    id <LinkedinCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* userID;
@property (nonatomic, assign) BOOL isGroupPost;

-(id)initLinkedinCommentOperationWithMesage:(NSString*)message_ andToken:(NSString*)token_ andPostID:(NSString*)postID andUserID:(NSString*)userID_ isGroupPost:(BOOL)isGroupPost withDelegate:(id)delegate_;
@end

@protocol LinkedinCommentOperationDelegate<NSObject>
-(void)linkedinCommentDidFinishWithDictionary:(NSDictionary*)comment;
-(void)linkedinCommentDidFinishWithFail:(NSDictionary*)failInfo;
@end
