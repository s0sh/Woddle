//
//  LinkedinGetPostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 13.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol LinkedinGetPostOperationDelegate;
@interface LinkedinGetPostOperation : NSOperation
{
    id <LinkedinGetPostOperationDelegate> delegate;
    NSUInteger count;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* userID;
@property (nonatomic, strong) NSArray* groups;

-(id)initLinkedinGetPostOperationWithToken:(NSString*)token_ andUserID:(NSString*)userID_ andCount:(NSUInteger)count_ andGroups:(NSArray *) groups withDelegate:(id)delegate_;

@end

@protocol LinkedinGetPostOperationDelegate<NSObject>
-(void)linkedinGetPostDidFinishWithPosts:(NSArray*)posts;
@end
