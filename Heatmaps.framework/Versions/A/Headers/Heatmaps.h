//
//  Heatmaps.h
//  Heatmaps EE
//
//  Created by Cyprian Cieckiewicz
//  Copyright (c) 2013 App Guru, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Heatmaps : NSObject

// Show debugger messages in the console.
// The default is NO.
@property(nonatomic,readwrite)BOOL showDebug;

// Show "Take a screen shot button" on all elements that you track.
// The default is NO.
@property(nonatomic,readwrite)BOOL showScreenshotButtons;

// Disable data upload over WWAN (Edge, 3G, 4G). By default
// all interaction data is send over WiFi and WWAN.
// The default is NO.
@property(nonatomic,readwrite)BOOL disableWWAN;


// Customise the app name that will appear in your account.
// You should set it up if you are using a long name for the optimization purposes
// Custom app name must have less then 20 characters.
@property(nonatomic,retain) NSString* customAppName;

+(Heatmaps*)instance;
-(void)start;

+(void)track:(UIView*)element withKey:(NSString*)key;
+(void)trackScreenWithKey:(NSString*)key;
+(void)trackNavigationBarInNavigationController:(UINavigationController *)navigationController withKey:(NSString *)key;

+(void)stopTrackingElementWithKey:(NSString*)key;
+(void)stopTrackingScreenWithKey:(NSString*)key;
+(void)stopTrackingNavigationBarWithKey:(NSString*)key;

@end
