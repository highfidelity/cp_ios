//
//  CPUserDefaultsHandler.m
//  candpiosapp
//
//  Created by Stephen Birarda on 7/3/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPUserDefaultsHandler.h"
#import "ContactListViewController.h"
#import "CPTabBarController.h"

// define a way to quickly grab and set NSUserDefaults
#define DEFAULTS(type, key) ([[NSUserDefaults standardUserDefaults] type##ForKey:key])
#define SET_DEFAULTS(Type, key, val) do {\
[[NSUserDefaults standardUserDefaults] set##Type:val forKey:key];\
[[NSUserDefaults standardUserDefaults] synchronize];\
} while (0)

@implementation CPUserDefaultsHandler

NSString* const kUDCurrentUser = @"loggedUser";

+ (void)setCurrentUser:(CPUser *)currentUser
{
#if DEBUG
    NSLog(@"Storing user data for user with ID %@ and nickname %@ to NSUserDefaults", currentUser.userID, currentUser.nickname);
#endif

    [[CPAppDelegate appCache] removeObjectForKey:kUDCurrentUser];
    // encode the user object
    NSData *encodedUser = [NSKeyedArchiver archivedDataWithRootObject:currentUser];
    
    // store it in user defaults
    SET_DEFAULTS(Object, kUDCurrentUser, encodedUser);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginStateChanged" object:nil];
}

+ (CPUser *)currentUser
{
    if (DEFAULTS(object, kUDCurrentUser)) {
        CPUser *user = [[CPAppDelegate appCache] objectForKey:kUDCurrentUser];

        if (!user) {
            // grab the coded user from NSUserDefaults
            NSData *myEncodedObject = DEFAULTS(object, kUDCurrentUser);
            user = (CPUser *)[NSKeyedUnarchiver unarchiveObjectWithData:myEncodedObject];
            if (!user) {
                return nil;
            }
            [[CPAppDelegate appCache] setObject:user forKey:kUDCurrentUser];
        }
        // return it
        return user;
    } else {
        return nil;
    }
}

NSString* const kUDNumberOfContactRequests = @"numberOfContactRequests";
+ (void)setNumberOfContactRequests:(NSInteger)numberOfContactRequests
{
    SET_DEFAULTS(Integer, kUDNumberOfContactRequests, numberOfContactRequests);
    
    // update the badge on the contacts tab number
    CPThinTabBar *thinTabBar = (CPThinTabBar *)[[CPAppDelegate  tabBarController] tabBar];
    [thinTabBar setBadgeNumber:[NSNumber numberWithInteger:numberOfContactRequests]
                    atTabIndex:(kNumberOfTabsRightOfButton - 1)];
}

+ (NSInteger)numberOfContactRequests
{
    return DEFAULTS(integer, kUDNumberOfContactRequests);
}

NSString* const kUDCurrentVenue = @"currentCheckIn";

+ (void)setCurrentVenue:(CPVenue *)venue
{
    // encode the venue object
    NSData *newVenueData = [NSKeyedArchiver archivedDataWithRootObject:venue];
    
    // store it in user defaults
    SET_DEFAULTS(Object, kUDCurrentVenue, newVenueData);
}

+ (CPVenue *)currentVenue
{
    if (DEFAULTS(object, kUDCurrentVenue)) {
        // grab the coded user from NSUserDefaults
        NSData *myEncodedObject = DEFAULTS(object, kUDCurrentVenue);
        // return it
        return (CPVenue *)[NSKeyedUnarchiver unarchiveObjectWithData:myEncodedObject];
    } else {
        return nil;
    }
}


NSString* const kUDPastVenues = @"pastVenues";
+ (void)setPastVenues:(NSArray *)pastVenues
{
    SET_DEFAULTS(Object, kUDPastVenues, pastVenues);  
}

+ (NSArray *)pastVenues
{
    return DEFAULTS(object, kUDPastVenues);
}


NSString* const kUDCheckoutTime = @"localUserCheckoutTime";

+ (void)setCheckoutTime:(NSInteger)checkoutTime
{
    // set the NSUserDefault to the user checkout time
    SET_DEFAULTS(Object, kUDCheckoutTime, [NSNumber numberWithInt:checkoutTime]);
}

+ (NSInteger)checkoutTime
{
    return [DEFAULTS(object, kUDCheckoutTime) intValue];
}

+ (BOOL)isUserCurrentlyCheckedIn
{
    return [self checkoutTime] > [[NSDate date]timeIntervalSince1970];
}


NSString* const kUDLastLoggedAppVersion = @"lastLoggedAppVersion";
+ (void)setLastLoggedAppVersion:(NSString *)appVersionString
{
    SET_DEFAULTS(Object, kUDLastLoggedAppVersion, appVersionString);
}

+ (NSString *)lastLoggedAppVersion
{
    return DEFAULTS(object, kUDLastLoggedAppVersion);
}

NSString* const kAutomaticCheckins = @"automaticCheckins";

+ (void)setAutomaticCheckins:(BOOL)on
{
    SET_DEFAULTS(Object, kAutomaticCheckins, [NSNumber numberWithBool:on]);
}

+ (BOOL)automaticCheckins
{
    return [DEFAULTS(object, kAutomaticCheckins) boolValue];
}

@end
