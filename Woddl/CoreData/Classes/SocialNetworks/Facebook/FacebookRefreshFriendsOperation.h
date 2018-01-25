//
//  FacebookRefreshFriendsOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 24.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FacebookRefreshFriendsOperationDelegate;
@interface FacebookRefreshFriendsOperation : NSOperation
{
    id <FacebookRefreshFriendsOperationDelegate> delegate;
    NSUInteger count;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* userID;

-(id)initFacebookRefreshFriendsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_;
@end

@protocol FacebookRefreshFriendsOperationDelegate<NSObject>
-(void)facebookRefreshFriendsDidFinishWithFriends:(NSArray*)friends;
@end
