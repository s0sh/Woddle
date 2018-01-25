//
//  FoursquareCommentOperation.h
//  Woddl
//
//  Created by Александр Бородулин on 26.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FoursquareCommentOperationDelegate;
@interface FoursquareCommentOperation : NSOperation
{
    id <FoursquareCommentOperationDelegate> delegate;
}
@property (nonatomic, strong) NSString* token;
@property (nonatomic, strong) NSString* objectID;
@property (nonatomic, strong) NSString* message;
@property (nonatomic, strong) NSString* userID;

-(id)initFoursquareCommentOperationWithMesage:(NSString*)message_ andToken:(NSString*)token_ andPostID:(NSString*)postID withDelegate:(id)delegate_;
@end

@protocol FoursquareCommentOperationDelegate<NSObject>
-(void)foursquareCommentDidFinishWithDictionary:(NSDictionary*)comment;
-(void)foursquareCommentDidFinishWithFail;
@end
