//
//  TwitterReplyOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 29.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol TwitterReplyOperationDelegate;
@interface TwitterReplyOperation : NSOperation
{
    id <TwitterReplyOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSData* imageData;

-(id)initTwitterReplyOperationWithToken:(NSString*)token_ andPostID:(NSString*)postID andMessage:(NSString*)message andImage:(NSData*)image withDelegate:(id)delegate_;
@end

@protocol TwitterReplyOperationDelegate<NSObject>
-(void)twitterReplyDidFinishWithSuccess:(NSDictionary*)result;
-(void)twitterReplyDidFinishWithFail;
@end
