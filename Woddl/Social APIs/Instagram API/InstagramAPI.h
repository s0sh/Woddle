//
//  InstagramAPI.h
//  Woddl
//
//  Created by Александр Бородулин on 01.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol InstagramAPIDelegate;
@interface InstagramAPI : NSObject
{
    id<InstagramAPIDelegate> delegate;
}

+(InstagramAPI*)Instance;
-(void)loginWithDelegate:(id<InstagramAPIDelegate>)delegate_;
-(void)getMediaWithID:(NSString*)userID andToken:(NSString*)token;

@end

@protocol InstagramAPIDelegate
-(void)loginInstagramSuccessWithToken:(NSString*)token andUserID:(NSString*)userID andScreenName:(NSString*)name andImageURL:(NSString*)imageURL andProfileURL:(NSString *)profileURLString;
-(void)loginInstagramViewController:(UIViewController*) controller;
-(void)loginInstagramFailed;
@end
