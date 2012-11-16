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
    formatter.maximumFractionDigits = 0;
    // if we're on a device using the metric system
    if ([[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
        // if the person is more than 100m away show it in km
        if (distance > 100) {
            if (distance < 10000) {
                // decimal fractions from 0.1km - 10km 
                formatter.maximumFractionDigits = 1;                
            }
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
            if (distance < 52800) {
                // decimal fractions miles from 160ft - 10mi
                formatter.maximumFractionDigits = 1;                
            }
            distance = distance * 0.000621371192;
            NSNumber *number = [NSNumber numberWithDouble:distance];
            return [NSString stringWithFormat:@"%@mi", [formatter stringFromNumber:number]];
        } else {
            distance = round(distance * 3.2808399);
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

+ (NSString *)localizedDistanceStringFromMiles:(double)miles
{
    float distance = (float)miles;
    NSString *suffix = @"mi";
    if ([[[NSLocale currentLocale] objectForKey:NSLocaleUsesMetricSystem] boolValue]) {
        distance = roundf(distance * 1609.344);
        if (distance <= 100) {
            suffix = @"m";
        } else {
            distance = distance / 1000;
            suffix = @"km";
        }
    } else {
        if (distance <= 0.1) {
            distance = roundf(distance * 5280);
            suffix = @"ft";
        }
    }
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.maximumFractionDigits = 1;
    NSNumber *number = [NSNumber numberWithDouble:distance];
    
    return [NSString stringWithFormat:@"%@ %@", [formatter stringFromNumber:number], suffix];
}

#pragma mark - Validation
+ (BOOL)validateEmailWithString:(NSString*)email
{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"; 
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex]; 
    return [emailTest evaluateWithObject:email];
}

#pragma mark - Localize a date given an offset from UTC
//
// logic based on sample code provided at
// http://stackoverflow.com/questions/1490537/gmt-time-on-iphone
//
#define SECONDS_IN_HOUR 3600

+ (NSDate*)localizeDate:(NSDate*)date offsetFromUtc:(int)offset;
{
    NSDate* localizedDate;
    
    NSTimeZone* remoteTimeZone = [NSTimeZone timeZoneForSecondsFromGMT:(offset*SECONDS_IN_HOUR)];
    NSTimeZone* utcTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    NSInteger remoteGmtOffset = [remoteTimeZone secondsFromGMTForDate:date];
    NSInteger gmtOffset = [utcTimeZone secondsFromGMTForDate:date];
    NSTimeInterval gmtInterval = gmtOffset - remoteGmtOffset;
    localizedDate = [[NSDate alloc] initWithTimeInterval:gmtInterval sinceDate:date];
    
    return localizedDate;
}

#pragma mark - Relative time string
+ (NSString *)relativeTimeStringFromDateToNow:(NSDate *)date
{
    if (date) {
        NSTimeInterval secondsAgo = -[date timeIntervalSinceNow];
        int secondsInMinute = 60;
        int minutesInHour = 60;
        int hoursInDay = 24;
        int daysInMonth = 30;
        int daysInYear = 365;

        
        if (secondsAgo < secondsInMinute) {
            return @"a moment ago";
        } else if (secondsAgo < secondsInMinute * minutesInHour * hoursInDay * daysInYear){
            double result;
            NSString *unit;
            
            if (secondsAgo < secondsInMinute * minutesInHour) {
                result = secondsAgo / secondsInMinute;
                unit = @"min";
            } else if (secondsAgo < secondsInMinute * minutesInHour * hoursInDay) {
                result = secondsAgo / (secondsInMinute * minutesInHour);
                unit = @"hr";
            } else if (secondsAgo < secondsInMinute * minutesInHour * hoursInDay * daysInMonth) {
                result = secondsAgo / (secondsInMinute * minutesInHour * hoursInDay);
                unit = @"day";
            } else {
                result = secondsAgo / (secondsInMinute * minutesInHour * hoursInDay * daysInMonth);
                unit = @"mnth";
            }
            
            return [NSString stringWithFormat:@"%.f %@ ago", round(result), (round(result) == 1 ? unit : [unit stringByAppendingString:@"s"])];
                
        } else {
            return @"more than 1 yr";
        }
    } else {
        return nil;
    }
}

#pragma mark - Device Identification

+ (BOOL)systemVersionGreaterThanOrEqualTo:(CGFloat)version
{
    return [[[UIDevice currentDevice] systemVersion] floatValue] >= version;
}

+ (BOOL)isDeviceWithFourInchDisplay
{
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [[UIScreen mainScreen] bounds].size.height == 568);
}


@end
