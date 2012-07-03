//
//  CPUserDefaultsHandler.h
//  candpiosapp
//
//  Created by Stephen Birarda on 7/3/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPUserDefaultsHandler : NSObject

extern NSString* const kUDCurrentUser;
+ (void)setCurrentUser:(User *)currentUser;
+ (User *)currentUser;

extern NSString* const kUDCurrentVenue;
+ (void)setCurrentVenue:(CPVenue *)venue;
+ (CPVenue *)currentVenue;

extern NSString* const kUDPastVenues;
+ (void)setPastVenues:(NSArray *)pastVenues;
+ (NSArray *)pastVenues;

extern NSString* const kUDCheckoutTime;
+ (void)setCheckoutTime:(NSInteger)checkoutTime;
+ (NSInteger)checkoutTime;
+ (BOOL)isUserCurrentlyCheckedIn;

extern NSString* const kUDLastLoggedAppVersion;
+ (void)setLastLoggedAppVersion:(NSString *)appVersionString;
+ (NSString *)lastLoggedAppVersion;

extern NSString* const kAutomaticCheckins;
+ (void)setAutomaticCheckins:(BOOL)on;
+ (BOOL)automaticCheckins;

extern NSString* const kUDLogVenues;

@end
