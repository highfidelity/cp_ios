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
@property (nonatomic, readonly, strong) NSMutableArray *annotations;
@property (nonatomic, strong) NSDate *dateLoaded;
@property (nonatomic, assign) MKCoordinateRegion regionCovered;

+(void)beginLoadingNewDataset:(CLLocationCoordinate2D)currentLocation
				   radiusInKm:(double)radiusInKm
				  completion:(void (^)(MapDataSet *set, NSError *error))completion;


@end
