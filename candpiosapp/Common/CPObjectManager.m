//
//  CPObjectManager.m
//  candpiosapp
//
//  Created by Stephen Birarda on 10/22/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPObjectManager.h"
#import <RestKit/RestKit.h>

@implementation CPObjectManager

+ (void)initialize
{
    // make sure that RestKit is ready to go
    [self managerWithBaseURL:[NSURL URLWithString:kCandPWebServiceUrl]];
    
    // show the network activity spinner during requests
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    // if you want RK to log out request/response
    // flip this to 1
#if 0
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
#endif
    
    // set the api version header so that we get RK friendly responses from C&P backend
    [[self sharedManager].HTTPClient setDefaultHeader:kCPAPIVersionHeader value:kCPAPIVersionValue];
    
    [self setupAllRKObjectMappings];
    [self setupAllRKRouting];
}

+ (void)setupAllRKObjectMappings
{
    RKObjectManager *sharedManager = [self sharedManager];
    NSIndexSet *successCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful);
    
    RKResponseDescriptor *venuesDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[self venueRKObjectMapping]
                                                                                   pathPattern:nil
                                                                                       keyPath:@"payload.venues"
                                                                                   statusCodes:successCodes];
    RKResponseDescriptor *venueDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[self venueRKObjectMapping]
                                                                                    pathPattern:nil
                                                                                        keyPath:@"payload.venue"
                                                                                    statusCodes:successCodes];
    
    RKResponseDescriptor *usersDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:[self userObjectMapping]
                                                                                    pathPattern:nil
                                                                                        keyPath:@"payload.users"
                                                                                    statusCodes:successCodes];
    
    [sharedManager addResponseDescriptorsFromArray:@[venueDescriptor, venuesDescriptor, usersDescriptor]];
}

+ (RKObjectMapping *)venueRKObjectMapping
{
    static RKObjectMapping *_venueRKObjectMapping;
    
    if (!_venueRKObjectMapping) {
        _venueRKObjectMapping = [RKObjectMapping mappingForClass:[CPVenue class]];
        
        // the API usually allows for an interval to be passed when asking for venue info
        // as of right now the mobile app never passes this and it's always 7 days
        
        // if we decide that in some places we want a different interval we should switch
        // the venue property to also be intervalCheckinCount, and maintain another
        // parameter so that for a given venue we know which interval it is for
        
        [_venueRKObjectMapping addAttributeMappingsFromDictionary:@{
            @"id": @"venueID",
            @"name": @"name",
            @"address": @"address",
            @"city": @"city",
            @"state": @"state",
            @"phone": @"phone",
            @"formatted_phone": @"formattedPhone",
            @"lat": @"lat",
            @"lng": @"lng",
            @"foursquare_id": @"foursquareID",
            @"photo_url": @"photoURL",
            @"checked_in_now": @"checkedInNow",
            @"checkins_for_interval": @"weeklyCheckinCount",
            @"is_neighborhood": @"isNeighborhood",
            @"has_contacts": @"hasCheckedInContacts"
         }];
        
        RKRelationshipMapping *checkedInUsersRel = [RKRelationshipMapping relationshipMappingFromKeyPath:@"checked_in_users" toKeyPath:@"checkedInUsers" withMapping:[self userObjectMapping]];
        RKRelationshipMapping *previousUsersRel = [RKRelationshipMapping relationshipMappingFromKeyPath:@"previous_users" toKeyPath:@"previousUsers" withMapping:[self userObjectMapping]];
        [_venueRKObjectMapping addPropertyMappingsFromArray:@[checkedInUsersRel, previousUsersRel]];
    }
    
    return _venueRKObjectMapping;
}

+ (RKObjectMapping *)userObjectMapping
{
    static RKObjectMapping *_userObjectMapping;
    
    if (!_userObjectMapping) {
        _userObjectMapping = [RKObjectMapping mappingForClass:[CPUser class]];
        
        [_userObjectMapping addAttributeMappingsFromDictionary:@{
            @"id": @"userID",
            @"nickname": @"nickname",
            @"photo_url": @"photoURL",
            @"job_title": @"jobTitle",
            @"major_job_category": @"majorJobCategory",
            @"minor_job_category": @"minorJobCategory",
            @"is_contact": @"isContact",
            @"total_check_in_time": @"totalCheckInTime",
            @"total_check_in_count": @"totalCheckInCount"
         }];
    }
    
    return _userObjectMapping;
}

NSString* const kRouteMarkers = @"markers";
NSString* const kRouteVenueCheckedInUsers = @"venueCheckedInUsers";
NSString* const kRouteVenueFullDetails = @"venueDetails";

+ (void)setupAllRKRouting
{
    RKObjectManager *sharedManager = [self sharedManager];
    
    [sharedManager.router.routeSet addRoute:[RKRoute routeWithName:kRouteMarkers
                                                       pathPattern:@"api.php?action=getMarkers&ne_lat=:ne_lat&ne_lng=:ne_lng&sw_lng=:sw_lng&sw_lat=:sw_lat"
                                                            method:RKRequestMethodGET]];
    [sharedManager.router.routeSet addRoute:[RKRoute routeWithName:kRouteVenueCheckedInUsers
                                                       pathPattern:@"api.php?action=getVenueDetails&venue_id=:venueID"
                                                            method:RKRequestMethodGET]];
    [sharedManager.router.routeSet addRoute:[RKRoute routeWithName:kRouteVenueFullDetails
                                                       pathPattern:@"api.php?action=getVenueCheckInData&venue_id=:venueID"
                                                            method:RKRequestMethodGET]];
}

@end