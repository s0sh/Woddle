//
//  FacebookLoadMorePostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 03.01.14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FacebookLoadMorePostOperationDelegate;
@interface FacebookLoadMorePostOperation : NSOperation
{
    id <FacebookLoadMorePostOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* from;
@property (nonatomic, strong) NSString* to;

-(id)initFacebookLoadMorePostOperationWithToken:(NSString*)token from:(NSString*)from to:(NSString*)to withDelegate:(id)delegate_;

@end

@protocol FacebookLoadMorePostOperationDelegate<NSObject>
-(void)facebookLoadMorePostDidFinishWithPosts:(NSArray*)posts;
@end
