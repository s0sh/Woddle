//
//  FacebookRefreshCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 10.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FacebookRefreshCommentOperationDelegate;
@interface FacebookRefreshCommentOperation : NSOperation
{
    id <FacebookRefreshCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* userID;

-(id)initFacebookRefreshCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID withDelegate:(id)delegate_;

@end

@protocol FacebookRefreshCommentOperationDelegate<NSObject>
-(void)facebookRefreshCommentDidFinishWithComments:(NSArray*)comments;
@end
