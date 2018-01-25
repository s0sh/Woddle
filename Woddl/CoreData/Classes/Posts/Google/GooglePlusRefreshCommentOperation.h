//
//  GooglePlusRefreshCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 09.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol GooglePlusRefreshCommentOperationDelegate;
@interface GooglePlusRefreshCommentOperation : NSOperation
{
    id <GooglePlusRefreshCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* userID;

-(id)initGooglePlusRefreshCommentsWithToken:(NSString*)token_ andPostID:(NSString*)postID withDelegate:(id)delegate_;

@end

@protocol GooglePlusRefreshCommentOperationDelegate<NSObject>
-(void)googlePlusRefreshCommentDidFinishWithComments:(NSArray*)comments;
@end
