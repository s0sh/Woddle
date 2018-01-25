//
//  FacebookCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 18.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FacebookCommentOperationDelegate;
@interface FacebookCommentOperation : NSOperation
{
    id <FacebookCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* userID;

-(id)initFacebookCommentOperationWithMesage:(NSString*)message_ Token:(NSString*)token_ andPostID:(NSString*)postID andUserID:(NSString*)userID withDelegate:(id)delegate_;
@end

@protocol FacebookCommentOperationDelegate<NSObject>
-(void)facebookCommentDidFinishWithDictionary:(NSDictionary *)comment;
-(void)facebookCommentDidFinishWithFail;
@end
