//
//  CPPlace.m
//  candpiosapp
//
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPVenue.h"
#import <CoreLocation/CoreLocation.h>
#import "VenueInfoViewController.h"
#import "NSDictionary+JsonParserWorkaround.h"

@implementation CPVenue


- (NSMutableDictionary *)activeUsers
{
    if (!_activeUsers) {
        _activeUsers = [NSMutableDictionary dictionary];
    }
    return _activeUsers;
}

- (CPVenue *)initFromDictionary:(NSDictionary *)json
{
    self = [super init];
    if (self) {
        self.venueID = [[json objectForKey:@"venue_id" orDefault:[NSNumber numberWithInt:0]] intValue];
        self.name = [json objectForKey:@"name" orDefault:@""];
        self.address = [json objectForKey:@"address" orDefault:@""];
        self.city = [json objectForKey:@"city" orDefault:@""];
        self.state = [json objectForKey:@"state" orDefault:@""];
        self.phone = [json objectForKey:@"phone" orDefault:@""];
        self.formattedPhone = [json objectForKey:@"formatted_phone" orDefault:@""];
        self.distanceFromUser = [[json objectForKey:@"distance" orDefault:[NSNumber numberWithDouble:0]] doubleValue];
        self.foursquareID = [json objectForKey:@"foursquare_id" orDefault:@""];
        self.checkinCount = [[json objectForKey:@"checkins" orDefault:[NSNumber numberWithInt:0]] intValue];
        self.weeklyCheckinCount = [[json objectForKey:@"checkins_for_week" orDefault:[NSNumber numberWithInt:0]] intValue];
        self.intervalCheckinCount = [[json objectForKey:@"checkins_for_interval" orDefault:[NSNumber numberWithInt:0]] intValue];
        self.virtualCheckinCount = [[json objectForKey:@"virtual_checkins" orDefault:[NSNumber numberWithInt:0]] intValue];
        self.photoURL = [json objectForKey:@"photo_url" orDefault:nil];
        self.specialVenueType = [json objectForKey:@"special_venue_type" orDefault:nil];
        self.postsCount = [[json objectForKey:@"posts_count" orDefault:[NSNumber numberWithUnsignedInteger:0]] unsignedIntValue];
        
        if ([json objectForKey:@"lat" orDefault:nil] && [json objectForKey:@"lng" orDefault:nil]) {
            self.coordinate = CLLocationCoordinate2DMake([[json objectForKey:@"lat"] doubleValue], [[json objectForKey:@"lng"] doubleValue]);
        }
        
        self.activeUsers = [json objectForKey:@"users"];
        self.utc = [json objectForKey:@"utc" orDefault:@""];
    }
    return self;
}

// this method is used in CheckInListTableViewController to sort the array of places
// by the distance of each place from the user
// might be a faster way to accomplish this (sorting while inserting the foursquare returned
// data) but this seems to be quite quick anyways, as we aren't displaying a ton of places
- (NSComparisonResult)sortByDistanceToUser:(CPVenue *)place
{
    if (self.distanceFromUser < place.distanceFromUser) {
        return NSOrderedAscending;
    } else if (self.distanceFromUser > place.distanceFromUser) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSString *)checkinCountString {
    if (1 == self.checkinCount) { 
        return @"1 checkin";
    }
    
    return [NSString stringWithFormat:@"%d checkins", self.checkinCount];
}

- (NSString *)checkinTimeString {
    if (1 == self.checkinTime / 3600) {
        return @"1 hr";
    }
    
    return [NSString stringWithFormat:@"%d hrs", self.checkinTime / 3600];
}

- (NSString*) formattedAddress {
    // format the address from available address components
    NSMutableArray *addressComponents = [NSMutableArray array];
    if (self.address && self.address.length > 0) { 
        [addressComponents addObject:self.address];
    }
    if (self.city && self.city.length > 0) { 
        [addressComponents addObject:self.city];
    }
    if (self.state && self.state.length > 0) {
        [addressComponents addObject:self.state];
    }
    return [addressComponents componentsJoinedByString:@", "];
}

// title method implemented for MKAnnotation protocol
- (NSString *)title {
    return self.name;
}

- (NSString *)subtitle {
    NSString *subtitleString;
    if (self.checkinCount > 0) {
        subtitleString = [NSString stringWithFormat:@"%d %@ here now", self.checkinCount, self.checkinCount > 1 ? @"people" : @"person"];
    } else {
        subtitleString = [NSString stringWithFormat:@"%d %@ in the last week", self.weeklyCheckinCount, self.weeklyCheckinCount > 1 ? @"people" : @"person"];
    }
    return subtitleString;
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) 
    {
        self.name = [decoder decodeObjectForKey:@"name"];
        self.foursquareID = [decoder decodeObjectForKey:@"foursquareID"];
        self.venueID = [decoder decodeIntegerForKey:@"venueID"];
        self.coordinate = CLLocationCoordinate2DMake([[decoder decodeObjectForKey:@"lat"] doubleValue], [[decoder decodeObjectForKey:@"lng"] doubleValue]);
        self.address = [decoder decodeObjectForKey:@"address"];
        self.phone = [decoder decodeObjectForKey:@"phone"];
        self.photoURL = [decoder decodeObjectForKey:@"photoURL"];
        self.checkinTime = [decoder decodeIntegerForKey:@"checkinTime"];
        self.autoCheckin = [[decoder decodeObjectForKey:@"autoCheckin"] boolValue];
        self.specialVenueType = [decoder decodeObjectForKey:@"specialVenueType"];
        self.utc = [decoder decodeObjectForKey:@"utc"];
    }    
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.foursquareID forKey:@"foursquareID"];
    [encoder encodeInt:self.venueID forKey:@"venueID"];
    [encoder encodeObject:[NSNumber numberWithDouble:self.coordinate.latitude] forKey:@"lat"];
    [encoder encodeObject:[NSNumber numberWithDouble:self.coordinate.longitude] forKey:@"lng"];
    [encoder encodeObject:self.address forKey:@"address"];
    [encoder encodeObject:self.phone forKey:@"phone"];
    [encoder encodeObject:self.photoURL forKey:@"photoURL"];
    [encoder encodeInt:self.checkinTime forKey:@"checkinTime"];
    [encoder encodeObject:[NSNumber numberWithBool:self.autoCheckin] forKey:@"autoCheckin"];
    [encoder encodeObject:self.specialVenueType forKey:@"specialVenueType"];
    [encoder encodeObject:self.utc forKey:@"utc"];
}

-(BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    } else if (![object isKindOfClass:[self class]]) {
        return NO;
    } else if (self.venueID == [object venueID]) {
        return YES;
    } else {
        return NO;
    }
}

@end
