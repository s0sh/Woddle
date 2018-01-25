//
//  InstagramGetPostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 13.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol InstagramGetPostOperationDelegate;
@interface InstagramGetPostOperation : NSOperation
{
    id <InstagramGetPostOperationDelegate> delegate;
    NSUInteger count;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* userID;

-(id)initInstagramGetPostOperationWithToken:(NSString*)token andUserID:(NSString*)userID andCount:(NSUInteger)count withDelegate:(id)delegate_;

@end

@protocol InstagramGetPostOperationDelegate<NSObject>
-(void)instagramGetPostDidFinishWithPosts:(NSArray*)posts;
@end
