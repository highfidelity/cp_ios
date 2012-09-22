//
//  CPGeofenceHandler.m
//  candpiosapp
//
//  Created by Stephen Birarda on 8/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPGeofenceHandler.h"
#import "CPCheckinHandler.h"
#import "CPApiClient.h"
#import "CPAlertView.h"

#define kGeoFenceAlertTag 601
#define kRadiusForCheckins 10 // measure in meters, from lat/lng of CPVenue
#define kMaxCheckInDuration 24

@implementation CPGeofenceHandler {
    int pendingVenueCheckInID;
}

static CPGeofenceHandler *sharedHandler;

+ (void)initialize
{
    if(!sharedHandler) {
        sharedHandler = [[CPGeofenceHandler alloc] init];
    }
}

+ (CPGeofenceHandler *)sharedHandler
{
    return sharedHandler;
}

- (CLRegion *)getRegionForVenue:(CPVenue *)venue
{
    CLRegion* region = [[CLRegion alloc] initCircularRegionWithCenter:venue.coordinate
                                                               radius:kRadiusForCheckins identifier:venue.name];
    
    return region;
}

- (void)startMonitoringVenue:(CPVenue *)venue
{
    // Only start monitoring a region if automaticCheckins is YES
    if ([CPUserDefaultsHandler automaticCheckins]) {
        CLRegion* region = [self getRegionForVenue:venue];
        
        [[CPAppDelegate locationManager] startMonitoringForRegion:region
                                       desiredAccuracy:kCLLocationAccuracyNearestTenMeters];
        
        [CPapi saveVenueAutoCheckinStatus:venue];
    }
}

- (void)stopMonitoringVenue:(CPVenue *)venue
{
    CLRegion* region = [self getRegionForVenue:venue];
    [[CPAppDelegate locationManager] stopMonitoringForRegion:region];
    
    [CPapi saveVenueAutoCheckinStatus:venue];
    
    [FlurryAnalytics logEvent:@"automaticCheckinLocationDisabled"];
}

- (void)autoCheckInForVenue:(CPVenue *)venue
{
    // Check to see if there is an existing checkin request for this venueID to eliminate duplicate check-ins from multiple geofence triggers
    
    if (pendingVenueCheckInID && venue.venueID == pendingVenueCheckInID) {
        [FlurryAnalytics logEvent:@"autoCheckedInDuplicateIgnored"];
    }
    else {
        // Check the user in automatically now
        [FlurryAnalytics logEvent:@"autoCheckedIn"];

        pendingVenueCheckInID = venue.venueID;

        NSTimeInterval checkInTime = [[NSDate date] timeIntervalSince1970];
        // Set a maximum checkInDuration to 24 hours
        NSInteger checkInDuration = kMaxCheckInDuration;
        
        NSInteger checkOutTime = checkInTime + checkInDuration * 3600;
        NSString *statusText = @"";
        
        // use CPapi to checkin
        [CPApiClient checkInToVenue:venue hoursHere:checkInDuration statusText:statusText isVirtual:NO isAutomatic:YES completionBlock:^(NSDictionary *json, NSError *error){
            
            if (!error) {
                if (![[json objectForKey:@"error"] boolValue]) {
                                        
                    // Cancel all old local notifications
                    [[UIApplication sharedApplication] cancelAllLocalNotifications];
                    
                    [[CPCheckinHandler sharedHandler] setCheckedOut];
                    
                    [CPUserDefaultsHandler setCheckoutTime:checkOutTime];
                    
                    // Save current place to venue defaults as it's used in several places in the app
                    [CPUserDefaultsHandler setCurrentVenue:venue];
                    
                    // update this venue in the list of past venues
                    [self updatePastVenue:venue];
                }
                else {
                    // There was an error checking in; probably safe to ignore
                }
            } else {
                // There was an error in the main call while checking in; probably safe to ignore
            }
            
            // Reset pendingVenueCheckInID to 0 upon completion, regardless of success since we would want the check-in to complete if it failed previously
            pendingVenueCheckInID = 0;
        }];
    }
}

