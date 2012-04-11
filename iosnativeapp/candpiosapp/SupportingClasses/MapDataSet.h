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

// TODO: Although it might not matter because I don't think the map comes back to grab it
// (it simply alloc-inits a completely new dataset)
// this, like activeUsers, should really not be mutable so that nobody grabs it and
// changes the data from underneath the map 

@property (nonatomic, readonly, strong) NSMutableArray *annotations;
@property (nonatomic, strong) NSDate *dateLoaded;
@property (nonatomic, assign) MKMapRect regionCovered;
@property (nonatomic, strong) NSDictionary *activeUsers;

+(void)beginLoadingNewDataset:(MKMapRect)mapRect
				   completion:(void (^)(MapDataSet *set, NSError *error))completion;

-(bool)isValidFor:(MKMapRect)newRegion;

@end
