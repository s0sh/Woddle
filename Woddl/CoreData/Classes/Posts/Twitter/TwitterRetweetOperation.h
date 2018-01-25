//
//  TwitterRetweetOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 19.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol TwitterRetweetOperationDelegate;
@interface TwitterRetweetOperation : NSOperation
{
    id <TwitterRetweetOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;

-(id)initTwitterRetweetOperationWithToken:(NSString*)token_ andPostID:(NSString*)postID withDelegate:(id)delegate_;
@end

@protocol TwitterRetweetOperationDelegate<NSObject>
-(void)twitterRetweetDidFinishWithSuccess;
-(void)twitterRetweetDidFinishWithFail;
@end
