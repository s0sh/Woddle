//
//  TwitterLikeOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 15.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol TwitterLikeOperationDelegate;
@interface TwitterLikeOperation : NSOperation
{
    id <TwitterLikeOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* myID;

-(id)initTwitterLikeOperationWithToken:(NSString*)token andPostID:(NSString*)postID andMyID:(NSString*)myID withDelegate:(id)delegate_;
@end

@protocol TwitterLikeOperationDelegate<NSObject>
-(void)twitterLikeDidFinishWithSuccess;
-(void)twitterLikeDidFinishWithFail;
-(void)twitterUnlikeDidFinishWithSuccess;
-(void)twitterUnlikeDidFinishWithFail;
@end
