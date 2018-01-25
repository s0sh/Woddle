//
//  FacebookPostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 19.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Post, Group;
@protocol FacebookPostOperationDelegate;

@interface FacebookPostOperation : NSOperation
{
    id <FacebookPostOperationDelegate> delegate;
}

@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* link;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* description;
@property (nonatomic, strong) NSString* picture;

- (id)initFacebookPostOperationWithToken:(NSString *)token_
                              andMessage:(NSString *)message_
                                 andPost:(Post *)post
                                 toGroup:(Group *)group
                            withDelegate:(id)delegate_;
@end

@protocol FacebookPostOperationDelegate<NSObject>
-(void)facebookPostDidFinishWithSuccess;
-(void)facebookPostDidFinishWithFail;
@end
