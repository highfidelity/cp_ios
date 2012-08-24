//
//  CPUserDefaultsHandler.m
//  candpiosapp
//
//  Created by Stephen Birarda on 7/3/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPUserDefaultsHandler.h"
#import "ContactListViewController.h"

// define a way to quickly grab and set NSUserDefaults
#define DEFAULTS(type, key) ([[NSUserDefaults standardUserDefaults] type##ForKey:key])
#define SET_DEFAULTS(Type, key, val) do {\
[[NSUserDefaults standardUserDefaults] set##Type:val forKey:key];\
[[NSUserDefaults standardUserDefaults] synchronize];\
} while (0)

@implementation CPUserDefaultsHandler

NSString* const kUDCurrentUser = @"loggedUser";

+ (void)setCurrentUser:(User *)currentUser
{
#if DEBUG
    NSLog(@"Storing user data for user with ID %d and nickname %@ to NSUserDefaults", currentUser.userID, currentUser.nickname);
#endif

    [[CPAppDelegate appCache] removeObjectForKey:kUDCurrentUser];
    // encode the user object
    NSData *encodedUser = [NSKeyedArchiver archivedDataWithRootObject:currentUser];
    
    // store it in user defaults
    SET_DEFAULTS(Object, kUDCurrentUser, encodedUser);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginStateChanged" object:nil];
    
    if (currentUser.numberOfContactRequests) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNumberOfContactRequestsNotification
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                    currentUser.numberOfContactRequests, @"numberOfContactRequests",
                                                                    nil]];
    }
}

+ (User *)currentUser
{
    if (DEFAULTS(object, kUDCurrentUser)) {
        User *user = [[CPAppDelegate appCache] objectForKey:kUDCurrentUser];

        if (!user) {
            // grab the coded user from NSUserDefaults
            NSData *myEncodedObject = DEFAULTS(object, kUDCurrentUser);
            user = (User *)[NSKeyedUnarchiver unarchiveObjectWithData:myEncodedObject];
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

NSString* const kUDFeedVenues = @"feedVenues";

+ (void)addFeedVenue:(CPVenue *)venue
{
    // setup an NSString object with the venue ID
    NSString *venueIDString = [NSString stringWithFormat:@"%d", venue.venueID];
    
    // encode the venue object
    NSData *encodedVenue = [NSKeyedArchiver archivedDataWithRootObject:venue];
    
    // grab the array of logVenues
    NSMutableDictionary *mutableFeedVenues = [[self feedVenues] mutableCopy];
    
    // make sure we don't already have a venue for with this ID
    if (![mutableFeedVenues objectForKey:venueIDString]) {
        // add the NSData representation of this venue at the venue ID string key
        [mutableFeedVenues setObject:encodedVenue forKey:venueIDString];
    }
    
    SET_DEFAULTS(Object, kUDFeedVenues, [NSDictionary dictionaryWithDictionary:mutableFeedVenues]);
    
    // send a notification so the feed view controller reloads its feeds
    [[NSNotificationCenter defaultCenter] postNotificationName:@"feedVenueAdded" object:self];
}
+ (BOOL)hasFeedVenues
{
    return (DEFAULTS(object, kUDFeedVenues) != nil);
}

+ (NSDictionary *)feedVenues
{
    // pull the array of logVenues from NSUserDefaults
    // create one if it does not exist
    NSDictionary *feedVenues;
    if (!(feedVenues = DEFAULTS(object, kUDFeedVenues))) {
        // the user has not selected any venues yet.. set them up with reasonable defaults
        feedVenues = [NSDictionary dictionary];
    }
    
    return feedVenues;
}

+ (void)removeFeedVenueWithID:(NSUInteger)venueID
{
    NSString *venueIDString = [NSString stringWithFormat:@"%d", venueID];
    NSMutableDictionary *mutableFeedVenues = [[self feedVenues] mutableCopy];
    
    [mutableFeedVenues removeObjectForKey:venueIDString];
    
    SET_DEFAULTS(Object, kUDFeedVenues, [NSDictionary dictionaryWithDictionary:mutableFeedVenues]);
}

@end
