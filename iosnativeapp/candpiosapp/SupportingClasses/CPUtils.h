//
//  CPUtils.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface CPUtils : NSObject

+ (NSString *)localizedDistanceStringForDistance:(double)distance;
+ (NSString *)localizedDistanceBetweenLocationA:(CLLocation *)locationA
    andLocationB:(CLLocation *)locationB;
+ (NSString *)localizedDistanceofLocationA:(CLLocation *)locationA awayFromLocationB:(CLLocation *)locationB;

+ (NSString *)localizedDistanceStringFromMiles:(double)miles;

@end
