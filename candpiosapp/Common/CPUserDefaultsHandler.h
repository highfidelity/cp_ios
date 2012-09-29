//
//  CPUserDefaultsHandler.h
//  candpiosapp
//
//  Created by Stephen Birarda on 7/3/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPUserDefaultsHandler : NSObject

+ (void)setCurrentUser:(User *)currentUser;
+ (User *)currentUser;

+ (void)setCurrentVenue:(CPVenue *)venue;
+ (CPVenue *)currentVenue;

+ (void)setNumberOfContactRequests:(NSInteger)numberOfContactRequests;
+ (NSInteger)numberOfContactRequests;

+ (void)setPastVenues:(NSArray *)pastVenues;
+ (NSArray *)pastVenues;

+ (void)setCheckoutTime:(NSInteger)checkoutTime;
+ (NSInteger)checkoutTime;
+ (BOOL)isUserCurrentlyCheckedIn;

+ (void)setLastLoggedAppVersion:(NSString *)appVersionString;
+ (NSString *)lastLoggedAppVersion;

+ (void)setAutomaticCheckins:(BOOL)on;
+ (BOOL)automaticCheckins;

+ (void)addFeedVenue:(CPVenue *)venue;
+ (NSDictionary *)feedVenues;
+ (BOOL)hasFeedVenues;
+ (void)removeFeedVenueWithID:(NSUInteger)venueID;

@end
