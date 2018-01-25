//
//  LinkedinLikeOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 15.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol LinkedinLikeOperationDelegate;
@interface LinkedinLikeOperation : NSOperation
{
    id <LinkedinLikeOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* myID;
@property (nonatomic, assign) BOOL isGroupPost;

-(id)initLinkedinLikeOperationWithToken:(NSString*)token andPostID:(NSString*)postID andMyID:(NSString*)myID isGroupPost:(BOOL)isGroupPost withDelegate:(id)delegate_;
@end

@protocol LinkedinLikeOperationDelegate<NSObject>
-(void)linkedinLikeDidFinishWithSuccess;
-(void)linkedinLikeDidFinishWithFail;
-(void)linkedinUnlikeDidFinishWithSuccess;
-(void)linkedinUnlikeDidFinishWithFail;
-(void)linkedinLikingError:(NSDictionary*)error;
@end
