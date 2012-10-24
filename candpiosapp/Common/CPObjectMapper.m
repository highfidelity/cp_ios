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
    [RKObjectManager objectManagerWithBaseURLString:kCandPWebServiceUrl];
    
    // show the network activity spinner during requests
    [RKObjectManager sharedManager].client.requestQueue.showsNetworkActivityIndicatorWhenBusy = YES;
}

+ (void)setupAllRKObjectMappings
{
    RKObjectMappingProvider *sharedMapper = [RKObjectManager sharedManager].mappingProvider;
    
    [sharedMapper setMapping:[self venueRKObjectMapping] forKeyPath:@"venues"];
    [sharedMapper setMapping:[self userObjectMapping] forKeyPath:@"users"];
}

+ (RKObjectMapping *)venueRKObjectMapping
{
    static RKObjectMapping *_venueRKObjectMapping;
    
    if (!_venueRKObjectMapping) {
        _venueRKObjectMapping = [RKObjectMapping mappingForClass:[CPVenue class]];
        
        [_venueRKObjectMapping mapKeyPath:@"id" toAttribute:@"venueID"];
        [_venueRKObjectMapping mapAttributes:@"name", @"address", nil];
        [_venueRKObjectMapping mapKeyPath:@"foursquare_id" toAttribute:@"foursquareID"];
        [_venueRKObjectMapping mapKeyPath:@"photo_url" toAttribute:@"photoURL"];
        
        [_venueRKObjectMapping mapKeyPath:@"checked_in_now" toAttribute:@"checkinCount"];
        
        // the API usually allows for an interval to be passed when asking for venue info
        // as of right now the mobile app never passes this and it's always 7 days
        
        // if we decide that in some places we want a different interval we should switch
        // the venue property to also be intervalCheckinCount, and maintain another
        // parameter so that for a given venue we know which interval it is for
        [_venueRKObjectMapping mapKeyPath:@"checkins_for_interval" toAttribute:@"weeklyCheckinCount"];
        
    }
    
    return _venueRKObjectMapping;
}

+ (RKObjectMapping *)userObjectMapping
{
    static RKObjectMapping *_userObjectMapping;
    
    if (!_userObjectMapping) {
        _userObjectMapping = [RKObjectMapping mappingForClass:[CPUser class]];
        
        [_userObjectMapping mapKeyPath:@"id" toAttribute:@"userID"];
        [_userObjectMapping mapAttributes:@"nickname",
                                          @"major_job_category",
                                          @"minor_job_category",
                                          nil];
        [_userObjectMapping mapKeyPath:@"filename" toAttribute:@"photoURLString"];
        [_userObjectMapping mapKeyPath:@"is_contact" toAttribute:@"isContact"];
    }
    
    return _userObjectMapping;
}

@end
