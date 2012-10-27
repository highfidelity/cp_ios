//
//  CPMarkerManager.m
//  candpiosapp
//
//  Created by Stephen Birarda on 10/27/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPMarkerManager.h"
#import "CPObjectManager.h"

@implementation CPMarkerManager

static CPMarkerManager *_sharedManager;

+ (void)initialize
{
    if(!_sharedManager) {
        _sharedManager = [[self alloc] init];
    }
}

+ (CPMarkerManager *)sharedManager
{
    return _sharedManager;
}

- (void)getMarkersWithinRegionDefinedByNortheastCoordinate:(CLLocationCoordinate2D)northeastCoord
                                       southwestCoordinate:(CLLocationCoordinate2D)southwestCoord
{
    NSDictionary *coordinateDictionary = @{
        @"ne_lat" : [NSString stringWithFormat:@"%f", northeastCoord.latitude],
        @"ne_lng" : [NSString stringWithFormat:@"%f", northeastCoord.longitude],
        @"sw_lat" : [NSString stringWithFormat:@"%f", southwestCoord.latitude],
        @"sw_lng" : [NSString stringWithFormat:@"%f", southwestCoord.longitude]
    };
        
    [[CPObjectManager sharedManager] getObjectsAtPathForRouteNamed:@"markers"
                                                            object:coordinateDictionary
                                                        parameters:nil
                                                           success:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
                                                               self.venues = result.array;
                                                           }
                                                           failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                           }];

}

@end
