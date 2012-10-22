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
    
}

+ (RKObjectMapping *)venueRKObjectMapping
{
    static RKObjectMapping *_venueRKObjectMapping;
    
    if (!_venueRKObjectMapping) {
        _venueRKObjectMapping = [RKObjectMapping mappingForClass:[CPVenue class]];
        [_venueRKObjectMapping mapAttributes:@"name", @"address", nil];
        [_venueRKObjectMapping mapKeyPath:@"id" toAttribute:@"venueID"];
        [_venueRKObjectMapping mapKeyPath:@"foursquare_id" toAttribute:@"foursquareID"];
        [_venueRKObjectMapping mapKeyPath:@"photo_url" toAttribute:@"photoURL"];
    }
    
    return _venueRKObjectMapping;
}

@end
