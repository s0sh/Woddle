//
//  GooglePlusGetPostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 04.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol GooglePlusGetPostOperationDelegate;
@interface GooglePlusGetPostOperation : NSOperation
{
    id <GooglePlusGetPostOperationDelegate> delegate;
    NSUInteger count;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* userID;

-(id)initGooglePlusGetPostOperationWithToken:(NSString*)token userID:(NSString *)userID andCount:(NSUInteger)count withDelegate:(id)delegate_;

@end

@protocol GooglePlusGetPostOperationDelegate<NSObject>
-(void)googlePlusGetPostDidFinishWithPosts:(NSArray*)posts;
@end
