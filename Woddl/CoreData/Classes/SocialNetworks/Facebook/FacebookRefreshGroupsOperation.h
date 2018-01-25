//
//  FacebookRefreshGroupsOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 18.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FacebookRefreshGroupsOperationDelegate;
@interface FacebookRefreshGroupsOperation : NSOperation
{
    id <FacebookRefreshGroupsOperationDelegate> delegate;
    NSUInteger count;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* userID;

-(id)initFacebookRefreshGroupsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_;
@end

@protocol FacebookRefreshGroupsOperationDelegate<NSObject>
-(void)facebookRefreshGroupsDidFinishWithGroups:(NSArray*)groups;
@end
