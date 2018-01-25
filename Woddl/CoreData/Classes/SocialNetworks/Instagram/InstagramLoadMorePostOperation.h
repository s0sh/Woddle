//
//  InstagramLoadMorePostOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 31.12.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol InstagramLoadMorePostOperationDelegate;
@interface InstagramLoadMorePostOperation : NSOperation
{
    id <InstagramLoadMorePostOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* from;
@property (nonatomic, strong) NSString* to;

-(id)initInstagramLoadMorePostOperationWithToken:(NSString*)token from:(NSString*)from to:(NSString*)to withDelegate:(id)delegate_;

@end

@protocol InstagramLoadMorePostOperationDelegate<NSObject>
-(void)instagramLoadMorePostDidFinishWithPosts:(NSArray*)posts;
@end
