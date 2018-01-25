//
//  FoursquareGetPostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 13.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FoursquareGetPostOperationDelegate;
@interface FoursquareGetPostOperation : NSOperation
{
    id <FoursquareGetPostOperationDelegate> delegate;
    NSUInteger count;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* userID;

-(id)initFoursquareGetPostOperationWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count withDelegate:(id)delegate_;
@end

@protocol FoursquareGetPostOperationDelegate<NSObject>
-(void)foursquareGetPostDidFinishWithPosts:(NSArray*)posts;
@end