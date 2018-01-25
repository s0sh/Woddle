//
//  FoursquareRefreshFriendsOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 25.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FoursquareRefreshFriendsOperationDelegate;
@interface FoursquareRefreshFriendsOperation : NSOperation
{
    id <FoursquareRefreshFriendsOperationDelegate> delegate;
    NSUInteger count;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* userID;

-(id)initFoursquareRefreshFriendsOperationWithToken:(NSString*)token andUserID:(NSString*)userID withDelegate:(id)delegate_;
@end

@protocol FoursquareRefreshFriendsOperationDelegate<NSObject>
-(void)foursquareRefreshFriendsDidFinishWithFriends:(NSArray*)friends;
@end
