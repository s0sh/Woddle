//
//  FacebookGetPostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 13.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FacebookGetPostOperationDelegate;
@interface FacebookGetPostOperation : NSOperation
{
    id <FacebookGetPostOperationDelegate> delegate;
    NSUInteger count;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* userID;
@property (nonatomic, strong) NSArray* groups;

-(id)initFacebookGetPostOperationWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count andGroups:(NSArray*)groups withDelegate:(id)delegate_;
@end

@protocol FacebookGetPostOperationDelegate<NSObject>
-(void)facebookGetPostDidFinishWithPosts:(NSArray*)posts;
@end
