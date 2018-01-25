//
//  TwitterLoadMorePostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 30.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol TwitterLoadMorePostOperationDelegate;
@interface TwitterLoadMorePostOperation : NSOperation
{
    id <TwitterLoadMorePostOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* from;
@property (nonatomic, strong) NSString* to;

-(id)initTwitterLoadMorePostOperationWithToken:(NSString*)token from:(NSString*)from to:(NSString*)to withDelegate:(id)delegate_;

@end

@protocol TwitterLoadMorePostOperationDelegate<NSObject>
-(void)twitterLoadMorePostDidFinishWithPosts:(NSArray*)posts;
@end
