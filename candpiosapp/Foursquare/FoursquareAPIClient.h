//
//  FoursquareAPIRequest.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define kFoursquareNeighborhoodCategoryID @"4f2a25ac4b909258e854f55f"

@interface FoursquareAPIClient: AFHTTPClient

typedef void (^AFRequestCompletionBlock)(AFHTTPRequestOperation *operation, id responseObject, NSError *error);

+ (FoursquareAPIClient *)sharedClient;

+ (AFHTTPRequestOperation *)getVenuesCloseToLocation:(CLLocation *)location
                      searchText:(NSString *)searchText
                      completion:(AFRequestCompletionBlock)completion;

+ (AFHTTPRequestOperation *)getClosestNeighborhoodToLocation:(CLLocation *)location
                              completion:(AFRequestCompletionBlock)completion;

@end
