//
//  CPCheckinHandler.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPCheckinHandler.h"
#import "CPGeofenceHandler.h"

@implementation CPCheckinHandler

@synthesize afterCheckinAction = _afterCheckinAction;
@synthesize checkOutTimer = _checkOutTimer;

static CPCheckinHandler *sharedHandler;

+ (void)initialize
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        sharedHandler = [[CPCheckinHandler alloc] init];
    }
}

+ (CPCheckinHandler *)sharedHandler
{
    return sharedHandler;
}

- (void)presentCheckinModalFromViewController:(UIViewController *)presentingViewController
{
    // grab the inital view controller of the checkin storyboard
    UINavigationController *checkinNVC = [[UIStoryboard storyboardWithName:@"CheckinStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
    
    // present that VC modally
    [presentingViewController presentModalViewController:checkinNVC animated:YES];
}

- (void)handleSuccessfulCheckinToVenue:(CPVenue *)venue checkoutTime:(NSInteger)checkoutTime
{       
    [self setCheckedOut];
    // set the NSUserDefault to the user checkout time
    [CPUserDefaultsHandler setCheckoutTime:checkoutTime];
    
    // Save current place to venue defaults as it's used in several places in the app
    [CPUserDefaultsHandler setCurrentVenue:venue];
    
    [self performAfterCheckinActionForVenue:venue];
    
    // If this is the user's first check in to this venue and auto-checkins are enabled,
    // ask the user about checking in automatically to this venue in the future
    BOOL automaticCheckins = [CPUserDefaultsHandler automaticCheckins];
    
    if (automaticCheckins) {
        // Only show the alert if the current venue isn't currently in the list of monitored venues
        CPVenue *matchedVenue = [[CPGeofenceHandler sharedHandler] venueWithName:venue.name];
        
        if (!matchedVenue) {                    
            UIAlertView *autoCheckinAlert = [[UIAlertView alloc] initWithTitle:nil 
                                                                       message:@"Automatically check in to this venue in the future?" 
                                                                      delegate:[CPAppDelegate settingsMenuController]
                                                             cancelButtonTitle:@"No" 
                                                             otherButtonTitles:@"Yes", nil];
            autoCheckinAlert.tag = AUTOCHECKIN_PROMPT_TAG;
            [autoCheckinAlert show];
        }
    }
}

- (void)queueLocalNotificationForVenue:(CPVenue *)venue checkoutTime:(NSInteger)checkoutTime
{
    // Fire a notification 5 minutes before checkout time
    NSInteger minutesBefore = 5;
    UILocalNotification *localNotif = [[UILocalNotification alloc] init];
    NSDictionary *venueDataDict;
    
    // Cancel all old local notifications
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    localNotif.alertBody = @"You will be checked out of C&P in 5 min.";
    localNotif.alertAction = @"Check Out";
    localNotif.soundName = UILocalNotificationDefaultSoundName;
    
    localNotif.fireDate = [NSDate dateWithTimeIntervalSince1970:(checkoutTime - minutesBefore * 60)];
    localNotif.timeZone = [NSTimeZone defaultTimeZone];
    
    // encode the venue and store it in an NSDictionary
    NSData *venueData = [NSKeyedArchiver archivedDataWithRootObject:venue];
    venueDataDict = [NSDictionary dictionaryWithObject:venueData forKey:@"venue"];
    
    localNotif.userInfo = venueDataDict;
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
}

- (void)setCheckedOut
{
    // set user checkout time to now
    NSInteger checkOutTime = (NSInteger) [[NSDate date] timeIntervalSince1970];
    [CPUserDefaultsHandler setCheckoutTime:checkOutTime];
    
    // nil out the venue in NSUserDefaults
    [CPUserDefaultsHandler setCurrentVenue:nil];
    if (self.checkOutTimer != nil) {
        [[self checkOutTimer] invalidate];
        self.checkOutTimer = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"userCheckInStateChange" object:nil];
}

- (void)saveCheckInVenue:(CPVenue *)venue andCheckOutTime:(NSInteger)checkOutTime
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [self setCheckedOut];
    [CPUserDefaultsHandler setCheckoutTime:checkOutTime];
    [CPUserDefaultsHandler setCurrentVenue:venue];
    
    // before we update the past venue we need to get its local autocheckin status
    // so that it doesn't get overriden by the call
    CPVenue *staleVenue;
    
    if ((staleVenue = [[CPGeofenceHandler sharedHandler] venueWithName:venue.name])) {
        venue.autoCheckin = staleVenue.autoCheckin;
    }
    
    [[CPGeofenceHandler sharedHandler] updatePastVenue:venue];
    [self queueLocalNotificationForVenue:venue checkoutTime:checkOutTime];
}

- (void)promptForCheckout
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Check Out"
                          message:@"Are you sure you want to be checked out?"
                          delegate:[CPAppDelegate settingsMenuController]
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles: @"Check Out", nil];
    alert.tag = 904;
    [alert show];
}

- (void)performAfterCheckinActionForVenue:(CPVenue *)venue
{
    if (self.afterCheckinAction != CPAfterCheckinActionNone) {
        // Add this venue to the list of recent venues for the feed TVC
        // if this was a forced checkin we need to show the feed now
        [CPUserDefaultsHandler addFeedVenue:venue];
        
        if (self.afterCheckinAction == CPAfterCheckinActionNewUpdate) {
            [[CPAppDelegate tabBarController] showFeedVCForNewPostWithPostType:CPPostTypeUpdate];
        } else if (self.afterCheckinAction == CPAfterCheckinActionNewQuestion) {
            [[CPAppDelegate tabBarController] showFeedVCForNewPostWithPostType:CPPostTypeQuestion];
        }
        
        self.afterCheckinAction = CPAfterCheckinActionNone;
    }
}

@end
