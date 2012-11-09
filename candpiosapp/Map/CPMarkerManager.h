//
//  CPMarkerManager.h
//  candpiosapp
//
//  Created by Stephen Birarda on 10/27/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPMarkerManager : NSObject

@property (strong, nonatomic) NSArray *venues;

+ (CPMarkerManager *)sharedManager;

- (CPVenue *)markerVenueWithID:(NSNumber *)venueID;
- (void)getMarkersWithinRegionDefinedByNortheastCoordinate:(CLLocationCoordinate2D)northeastCoord
                                       southwestCoordinate:(CLLocationCoordinate2D)southwestCoord
                                                completion:(void (^)(NSError *))completion;


@end
