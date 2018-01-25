//
//  LinkedinAPI.h
//  Woddl
//
//  Created by Александр Бородулин on 04.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol LinkedinAPIDelegate;
@interface LinkedinAPI : NSObject
{
    id<LinkedinAPIDelegate> delegate;
}
+(LinkedinAPI*)Instance;
-(void)loginWithDelegate:(id<LinkedinAPIDelegate>)delegate_;

@end

@protocol LinkedinAPIDelegate
-(void)loginLinkedinViewController:(UIViewController*) controller;
-(void)loginLinkedinFailed;
-(void)loginLinkedinSuccessWithToken:(NSString*)token andUserID:(NSString*)userID andScreenName:(NSString*)name andImageURL:(NSString*)imageURL andTimeExpire:(NSDate*)expires andProfileURL:(NSString *)profileURLString andGroups:(NSArray*)grpups;
@end

