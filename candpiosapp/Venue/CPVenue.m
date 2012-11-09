//
//  CPVenue.m
//  candpiosapp
//
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPVenue.h"
#import <CoreLocation/CoreLocation.h>
#import "VenueInfoViewController.h"
#import "NSDictionary+JsonParserWorkaround.h"
#import "FoursquareAPIClient.h"

@implementation CPVenue


- (CPVenue *)initFromDictionary:(NSDictionary *)json
{
    self = [super init];
    if (self) {
        self.venueID = [json numberForKey:@"venue_id" orDefault:@0];
        self.name = [json objectForKey:@"name" orDefault:@""];
        self.address = [json objectForKey:@"address" orDefault:@""];
        self.city = [json objectForKey:@"city" orDefault:@""];
        self.state = [json objectForKey:@"state" orDefault:@""];
        self.phone = [json objectForKey:@"phone" orDefault:@""];
        self.formattedPhone = [json objectForKey:@"formatted_phone" orDefault:@""];
        self.distanceFromUser = [[json objectForKey:@"distance" orDefault:[NSNumber numberWithDouble:0]] doubleValue];
        self.foursquareID = [json objectForKey:@"foursquare_id" orDefault:@""];
        self.checkedInNow = [json numberForKey:@"checked_in_now" orDefault:@0];
        self.photoURL = [json objectForKey:@"photo_url" orDefault:nil];
        self.specialVenueType = [json objectForKey:@"special_venue_type" orDefault:nil];
        self.isNeighborhood = @([[json objectForKey:@"is_neighborhood"] boolValue]);

        self.lat = [json numberForKey:@"lat" orDefault:@0];
        self.lng = [json numberForKey:@"lng" orDefault:@0];
    }
    return self;
}

- (CPVenue *)initFromFoursquareDictionary:(NSDictionary *)json userLocation:(CLLocation *)userLocation
{
    if (self = [super init]) {
        self.name = [json valueForKey:@"name"];
        self.foursquareID = [json valueForKey:@"id"];
        self.address = [[json valueForKey:@"location"] valueForKey:@"address"];
        self.city = [[json valueForKey:@"location"] valueForKey:@"city"];
        self.state = [[json valueForKey:@"location"] valueForKey:@"state"];
        self.zip = [[json valueForKey:@"location"] valueForKey:@"postalCode"];
        self.lat = [[json valueForKey:@"location"] numberForKey:@"lat" orDefault:@0];
        self.lng = [[json valueForKey:@"location"] numberForKey:@"lng" orDefault:@0];
        self.phone = [[json valueForKey:@"contact"] valueForKey:@"phone"];
        self.formattedPhone = [json valueForKeyPath:@"contact.formattedPhone"];
        
        // check if this venue is considered a neighborhood
        for (NSDictionary *categoryDict in [json valueForKey:@"categories"]) {
            if (self.isNeighborhood = @([[categoryDict objectForKey:@"id"] isEqualToString:kFoursquareNeighborhoodCategoryID])) {
                break;
            }
        }
        
        // if it's not a neighborhood then we need to set the distanceFromUser property
        if (![self.isNeighborhood boolValue]) {
            
            CLLocation *placeLocation = [[CLLocation alloc] initWithLatitude:self.coordinate.latitude longitude:self.coordinate.longitude];
            self.distanceFromUser = [placeLocation distanceFromLocation:userLocation];
        }
    }
    
    return self;
}

