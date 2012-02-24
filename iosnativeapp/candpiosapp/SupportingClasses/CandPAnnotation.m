//
//  CandPAnnotation.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CandPAnnotation.h"

@implementation CandPAnnotation
@synthesize lat,lon;
@synthesize title, subtitle, imageUrl;
@synthesize objectId;
@synthesize checkedIn;
@synthesize checkinId;
@synthesize _groupTag;

-(id)initFromDictionary:(NSDictionary*)jsonDict
{
	self=[super init];
	if(self)
	{
		lat = [[jsonDict objectForKey:@"lat"]doubleValue];
		lon = [[jsonDict objectForKey:@"lng"] doubleValue];
		objectId = [[jsonDict objectForKey:@"id"] copy];
		checkedIn = [[jsonDict objectForKey:@"checked_in"] boolValue];
        checkinId = [[jsonDict objectForKey:@"checkin_id"] intValue];
		id imageUrlObj = [jsonDict objectForKey:@"filename"];
		if(imageUrlObj && imageUrlObj != [NSNull null])
			imageUrl = [imageUrlObj copy];
        
        id foursquareObj = [jsonDict objectForKey:@"foursquare"];
        if (foursquareObj && foursquareObj != [NSNull null] && ![foursquareObj isEqualToString:@"0"])
            _groupTag = foursquareObj;
	}
	return self;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;   
    }
    if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    }
    return [self isEqualToUserAnnotation: other];
}

- (BOOL)isEqualToUserAnnotation:(CandPAnnotation *)annotation {
    if (self == annotation) {
        return YES;
    }
    
    if ([self checkinId] == [annotation checkinId] && [self checkedIn] == [annotation checkedIn]) {
        return YES;        
    }  
    return NO;
}

// for MKAnnotation protocol
// @property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
//
-(CLLocationCoordinate2D) coordinate
{
	return CLLocationCoordinate2DMake(lat, lon);
}

- (NSString *)groupTag{
    return _groupTag;
}

- (void)setGroupTag:(NSString *)tag{
    _groupTag = tag;
}


@end
