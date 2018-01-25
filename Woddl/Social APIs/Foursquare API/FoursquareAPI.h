//
//  FoursquareAPI.h
//  Woddl
//
//  Created by Александр Бородулин on 01.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol FoursquareAPIDelegate;
@interface FoursquareAPI : NSObject
{
    id<FoursquareAPIDelegate> delegate;
}

+(FoursquareAPI*)Instance;
-(void)loginWithDelegate:(id<FoursquareAPIDelegate>)delegate_;

@end

@protocol FoursquareAPIDelegate
-(void)loginFoursquareViewController:(UIViewController*) controller;
-(void)loginFoursquareFailed;
-(void)loginFoursquareSuccessWithToken:(NSString*)token andUserID:(NSString*)userID andScreenName:(NSString*)name andImageURL:(NSString*)imageURL andProfileURL:(NSString *)profileURLString;
@end
