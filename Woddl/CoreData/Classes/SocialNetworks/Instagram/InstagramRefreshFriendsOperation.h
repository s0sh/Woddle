//
//  InstagramRefreshFriendsOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 25.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol InstagramRefreshFriendsOperationDelegate;
@interface InstagramRefreshFriendsOperation : NSOperation
{
    id <InstagramRefreshFriendsOperationDelegate> delegate;
    NSUInteger count;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* userID;

-(id)initInstagramRefreshFriendsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_;
@end

@protocol InstagramRefreshFriendsOperationDelegate<NSObject>
-(void)instagramRefreshFriendsDidFinishWithFriends:(NSArray*)friends;
@end
