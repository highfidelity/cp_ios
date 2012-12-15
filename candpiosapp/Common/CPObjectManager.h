//
//  CPObjectManager.h
//  candpiosapp
//
//  Created by Stephen Birarda on 10/22/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>

@interface CPObjectManager : RKObjectManager

extern NSString* const kRouteMarkers;
extern NSString* const kRouteVenueCheckedInUsers;
extern NSString* const kRouteVenueFullDetails;
extern NSString* const kRouteNearestCheckedIn;
extern NSString* const kRouteContactsAndRequests;
extern NSString* const kRouteGeofenceCheckout;

@end
