//
//  CPUtils.m
//  candpiosapp
//
//  Created by Stephen Birarda on 2/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPUtils.h"

@implementation CPUtils

# pragma mark Localized Distance

// returns a string with the localized distance given the distance
+ (NSString *)localizedDistanceStringForDistance:(double)distance
{
    // set up a number formatter
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.maximumFractionDigits = 1;
    // if we're on a device using the metric system
    if ([[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
        // if the person is more than 100m away show it in km
        if (distance > 100) {
            distance = distance / 1000.0; // convert to km
            NSNumber *number = [NSNumber numberWithDouble:distance];
            return [NSString stringWithFormat:@"%@km", [formatter stringFromNumber:number]];                   
        } else {
            NSNumber *number = [NSNumber numberWithDouble:distance];
            return [NSString stringWithFormat:@"%@m", [formatter stringFromNumber:number]];  
        }           
    } else {
        // if the person is more than 160 feet away (0.1 miles) show it in miles
        if (distance > 160) {
            distance = distance * 0.000621371192;
            NSNumber *number = [NSNumber numberWithDouble:distance];
            return [NSString stringWithFormat:@"%@mi", [formatter stringFromNumber:number]];
        } else {
            distance = distance * 3.2808399;
            NSNumber *number = [NSNumber numberWithDouble:distance];
            return [NSString stringWithFormat:@"%@ft", [formatter stringFromNumber:number]];                
        }            
    }
}

// returns a string with the localized distance between two CLLocations
+ (NSString *)localizedDistanceBetweenLocationA:(CLLocation *)locationA
                                   andLocationB:(CLLocation *)locationB {
    double distance = [locationA distanceFromLocation:locationB];
    return [self localizedDistanceStringForDistance:distance];
    
}

// returns a string with 'away' appended to the distance, used on user profile and on user list
+ (NSString *)localizedDistanceofLocationA:(CLLocation *)locationA awayFromLocationB:(CLLocation *)locationB
{
    // get the distance in meters between the two co-ords
    double distance = [locationA distanceFromLocation:locationB];
    if (distance > 2400000) {
        // this is above our threshold so it's far far away
        return @"Far far away";
    } else {
        return [NSString stringWithFormat:@"%@ away", [self localizedDistanceStringForDistance:distance]];
    }
}

@end
