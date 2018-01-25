//
//  TwitterCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 03.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol TwitterCommentOperationDelegate;
@interface TwitterCommentOperation : NSOperation
{
    id <TwitterCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* userID;

-(id)initTwitterCommentOperationWithMesage:(NSString*)message_ Token:(NSString*)token_ andPostID:(NSString*)postID andUserID:(NSString*)userID withDelegate:(id)delegate_;
@end

@protocol TwitterCommentOperationDelegate<NSObject>
-(void)twitterCommentDidFinishWithDictionary:(NSDictionary *)comment;
-(void)twitterCommentDidFinishWithFail;
@end
