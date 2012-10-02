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

typedef void (^AFRequestCompletionBlock)(AFHTTPRequestOperation *operation, id responseObject, NSError *error);

+ (FoursquareAPIClient *)sharedClient;

+ (void)getVenuesCloseToLocation:(CLLocation *)location
                               completion:(AFRequestCompletionBlock)completion;

+ (void)getClosestNeighborhoodToLocation:(CLLocation *)location
                                  completion:(AFRequestCompletionBlock)completion;

+ (void)addNewPlace:(NSString *)name
        location:(CLLocation *)location
    completion:(AFRequestCompletionBlock)completion;

@end
