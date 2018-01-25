//
//  FacebookLoadMoreGroupsPostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 06.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FacebookLoadMoreGroupsPostOperationDelegate;
@interface FacebookLoadMoreGroupsPostOperation : NSOperation
{
    id <FacebookLoadMoreGroupsPostOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* from;
@property (nonatomic, strong) NSString* to;
@property (nonatomic, strong) NSString* groupID;

-(id)initFacebookLoadMoreGroupsPostOperationWithToken:(NSString*)token groupID:(NSString*)groupID from:(NSString*)from to:(NSString*)to withDelegate:(id)delegate_;

@end

@protocol FacebookLoadMoreGroupsPostOperationDelegate<NSObject>
-(void)facebookLoadMoreGroupsPostDidFinishWithPosts:(NSArray*)posts;
@end
