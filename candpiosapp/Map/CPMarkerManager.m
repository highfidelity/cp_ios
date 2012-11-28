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

+(void)initialize
{
    if(!_sharedManager) {
        _sharedManager = [[self alloc] init];
    }
}

+(CPMarkerManager *)sharedManager
{
    return _sharedManager;
}

- (void)getMarkersWithinRegionDefinedByNortheastCoordinate:(CLLocationCoordinate2D)northeastCoord
                                       southwestCoordinate:(CLLocationCoordinate2D)southwestCoord
                                                completion:(void (^)(NSError *))completion
{
    NSDictionary *coordinateDictionary = @{
        @"ne_lat" : [NSString stringWithFormat:@"%f", northeastCoord.latitude],
        @"ne_lng" : [NSString stringWithFormat:@"%f", northeastCoord.longitude],
        @"sw_lat" : [NSString stringWithFormat:@"%f", southwestCoord.latitude],
        @"sw_lng" : [NSString stringWithFormat:@"%f", southwestCoord.longitude]
    };
        
    [[CPObjectManager sharedManager] getObjectsAtPathForRouteNamed:kRouteMarkers
                                                            object:coordinateDictionary
                                                        parameters:@{@"v" : @"20121128"}
                                                           success:^(RKObjectRequestOperation *operation, RKMappingResult *result) {
                                                               self.venues = result.array;
                                                               [self getActiveUsersForMarkers];
                                                               completion(nil);
                                                           }
                                                           failure:^(RKObjectRequestOperation *operation, NSError *error) {
                                                               completion(error);
                                                           }];
}

-(CPVenue *)markerVenueWithID:(NSNumber *)venueID
{
    // leverage the isEqual method in CPVenue to pull out the desired venue
    CPVenue *searchVenue = [[CPVenue alloc] init];
    searchVenue.venueID = venueID;
    
    NSUInteger venueIndex = [self.venues indexOfObject:searchVenue];
    
    return venueIndex != NSNotFound ? [self.venues objectAtIndex:venueIndex] : nil;
}

-(void)getActiveUsersForMarkers
{
    // if we went over the limit on the backend and didn't get active users for some of the venues let's do that now
    for (CPVenue *markerVenue in self.venues) {
        // check if we have checkins for this venue but no people
        if ([markerVenue.checkedInNow intValue] > 0 && markerVenue.checkedInUsers.count == 0) {
            [[CPObjectManager sharedManager] getObjectsAtPathForRouteNamed:kRouteVenueCheckedInUsers
                                                                    object:markerVenue
                                                                parameters:nil
                                                                   success:^(RKObjectRequestOperation *operation, RKMappingResult *result)
            {
                markerVenue.checkedInUsers = result.array;
            } failure:^(RKObjectRequestOperation *operation, NSError *error) {
                // we didn't get the activeUsers for this venue
                // it's not the end of the world
                // fail safe will be additional call when venue page is loaded
            }];
        }
    }
}

@end
