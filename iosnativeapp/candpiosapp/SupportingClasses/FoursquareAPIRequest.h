//
//  FoursquareAPIRequest.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface FoursquareAPIRequest: NSObject

+(void)dictForVenueWithFoursquareID:(NSString *)foursquare_id
                                             :(void (^)(NSDictionary *dict, NSError *error))completion;

+(void)getVenuesCloseToLocation:(CLLocation *)location 
                               :(void (^)(NSDictionary *dict, NSError *error))completion;

@end
