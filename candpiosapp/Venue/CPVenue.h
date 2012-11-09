//
//  CPVenue.h
//  candpiosapp
//
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface CPVenue : NSObject <MKAnnotation, NSCoding>

@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *foursquareID;
@property (strong, nonatomic) NSString *address;
@property (strong, nonatomic) NSString *city;
@property (strong, nonatomic) NSString *state;
@property (strong, nonatomic) NSString *zip;
@property (strong, nonatomic) NSString *phone;
@property (strong, nonatomic) NSString *formattedPhone;
@property (strong, nonatomic) NSString *photoURL;
@property (strong, nonatomic) NSArray *checkedInUsers;
@property (strong, nonatomic) NSArray *previousUsers;
@property (strong, nonatomic) NSString *specialVenueType;
@property (strong, nonatomic) NSNumber *venueID;
@property (strong, nonatomic) NSNumber *checkedInNow;
@property (strong, nonatomic) NSNumber *weeklyCheckinCount;
@property (strong, nonatomic) NSNumber *lat;
@property (strong, nonatomic) NSNumber *lng;
@property (strong, nonatomic) NSNumber *isNeighborhood;
@property (strong, nonatomic) NSNumber *hasCheckedInContacts;
@property (nonatomic) double distanceFromUser;
@property (nonatomic) int checkinTime;
@property (nonatomic) BOOL autoCheckin;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) NSString *checkinCountString;
@property (nonatomic, readonly) NSString *checkinTimeString;
@property (nonatomic, readonly) NSString *formattedAddress;


- (CPVenue *)initFromDictionary:(NSDictionary *)json;
- (CPVenue *)initFromFoursquareDictionary:(NSDictionary *)json userLocation:(CLLocation *)userLocation;
- (NSComparisonResult)sortByNeighborhoodAndDistanceToUser:(CPVenue *)place;

@end
