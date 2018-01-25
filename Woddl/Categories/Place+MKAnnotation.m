//
//  Place+MKAnnotation.m
//  Woddl
//
//  Created by Oleg Komaristov on 1/5/14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "Place+MKAnnotation.h"

@implementation Place (MKAnnotation)

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake(self.latitude.doubleValue, self.longitude.doubleValue);
}

- (NSString *)title
{
    return self.name;
}

- (NSString *)subtitle
{
    return self.address;
}

@end
