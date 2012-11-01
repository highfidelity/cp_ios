//
//  CPGeofenceHandler.h
//  candpiosapp
//
//  Created by Stephen Birarda on 8/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPGeofenceHandler : NSObject <UIAlertViewDelegate>

- (CLRegion *)getRegionForVenue:(CPVenue *)venue;
- (void)startMonitoringVenue:(CPVenue *)venue;
- (void)stopMonitoringVenue:(CPVenue *)venue;
- (void)autoCheckInForVenue:(CPVenue *)venue;
- (void)hanldeAutoCheckOutForRegion:region;
- (void)autoCheckOutForRegion:(CLRegion *)region;
-(void)handleGeofenceNotification:(NSString *)message userInfo:(NSDictionary *)userInfo;
- (void)updatePastVenue:(CPVenue *)venue;
- (CPVenue *)venueWithName:(NSString *)name;

+ (CPGeofenceHandler *)sharedHandler;


@end
