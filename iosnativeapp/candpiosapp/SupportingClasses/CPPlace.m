#import "CPPlace.h"
#import <CoreLocation/CoreLocation.h>

@implementation CPPlace

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
@synthesize lat = _lat;
@synthesize lng = _lng;
@synthesize othersHere = _othersHere;
@synthesize distanceFromUser = _distanceFromUser;
@synthesize checkinCount = _checkinCount;
@synthesize weeklyCheckinCount = _weeklyCheckinCount;
@synthesize monthlyCheckinCount = _monthlyCheckinCount;


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

// override the getter for othersHere so it just intelligently calculates the value
// based on the checkinCount and wether this user is also there
-(int)othersHere
{
    return [CPAppDelegate userCheckedIn] && [self.foursquareID isEqualToString:DEFAULTS(object, kUDCheckedInVenueID)] ? self.checkinCount - 1 : self.checkinCount;
}

// this method is used in CheckInListTableViewController to sort the array of places
// by the distance of each place from the user
// might be a faster way to accomplish this (sorting while inserting the foursquare returned
// data) but this seems to be quite quick anyways, as we aren't displaying a ton of places
- (NSComparisonResult)sortByDistanceToUser:(CPPlace *)place
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

@end
