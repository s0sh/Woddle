//
//  WDDLocation.h
//  Woddl
//
//  Created by Sergii Gordiienko on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface WDDLocation : NSObject <NSCoding>

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *foursquareID;
@property (strong, nonatomic) NSString *facebookID;
@property (assign, nonatomic) CLLocationCoordinate2D coordinate;
@property (assign, nonatomic) CLLocationAccuracy accuracy;

- (instancetype)initWithCLLocation:(CLLocation *)location;

- (void)setLocationWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;
- (CLLocationDegrees)latidude;
- (CLLocationDegrees)longitude;

@end
