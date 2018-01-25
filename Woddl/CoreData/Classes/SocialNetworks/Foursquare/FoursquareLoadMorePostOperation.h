//
//  FoursquareLoadMorePostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 31.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FoursquareLoadMorePostOperationDelegate;
@interface FoursquareLoadMorePostOperation : NSOperation
{
    id <FoursquareLoadMorePostOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, assign) NSInteger count;

-(id)initFoursquareLoadMorePostOperationWithToken:(NSString*)token from:(NSString*)from to:(NSString*)to withDelegate:(id)delegate_;

@end

@protocol FoursquareLoadMorePostOperationDelegate<NSObject>
-(void)foursquareLoadMorePostDidFinishWithPosts:(NSArray*)posts;
@end
