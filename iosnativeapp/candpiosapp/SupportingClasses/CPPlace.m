#import "CPPlace.h"
#import "AppDelegate.h"
#import "LocalizedDistanceCalculator.h"
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
@synthesize distanceFromUser = _distanceFromUser;

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

@end
