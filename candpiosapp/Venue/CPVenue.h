//
//  CPPlace.h
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
@property (strong, nonatomic) NSString *utc;
@property (strong, nonatomic) NSString *phone;
@property (strong, nonatomic) NSString *formattedPhone;
@property (strong, nonatomic) NSString *photoURL;
@property (strong, nonatomic) NSMutableDictionary *activeUsers;
@property (strong, nonatomic) NSString *specialVenueType;
@property (nonatomic) int venueID;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) double distanceFromUser;
@property (nonatomic) int checkinCount;
@property (nonatomic) int checkinTime;
@property (nonatomic) int weeklyCheckinCount;
@property (nonatomic) int intervalCheckinCount;
@property (nonatomic) int virtualCheckinCount;
@property (nonatomic) BOOL hasContactAtVenue;
@property (nonatomic) BOOL autoCheckin;
@property (nonatomic) BOOL isNeighborhood;
@property (nonatomic, readonly) NSString *checkinCountString;
@property (nonatomic, readonly) NSString *checkinTimeString;
@property (nonatomic, readonly) NSString *formattedAddress;


- (CPVenue *)initFromDictionary:(NSDictionary *)json;
- (CPVenue *)initFromFoursquareDictionary:(NSDictionary *)json userLocation:(CLLocation *)userLocation;
- (NSComparisonResult)sortByNeighborhoodAndDistanceToUser:(CPVenue *)place;

@end
