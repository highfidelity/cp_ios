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


@property (strong, nonatomic, readonly) NSArray *annotations;
@property (strong, nonatomic) NSDate *dateLoaded;
@property (strong, nonatomic) NSDictionary *activeUsers;
@property (strong, nonatomic) NSDictionary *activeVenues;
@property (nonatomic) MKMapRect regionCovered;
@property (nonatomic) CLLocationCoordinate2D previousCenter;

+(void)beginLoadingNewDataset:(CLLocationCoordinate2D)mapCenter
				   completion:(void (^)(MapDataSet *set, NSError *error))completion;

-(bool)isValidFor:(MKMapRect)newRegion
        mapCenter:(CLLocationCoordinate2D)mapCenter;

@end
