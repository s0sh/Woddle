//
//  LinkedinPostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 20.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Post;
@protocol LinkedinPostOperationDelegate;
@interface LinkedinPostOperation : NSOperation
{
    id <LinkedinPostOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* link;
@property (nonatomic, strong) NSString* description;
@property (nonatomic, strong) NSString* picture;

-(id)initLinkedinPostOperationWithToken:(NSString*)token_ andMessage:(NSString*)message_ andPost:(Post*)post withDelegate:(id)delegate_;
@end

@protocol LinkedinPostOperationDelegate<NSObject>
-(void)linkedinPostDidFinishWithSuccess;
-(void)linkedinPostDidFinishWithFail;
@end
