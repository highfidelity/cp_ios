//
//  FoursquareAPIRequest.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface FoursquareAPIClient: AFHTTPClient

+ (FoursquareAPIClient *)sharedClient;

+ (void)getVenuesCloseToLocation:(CLLocation *)location
                               withCompletion:(void (^)(AFHTTPRequestOperation *operation, id responseObject, NSError *error))completion;

+ (void)addNewPlace:(NSString *)name
        atLocation:(CLLocation *)location
    withCompletion:(void (^)(AFHTTPRequestOperation *operation, id responseObject, NSError *error))completion;

@end
