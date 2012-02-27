#import "CPPlace.h"
#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>

@implementation CPPlace

@synthesize name = _name;
@synthesize icon = _icon;
@synthesize foursquareID = _foursquareID;
@synthesize address = _address;
@synthesize city = _city;
@synthesize state = _state;
@synthesize zip = _zip;
@synthesize lat = _lat;
@synthesize lng = _lng;
@synthesize othersHere = _othersHere;

// this method is used in CheckInListTableViewController to sort the array of places
// by the distance of each place from the user
// might be a faster way to accomplish this (sorting while inserting the foursquare returned
// data) but this seems to be quite quick anyways, as we aren't display a ton of places
- (NSComparisonResult)sortByDistanceToUser:(CPPlace *)place
{
    CLLocation *locationA = [[CLLocation alloc] initWithLatitude:self.lat longitude:self.lng];
    CLLocation *locationB = [[CLLocation alloc] initWithLatitude:place.lat longitude:place.lng];
    CLLocation *userLocation = [[AppDelegate instance].settings lastKnownLocation];
    
    double distanceA = [locationA distanceFromLocation:userLocation];
    double distanceB = [locationB distanceFromLocation:userLocation];
    
    if (distanceA < distanceB) {
        return NSOrderedAscending;
    } else if (distanceA > distanceB) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

@end
