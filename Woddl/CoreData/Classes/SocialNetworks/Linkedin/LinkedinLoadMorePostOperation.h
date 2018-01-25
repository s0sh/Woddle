//
//  LinkedinLoadMorePostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 31.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol LinkedinLoadMorePostOperationDelegate;
@interface LinkedinLoadMorePostOperation : NSOperation
{
    id <LinkedinLoadMorePostOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* from;
@property (nonatomic, strong) NSString* to;
@property (nonatomic, strong) NSString* userID;
@property (nonatomic, assign) BOOL isSelf;


-(id)initLinkedinLoadMorePostOperationWithToken:(NSString*)token andUserID:(NSString*)userID from:(NSString*)from to:(NSString*)to isSelfPosts:(BOOL)isSelf withDelegate:(id)delegate_;

@end

@protocol LinkedinLoadMorePostOperationDelegate<NSObject>
-(void)linkedinLoadMorePostDidFinishWithPosts:(NSArray*)posts;
@end
