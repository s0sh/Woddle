//
//  TwitterPostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 20.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Post;
@protocol TwitterPostOperationDelegate;
@interface TwitterPostOperation : NSOperation
{
    id <TwitterPostOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* link;

-(id)initTwitterPostOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andPost:(Post*)post withDelegate:(id)delegate_;
@end

@protocol TwitterPostOperationDelegate<NSObject>
-(void)twitterPostDidFinishWithSuccess;
-(void)twitterPostDidFinishWithFail;
@end
