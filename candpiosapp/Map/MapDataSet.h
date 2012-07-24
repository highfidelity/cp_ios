//
//  MapDataSet.h
//  candpiosapp
//
//  Created by David Mojdehi on 1/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MKGeometry.h>

@interface MapDataSet : NSObject


@property (nonatomic, readonly, strong) NSArray *annotations;
@property (nonatomic, strong) NSDate *dateLoaded;
@property (nonatomic, assign) MKMapRect regionCovered;
@property (nonatomic, assign) CLLocationCoordinate2D previousCenter;
@property (nonatomic, strong) NSDictionary *activeUsers;
@property (nonatomic, strong) NSDictionary *activeVenues;

+(void)beginLoadingNewDataset:(CLLocationCoordinate2D)mapCenter
				   completion:(void (^)(MapDataSet *set, NSError *error))completion;

-(bool)isValidFor:(MKMapRect)newRegion
        mapCenter:(CLLocationCoordinate2D)mapCenter;

@end
