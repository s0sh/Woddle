//
//  LinkedinGetCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 09.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol LinkedinRefreshCommentOperationDelegate;
@interface LinkedinRefreshCommentOperation : NSOperation
{
    id <LinkedinRefreshCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* userID;
@property (nonatomic, assign) BOOL isGroupPost;

-(id)initLinkedinRefreshCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID isGroupPost:(BOOL)isGroupPost withDelegate:(id)delegate_;

@end

@protocol LinkedinRefreshCommentOperationDelegate<NSObject>
-(void)linkedinRefreshCommentDidFinishWithComments:(NSArray*)comments;
@end
