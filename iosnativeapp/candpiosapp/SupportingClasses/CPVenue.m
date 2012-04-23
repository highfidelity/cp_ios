//
//  CPPlace.m
//  candpiosapp
//
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPVenue.h"
#import <CoreLocation/CoreLocation.h>
#import "VenueInfoViewController.h"

@implementation CPVenue

@synthesize venueID = _venueID;
@synthesize name = _name;
@synthesize icon = _icon;
@synthesize foursquareID = _foursquareID;
@synthesize address = _address;
@synthesize city = _city;
@synthesize state = _state;
@synthesize zip = _zip;
@synthesize formattedPhone = _formattedPhone;
@synthesize phone = _phone;
@synthesize photoURL = _photoURL;
@synthesize distanceFromUser = _distanceFromUser;
@synthesize checkinCount = _checkinCount;
@synthesize weeklyCheckinCount = _weeklyCheckinCount;
@synthesize intervalCheckinCount = _monthlyCheckinCount;
@synthesize coordinate = _coordinate;
@synthesize activeUsers = _activeUsers;

// override setters here to that when we parse JSON to set values we don't set things to null


// TODO: find out if there is a JSON parser that will just set these values to nil or empty strings so we don't have to do this everywhere
- (void)setAddress:(NSString *)address
{
    if (![address isKindOfClass:[NSNull class]]) {
        _address = address;
    } else {
        _address = @"";
    }
}

- (void)setCity:(NSString *)city
{
    if (![city isKindOfClass:[NSNull class]]) {
        _city = city;
    } else {
        _city = @"";
    }
}

- (void)setState:(NSString *)state
{
    if (![state isKindOfClass:[NSNull class]]) {
        _state = state;
    } else {
        _state = @"";
    }
}

- (void)setZip:(NSString *)zip
{
    if (![zip isKindOfClass:[NSNull class]]) {
        _zip = zip;
    } else {
        _zip = @"";
    }
}

- (void)setPhone:(NSString *)phone
{
    if (![phone isKindOfClass:[NSNull class]]) {
        _phone = phone;
    } else {
        _phone = @"";
    }
}

- (void)setFormattedPhone:(NSString *)formattedPhone
{
    if (![formattedPhone isKindOfClass:[NSNull class]]) {
        _formattedPhone = formattedPhone;
    } else {
        _formattedPhone = @"";
    }
}

- (void)setPhotoURL:(NSString *)photoURL
{
    if (![photoURL isKindOfClass:[NSNull class]]) {
        _photoURL = photoURL;
    } else {
        _photoURL = nil;
    }
    
}

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
        self.venueID = [[json objectForKey:@"venue_id"] intValue];
        self.name = [json objectForKey:@"name"];
        self.address = [json objectForKey:@"address"];
        self.city = [json objectForKey:@"city"];
        self.state = [json objectForKey:@"state"];
        self.phone = [json objectForKey:@"phone"];
        self.formattedPhone = [json objectForKey:@"formatted_phone"];
        self.distanceFromUser = [[json objectForKey:@"distance"] doubleValue];
        self.foursquareID = [json objectForKey:@"foursquare_id"];
        self.checkinCount = [[json objectForKey:@"checkins"] integerValue];
        self.weeklyCheckinCount = [[json objectForKey:@"checkins_for_week"] integerValue];
        self.intervalCheckinCount = [[json objectForKey:@"checkins_for_interval"] integerValue];
        self.photoURL = [json objectForKey:@"photo_url"];
        
        self.coordinate = CLLocationCoordinate2DMake([[json objectForKey:@"lat"] doubleValue], [[json objectForKey:@"lng"] doubleValue]);
        
        self.activeUsers = [json objectForKey:@"users"];               
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
        subtitleString = [NSString stringWithFormat:@"%d %@ in the last week", self.weeklyCheckinCount, self.weeklyCheckinCount > 1 ? @"checkins" : @"checkin"];
    }
    return subtitleString;
}

-(NSDictionary *)initializationDictionaryJSON {
    NSMutableDictionary *json = [NSMutableDictionary dictionaryWithCapacity:15];
    
    if (self.name) { [json setObject:self.name forKey:@"name"]; }
    if (self.address) { [json setObject:self.address forKey:@"address"]; }
    if (self.city) { [json setObject:self.city forKey:@"city"]; }
    if (self.state) { [json setObject:self.state forKey:@"state"]; }
    if (self.phone) { [json setObject:self.phone forKey:@"phone"]; }
    if (self.formattedPhone) { [json setObject:self.formattedPhone forKey:@"formatted_phone"]; }
    [json setObject:[NSNumber numberWithDouble:self.distanceFromUser] forKey:@"distance"];
    if (self.foursquareID) { [json setObject:self.foursquareID forKey:@"foursquare_id"]; }
    [json setObject:[NSNumber numberWithInteger:self.checkinCount] forKey:@"checkins"];
    [json setObject:[NSNumber numberWithInteger:self.weeklyCheckinCount] forKey:@"checkins_for_week"];
    [json setObject:[NSNumber numberWithInteger:self.intervalCheckinCount] forKey:@"checkins_for_interval"];
    if (self.photoURL) { [json setObject:self.photoURL forKey:@"photo_url"]; }
    [json setObject:[NSNumber numberWithDouble:self.coordinate.latitude] forKey:@"lat"];
    [json setObject:[NSNumber numberWithDouble:self.coordinate.longitude] forKey:@"lng"];
    if (self.activeUsers) { [json setObject:self.activeUsers forKey:@"users"]; }
    
    return json;
}

@end
