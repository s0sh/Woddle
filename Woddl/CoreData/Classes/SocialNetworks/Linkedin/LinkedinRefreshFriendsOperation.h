//
//  LinkedinRefreshFriendsOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 25.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol LinkedinRefreshFriendsOperationDelegate;
@interface LinkedinRefreshFriendsOperation : NSOperation
{
    id <LinkedinRefreshFriendsOperationDelegate> delegate;
    NSUInteger count;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* userID;

-(id)initLinkedinRefreshFriendsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_;
@end

@protocol LinkedinRefreshFriendsOperationDelegate<NSObject>
-(void)linkedinRefreshFriendsDidFinishWithFriends:(NSArray*)friends;
@end
