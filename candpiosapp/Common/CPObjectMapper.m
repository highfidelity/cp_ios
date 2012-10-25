//
//  CPObjectMapper.m
//  candpiosapp
//
//  Created by Stephen Birarda on 10/22/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPObjectMapper.h"
#import <RestKit/RestKit.h>

@implementation CPObjectMapper

+ (void)initialize
{
    // make sure that RestKit is ready to go
    [RKObjectManager managerWithBaseURL:[NSURL URLWithString:kCandPWebServiceUrl]];
    
    // show the network activity spinner during requests
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
}

+ (void)setupAllRKObjectMappings
{
    
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
            @"id" : @"venueID",
            @"name": @"name",
            @"address": @"address",
            @"foursquare_id": @"foursquareID",
            @"photo_url": @"photoURL",
            @"checked_in_now": @"checkedInNow",
            @"checkins_for_interval": @"weeklyCheckinCount"
         }];
    }
    
    return _venueRKObjectMapping;
}

+ (RKObjectMapping *)userObjectMapping
{
    static RKObjectMapping *_userObjectMapping;
    
    if (!_userObjectMapping) {
        _userObjectMapping = [RKObjectMapping mappingForClass:[CPUser class]];
        
        [_userObjectMapping addAttributeMappingsFromDictionary:@{
            @"id" : @"userID",
            @"nickname": @"nickname",
            @"photo_url" : @"photoURL",
            @"major_job_category": @"majorJobCategory",
            @"minor_job_category": @"minorJobCategory",
            @"is_contact" : @"isContact"
         }];
    }
    
    return _userObjectMapping;
}

@end