-(id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self)
    {
        self.name = [decoder decodeObjectForKey:@"name"];
        self.foursquareID = [decoder decodeObjectForKey:@"foursquareID"];
        
        // temporary handling of venues stored with venueID as integer
        @try {
            self.venueID = [decoder decodeObjectOfClass:[NSNumber class] forKey:@"venueID"];
        }
        @catch (NSException *exception) {
            self.venueID = [NSNumber numberWithInt:[decoder decodeIntForKey:@"venueID"]];
        }
        
        self.lat = [decoder decodeObjectForKey:@"lat"];
        self.lng = [decoder decodeObjectForKey:@"lng"];
        self.address = [decoder decodeObjectForKey:@"address"];
        self.phone = [decoder decodeObjectForKey:@"phone"];
        self.photoURL = [decoder decodeObjectForKey:@"photoURL"];
        self.checkinTime = [decoder decodeIntegerForKey:@"checkinTime"];
        self.autoCheckin = [[decoder decodeObjectForKey:@"autoCheckin"] boolValue];
        self.specialVenueType = [decoder decodeObjectForKey:@"specialVenueType"];
    }
    return self;
}

-(void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.name forKey:@"name"];
    [encoder encodeObject:self.foursquareID forKey:@"foursquareID"];
    [encoder encodeObject:self.venueID forKey:@"venueID"];
    [encoder encodeObject:self.lat forKey:@"lat"];
    [encoder encodeObject:self.lng forKey:@"lng"];
    [encoder encodeObject:self.address forKey:@"address"];
    [encoder encodeObject:self.phone forKey:@"phone"];
    [encoder encodeObject:self.photoURL forKey:@"photoURL"];
    [encoder encodeInt:self.checkinTime forKey:@"checkinTime"];
    [encoder encodeObject:[NSNumber numberWithBool:self.autoCheckin] forKey:@"autoCheckin"];
    [encoder encodeObject:self.specialVenueType forKey:@"specialVenueType"];
}

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

- (void)setName:(NSString *)name
{
    if (![name isKindOfClass:[NSNull class]]) {
        _name = name;
    } else {
        _name = @"";
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

- (void)setSpecialVenueType:(NSString *)specialVenueType
{
    if (![specialVenueType isKindOfClass:[NSNull class]]) {
        _specialVenueType = specialVenueType;
    } else {
        _specialVenueType = nil;
    }
}

- (CLLocationCoordinate2D)coordinate
{
    return CLLocationCoordinate2DMake([self.lat doubleValue], [self.lng doubleValue]);
}

// this method is used in CheckInListViewController to sort the array of places
// by the distance of each place from the user
// might be a faster way to accomplish this (sorting while inserting the foursquare returned
// data) but this seems to be quite quick anyways, as we aren't displaying a ton of places
- (NSComparisonResult)sortByNeighborhoodAndDistanceToUser:(CPVenue *)place
{
    if ([self.isNeighborhood boolValue] && ![place.isNeighborhood boolValue]) {
        return NSOrderedAscending;
    } else if (![self.isNeighborhood boolValue] && [place.isNeighborhood boolValue]) {
        return NSOrderedDescending;
    } if (self.distanceFromUser < place.distanceFromUser) {
        return NSOrderedAscending;
    } else if (self.distanceFromUser > place.distanceFromUser) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSString *)checkinCountString {
    if ([self.checkedInNow intValue] == 1) {
        return @"1 checkin";
    }
    
    return [NSString stringWithFormat:@"%@ checkins", self.checkedInNow];
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
    if ([self.checkedInNow intValue] > 0) {
        subtitleString = [NSString stringWithFormat:@"%@ %@ here now",
                                                    self.checkedInNow,
                                                    [self.checkedInNow intValue] > 1 ? @"people" : @"person"];
    } else {
        subtitleString = [NSString stringWithFormat:@"%@ %@ in the last week",
                                                    self.weeklyCheckinCount,
                                                    [self.weeklyCheckinCount intValue] > 1 ? @"people" : @"person"];
    }
    return subtitleString;
}

-(BOOL)isEqual:(id)object
{
    if (self == object) {
        return YES;
    } else if (![object isKindOfClass:[self class]]) {
        return NO;
    } else if ([self.venueID isEqualToNumber:[object venueID]]) {
        return YES;
    } else {
        return NO;
    }
}

@end
