//
//  FacebookLikeOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 14.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FacebookLikeOperationDelegate;
@interface FacebookLikeOperation : NSOperation
{
    id <FacebookLikeOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* myID;

-(id)initFacebookLikeOperationWithToken:(NSString*)token andPostID:(NSString*)postID andMyID:(NSString*)myID withDelegate:(id)delegate_;
@end

@protocol FacebookLikeOperationDelegate<NSObject>
-(void)facebookLikeDidFinishWithSuccess;
-(void)facebookLikeDidFinishWithFail;
-(void)facebookUnlikeDidFinishWithSuccess;
-(void)facebookUnlikeDidFinishWithFail;
@end
