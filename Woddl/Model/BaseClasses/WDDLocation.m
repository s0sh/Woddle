//
//  WDDLocation.m
//  Woddl
//
//  Created by Sergii Gordiienko on 28.10.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDLocation.h"

static NSString * const kCoordinateKey = @"coordinate";
static NSString * const kNameKey = @"name";

@implementation WDDLocation

- (instancetype)initWithCLLocation:(CLLocation *)location
{
    self = [super init];
    if (self)
    {
        [self setLocationWithLatitude:location.coordinate.latitude
                            longitude:location.coordinate.longitude];
        self.accuracy = location.horizontalAccuracy;
    }
    return self;
}

- (void)setLocationWithLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude
{
    self.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
}

- (CLLocationDegrees)latidude
{
    return self.coordinate.latitude;
}

- (CLLocationDegrees)longitude
{
    return self.coordinate.longitude;
}

#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    CLLocationCoordinate2D coordinate = self.coordinate;
    NSValue *coordinateValue = [NSValue valueWithBytes:&coordinate objCType:@encode(CLLocationCoordinate2D)];
    
    [aCoder encodeObject:coordinateValue forKey:kCoordinateKey];
    [aCoder encodeObject:self.name forKey:kNameKey];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        NSValue *coordinateValue = [aDecoder decodeObjectForKey:kCoordinateKey];
        CLLocationCoordinate2D coordinate;
        [coordinateValue getValue:&coordinate];
        
        self.coordinate = coordinate;
        self.name = [aDecoder decodeObjectForKey:kNameKey];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"Name: %@, latitude: %f, lontitude: %f", self.name, self.latidude, self.longitude];
}
@end
