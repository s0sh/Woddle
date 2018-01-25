//
//  LinkedinRefreshGroupsOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 09.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol LinkedinRefreshGroupsOperationDelegate;
@interface LinkedinRefreshGroupsOperation : NSOperation
{
    id <LinkedinRefreshGroupsOperationDelegate> delegate;
    NSUInteger count;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* userID;

-(id)initLinkedinRefreshGroupsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_;
@end

@protocol LinkedinRefreshGroupsOperationDelegate<NSObject>
-(void)linkedinRefreshGroupsDidFinishWithGroups:(NSArray*)groups;
@end
