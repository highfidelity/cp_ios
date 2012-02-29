//
//  CandPAnnotation.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPAnnotation.h"

@implementation CPAnnotation
@synthesize lat,lon;
@synthesize title, subtitle, imageUrl;
@synthesize objectId;
@synthesize checkedIn;
@synthesize checkinId;
@synthesize _groupTag;
@synthesize nickname, status, skills, userId, distance, distanceTo, haveMet;

-(id)initFromDictionary:(NSDictionary*)jsonDict
{
	self=[super init];
	if(self)
	{
        userId = [[jsonDict objectForKey:@"id"] integerValue];
        nickname = [jsonDict objectForKey:@"nickname"];
		skills = [jsonDict objectForKey:@"skills"];
        status = [jsonDict objectForKey:@"status_text"];
        if (status && [status length] > 0) {
            self.subtitle = [NSString stringWithFormat:@"\"%@\"", status];
        } else {
            if(skills && ((NSNull*)skills != [NSNull null])) {
                self.subtitle = skills;
            }            
        }
        if ([[jsonDict objectForKey:@"met"] isEqualToNumber:[NSNumber numberWithInt:1]]) {
            haveMet = YES;
        } else {
            haveMet = NO;
        }
        
		lat = [[jsonDict objectForKey:@"lat"]doubleValue];
		lon = [[jsonDict objectForKey:@"lng"] doubleValue];
		objectId = [[jsonDict objectForKey:@"id"] copy];
		checkedIn = [[jsonDict objectForKey:@"checked_in"] boolValue];
        checkinId = [[jsonDict objectForKey:@"checkin_id"] intValue];
		id imageUrlObj = [jsonDict objectForKey:@"filename"];
		if(imageUrlObj && imageUrlObj != [NSNull null])
			imageUrl = [imageUrlObj copy];
        
        id foursquareObj = [jsonDict objectForKey:@"foursquare"];
        if (foursquareObj && foursquareObj != [NSNull null] && ![foursquareObj isEqualToString:@"0"]) {
            _groupTag = foursquareObj;
            self.title = foursquareObj;
        }

        if (!self.title) {
            self.title = @"Venue Name";
        }
        
        if (checkedIn) {
            subtitle = @"1 person here now";
        }
        else {
            subtitle = @"1 checkin in the last week";
        }


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

- (BOOL)isEqualToUserAnnotation:(CPAnnotation *)annotation {
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
