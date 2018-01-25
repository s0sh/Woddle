//
//  WDDMapViewController.m
//  Woddl
//
//  Created by Oleg Komaristov on 1/5/14.
//  Copyright (c) 2014 IDS. All rights reserved.
//

#import "WDDMapViewController.h"

#import "Place+MKAnnotation.h"

#import <MapKit/MapKit.h>

@interface WDDMapViewController ()

@property (nonatomic, strong) Place *place;

@property (nonatomic, strong) MKMapView *mapView;

@end

@implementation WDDMapViewController

- (instancetype)initWithPlace:(Place *)place
{
    if (self = [super init])
    {
        self.place = place;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mapView = [[MKMapView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.mapView];
    
    NSLayoutConstraint *botttom =[NSLayoutConstraint
                                  constraintWithItem:self.mapView
                                  attribute:NSLayoutAttributeBottom
                                  relatedBy:NSLayoutRelationEqual
                                  toItem:self.view
                                  attribute:NSLayoutAttributeBottom
                                  multiplier:1.0
                                  constant:0];
    
    NSLayoutConstraint *top =[NSLayoutConstraint
                              constraintWithItem:self.mapView
                              attribute:NSLayoutAttributeTop
                              relatedBy:NSLayoutRelationEqual
                              toItem:self.view
                              attribute:NSLayoutAttributeTop
                              multiplier:1.0
                              constant:0];
    
    NSLayoutConstraint *left =[NSLayoutConstraint
                               constraintWithItem:self.mapView
                               attribute:NSLayoutAttributeLeft
                               relatedBy:NSLayoutRelationEqual
                               toItem:self.view
                               attribute:NSLayoutAttributeLeft
                               multiplier:1.0
                               constant:0];
    
    NSLayoutConstraint *right=[NSLayoutConstraint
                               constraintWithItem:self.mapView
                               attribute:NSLayoutAttributeRight
                               relatedBy:NSLayoutRelationEqual
                               toItem:self.view
                               attribute:NSLayoutAttributeRight
                               multiplier:1.0
                               constant:0];

    [self.mapView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraints:@[top, left, right, botttom]];
    [self customizeBackButton];
    
    self.title = self.place.name;
    [self.mapView addAnnotation:self.place];
}

- (void)viewDidAppear:(BOOL)animated
{
    MKCoordinateRegion region;
    region.center = self.place.coordinate;
    
    MKCoordinateSpan span;
    span.latitudeDelta = 0.015;
    span.longitudeDelta = 0.015;
    region.span = span;

    [self.mapView setRegion:region animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
