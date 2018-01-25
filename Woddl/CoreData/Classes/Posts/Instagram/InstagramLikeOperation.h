//
//  InstagramLikeOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 16.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol InstagramLikeOperationDelegate;
@interface InstagramLikeOperation : NSOperation
{
    id <InstagramLikeOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* myID;

-(id)initInstagramLikeOperationWithToken:(NSString*)token andPostID:(NSString*)postID andMyID:(NSString*)myID withDelegate:(id)delegate_;
@end

@protocol InstagramLikeOperationDelegate<NSObject>
-(void)instagramLikeDidFinishWithSuccess;
-(void)instagramLikeDidFinishWithFail;
-(void)instagramUnlikeDidFinishWithSuccess;
-(void)instagramUnlikeDidFinishWithFail;
@end
