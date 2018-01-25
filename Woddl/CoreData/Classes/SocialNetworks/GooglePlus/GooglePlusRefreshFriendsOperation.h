//
//  GooglePlusRefreshFriendsOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 25.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol GooglePlusRefreshFriendsOperationDelegate;
@interface GooglePlusRefreshFriendsOperation : NSOperation
{
    id <GooglePlusRefreshFriendsOperationDelegate> delegate;
    NSUInteger count;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* userID;

-(id)initGooglePlusRefreshFriendsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_;
@end

@protocol GooglePlusRefreshFriendsOperationDelegate<NSObject>
-(void)googlePlusRefreshFriendsDidFinishWithFriends:(NSArray*)friends;
@end
