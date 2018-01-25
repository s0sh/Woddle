//
//  FoursquareLikeOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 16.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FoursquareLikeOperationDelegate;
@interface FoursquareLikeOperation : NSOperation
{
    id <FoursquareLikeOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* myID;

-(id)initFoursquareLikeOperationWithToken:(NSString*)token andPostID:(NSString*)postID andMyID:(NSString*)myID withDelegate:(id)delegate_;
@end

@protocol FoursquareLikeOperationDelegate<NSObject>
-(void)foursquareLikeDidFinishWithSuccess;
-(void)foursquareLikeDidFinishWithFail;
-(void)foursquareUnlikeDidFinishWithSuccess;
-(void)foursquareUnlikeDidFinishWithFail;
@end