- (void)autoCheckOutForRegion:(CLRegion *)region
{
    [FlurryAnalytics logEvent:@"autoCheckedOut"];
    
    [SVProgressHUD showWithStatus:@"Checking out..."];
    
    [CPapi checkOutWithCompletion:^(NSDictionary *json, NSError *error) {
        
        BOOL respError = [[json objectForKey:@"error"] boolValue];
        
        if (!error && !respError) {
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
            
            NSDictionary *jsonDict = [json objectForKey:@"payload"];
            NSString *venue = [jsonDict valueForKey:@"venue_name"];
            NSMutableString *alertText = [NSMutableString stringWithFormat:@"Checked out of %@.", venue];
            
            int hours = [[jsonDict valueForKey:@"hours_checked_in"] intValue];
            if (hours == 1) {
                [alertText appendString:@" You were there for 1 hour."];
            } else if (hours > 1) {
                [alertText appendFormat:@" You were there for %d hours.", hours];
            }
            
            UILocalNotification *localNotif = [[UILocalNotification alloc] init];
            localNotif.alertBody = alertText;
            localNotif.alertAction = @"View";
            localNotif.soundName = UILocalNotificationDefaultSoundName;
            
            localNotif.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"exit", @"geofence",
                                   region.identifier, @"venue_name",
                                   nil];
            
            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotif];
            [[CPCheckinHandler sharedHandler] setCheckedOut];
            
            [SVProgressHUD dismissWithSuccess:alertText
                                   afterDelay:kDefaultDismissDelay];
        } else {
            NSString *message = [json objectForKey:@"payload"];
            if (!message) {
                message = @"Oops. Something went wrong.";
            }
            [SVProgressHUD dismissWithError:message
                                 afterDelay:kDefaultDismissDelay];
        }
    }];
}

-(void)handleGeofenceNotification:(NSString *)message userInfo:(NSDictionary *)userInfo
{
    // check if the app is currently active
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        // alloc-init a CPAlertView
        CPAlertView *alertView = [[CPAlertView alloc] initWithTitle:message
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:@"View"
                                                  otherButtonTitles:@"Ignore", nil];
        
        // add our userInfo to the alertView
        // be the delegate, give it a tag so we can recognize it
        // and return it
        alertView.context = userInfo;
        alertView.delegate = self;
        alertView.tag = kGeoFenceAlertTag;
        
        [alertView show];
    } else {
        // otherwise when they slide the notification bring them to the venue
        [CPAppDelegate loadVenueView:[userInfo objectForKey:@"venue_name"]];
    }
}

- (void)updatePastVenue:(CPVenue *)venue
{
    // Store updated venue in pastVenues array
    // encode the user object
    NSData *newVenueData = [NSKeyedArchiver archivedDataWithRootObject:venue];
    
    NSArray *pastVenues = [CPUserDefaultsHandler pastVenues];
    
    // Reverse order so that the oldest venues are knocked out
    pastVenues = [[pastVenues reverseObjectEnumerator] allObjects];
    
    NSMutableArray *mutablePastVenues = [[NSMutableArray alloc] init];
    
    NSInteger i = 0;
    
    for (NSData *encodedObject in pastVenues) {
        i++;
        
        CPVenue *unencodedVenue = (CPVenue *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        
        // Only add the current venue at the very end, so that it will stay on the list the longest
        if (unencodedVenue && unencodedVenue.name) {
            if (![unencodedVenue.name isEqualToString:venue.name]) {
                [mutablePastVenues addObject:encodedObject];
            }
        }
        
        // Limit number of geofencable venues to 20 due to iOS limitations; remove all of the old venues from monitoring
        if (i > 18) {
            [self stopMonitoringVenue:unencodedVenue];
        }
    }
    
    [mutablePastVenues addObject:newVenueData];
    [CPUserDefaultsHandler setPastVenues:mutablePastVenues];
}

- (CPVenue *)venueWithName:(NSString *)name
{
    NSArray *pastVenues = [CPUserDefaultsHandler pastVenues];
    
    CPVenue *venueMatch;
    
    for (NSData *encodedObject in pastVenues) {
        CPVenue *venue = (CPVenue *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        
        if ([venue.name isEqualToString:name]) {
            venueMatch = venue;
        }
    }
    
    return venueMatch;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    CPAlertView *cpAlertView = (CPAlertView *)alertView;
    NSDictionary *userInfo = cpAlertView.context;
    
    if (alertView.tag == kGeoFenceAlertTag && alertView.cancelButtonIndex == buttonIndex) {
        // Load the venue if the user tapped on View from the didExit auto checkout alert
        if (userInfo) {
            [CPAppDelegate loadVenueView:[userInfo objectForKey:@"venue_name"]];
        }
    }
}

@end
