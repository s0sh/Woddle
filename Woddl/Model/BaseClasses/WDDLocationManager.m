//
//  WDDLocationManager.m
//  Woddl
//
//  Created by Sergii Gordiienko on 30.11.13.
//  Copyright (c) 2013 IDS. All rights reserved.
//

#import "WDDLocationManager.h"

#import <CoreLocation/CoreLocation.h>

@interface WDDLocationManager() <CLLocationManagerDelegate>
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLGeocoder *geocoder;
@property (strong, atomic) NSMutableArray *blocksRequestingLocation;    // Array of GetLocationBlock
@end

@implementation WDDLocationManager

@synthesize blocksRequestingLocation = _blocksRequestingLocation;

+ (instancetype)sharedLocationManager
{
    static WDDLocationManager *sharedLocationManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLocationManager = [[WDDLocationManager alloc] init];
    });
    return sharedLocationManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self setupLocationMatager];
    }
    return self;
}

- (NSMutableArray *)blocksRequestingLocation
{
    @synchronized(self)
    {
        if (!_blocksRequestingLocation)
        {
            _blocksRequestingLocation = [[NSMutableArray alloc] init];
        }
        return _blocksRequestingLocation;
    }
}

- (CLGeocoder *)geocoder
{
    if (!_geocoder)
    {
        _geocoder = [[CLGeocoder alloc] init];
    }
    return _geocoder;
}

- (void)setBlocksRequestingLocation:(NSMutableArray *)blocksRequestingLocation
{
    @synchronized(self)
    {
        _blocksRequestingLocation = blocksRequestingLocation;
    }
}


- (CLLocationManager *)locationManager
{
    if (!_locationManager)
    {
        _locationManager = [[CLLocationManager alloc] init];
    }
    return _locationManager;
}

- (void)setupLocationMatager
{
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLLocationAccuracyBest;
}

#pragma mark - Public API
static const NSTimeInterval kActualTimeInterval = 10.0f;
- (void)getCurrentLocationInComplition:(GetLocationBlock)resultBlock
{
    NSTimeInterval timeIntervalSinceLastSavedLocation = [[NSDate date] timeIntervalSinceDate:self.locationManager.location.timestamp];
    if (timeIntervalSinceLastSavedLocation > kActualTimeInterval || !self.locationManager.location)
    {
        [self.blocksRequestingLocation addObject:resultBlock];
        [self.locationManager startUpdatingLocation];
    }
    else
    {
        WDDLocation *currentLocation = [[WDDLocation alloc] initWithCLLocation:self.locationManager.location];
        [self.geocoder reverseGeocodeLocation:self.locationManager.location
                            completionHandler:^(NSArray *placemarks, NSError *error)
        {
            CLPlacemark *placemark = [placemarks firstObject];
            if (placemark)
            {
                NSString *locationName = [NSString stringWithFormat:@"%@, %@, %@, %@", placemark.name, placemark.locality, placemark.administrativeArea, placemark.ISOcountryCode];
                currentLocation.name = locationName;
            }
            resultBlock(currentLocation,nil);
        }];
    }
}

#pragma mark - Core Location delegate

- (void)locationManager:(CLLocationManager *)manager
	 didUpdateLocations:(NSArray *)locations
{
    if (self.blocksRequestingLocation.count)
    {
        [self sendLocationInBlocks:[locations lastObject]];
    }
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    [self sendResultInBlocksWithLocation:nil error:error];
}

- (void)sendLocationInBlocks:(CLLocation *)location
{
    if (!location)
    {
        return ;
    }
    
    WDDLocation *wddLocation = [[WDDLocation alloc] initWithCLLocation:location];
    [self.geocoder reverseGeocodeLocation:self.locationManager.location
                        completionHandler:^(NSArray *placemarks, NSError *error){
                            CLPlacemark *placemark = [placemarks firstObject];
                            if (placemark)
                            {
                                NSString *locationName = [NSString stringWithFormat:@"%@, %@, %@, %@", placemark.name, placemark.locality, placemark.administrativeArea, placemark.ISOcountryCode];
                                wddLocation.name = locationName;
                            }
                            [self sendResultInBlocksWithLocation:wddLocation error:nil];
                        }];
}

- (void)sendResultInBlocksWithLocation:(WDDLocation *)location
                                 error:(NSError *)error
{
    NSMutableArray *userdBlocks = [[NSMutableArray alloc]initWithCapacity:self.blocksRequestingLocation.count];
    for (GetLocationBlock block in self.blocksRequestingLocation)
    {
        block(location, error);
        [userdBlocks addObject:block];
    }
    
    [self.blocksRequestingLocation removeObjectsInArray:userdBlocks];
    
    if (!self.blocksRequestingLocation.count)
    {
        [self.locationManager stopUpdatingLocation];
    }
}
@end
