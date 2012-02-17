//
//  LocalizedDistanceCalculator.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LocalizedDistanceCalculator.h"

@implementation LocalizedDistanceCalculator

+ (NSString *)localizedDistanceBetweenLocationA:(CLLocation *)locationA andLocationB:(CLLocation *)locationB
{
    // get the distance in meters between the two co-ords
    double distance = [locationA distanceFromLocation:locationB];
    if (distance > 2400000) {
        // this is above our threshold so it's far far away
        return @"Far far away";
    } else {
        // set up a number formatter
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.maximumFractionDigits = 0;
        // if we're on a device using the metric system
        if ([[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
            // if the person is more than 100m away show it in km
            if (distance > 100) {
                distance = distance / 1000.0; // convert to km
                NSNumber *number = [NSNumber numberWithDouble:distance];
                return [NSString stringWithFormat:@"%@km away", [formatter stringFromNumber:number]];                   
            } else {
                NSNumber *number = [NSNumber numberWithDouble:distance];
                return [NSString stringWithFormat:@"%@m away", [formatter stringFromNumber:number]];  
            }           
        } else {
            // if the person is more than 160 feet away (0.1 miles) show it in miles
            if (distance > 160) {
                distance = distance * 0.000621371192;
                NSNumber *number = [NSNumber numberWithDouble:distance];
                return [NSString stringWithFormat:@"%@mi away", [formatter stringFromNumber:number]];
            } else {
                distance = distance * 3.2808399;
                NSNumber *number = [NSNumber numberWithDouble:distance];
                return [NSString stringWithFormat:@"%@ft away", [formatter stringFromNumber:number]];                
            }            
        }
    }
}

@end
