//
//  WDDLocationManager.h
//  Woddl
//
//  Created by Sergii Gordiienko on 30.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WDDLocation.h"

typedef void(^GetLocationBlock)(WDDLocation *location, NSError *error);

@interface WDDLocationManager : NSObject

+ (instancetype)sharedLocationManager;

- (void)getCurrentLocationInComplition:(GetLocationBlock)resultBlock;

@end
