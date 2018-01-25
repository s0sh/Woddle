//
//  TwitterGetPostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 13.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol TwitterGetPostOperationDelegate;
@interface TwitterGetPostOperation : NSOperation
{
    id <TwitterGetPostOperationDelegate> delegate;
    NSUInteger count;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* userID;

-(id)initTwitterGetPostOperationWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count withDelegate:(id)delegate_;

@end

@protocol TwitterGetPostOperationDelegate<NSObject>
-(void)twitterGetPostDidFinishWithPosts:(NSArray*)posts;
@end
