//
//  LinkedinLoadMoreGroupsPostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 09.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol LinkedinLoadMoreGroupsPostOperationDelegate;
@interface LinkedinLoadMoreGroupsPostOperation : NSOperation
{
    id <LinkedinLoadMoreGroupsPostOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* from;
@property (nonatomic, strong) NSString* to;
@property (nonatomic, strong) NSString* groupID;

-(id)initLinkedinLoadMoreGroupsPostOperationWithToken:(NSString*)token groupID:(NSString*)groupID from:(NSString*)from to:(NSString*)to withDelegate:(id)delegate_;

@end

@protocol LinkedinLoadMoreGroupsPostOperationDelegate<NSObject>
-(void)linkedinLoadMoreGroupsPostDidFinishWithPosts:(NSArray*)posts;
@end
