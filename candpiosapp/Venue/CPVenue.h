//
//  CPPlace.h
//  candpiosapp
//
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface CPVenue : NSObject <MKAnnotation, NSCoding>

@property (nonatomic, assign) int venueID;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *icon;
@property (strong, nonatomic) NSString *foursquareID;
@property (strong, nonatomic) NSString *address;
@property (strong, nonatomic) NSString *city;
@property (strong, nonatomic) NSString *state;
@property (strong, nonatomic) NSString *zip;
@property (strong, nonatomic) NSString *phone;
@property (strong, nonatomic) NSString *formattedPhone;
@property (strong, nonatomic) NSString *photoURL;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) double distanceFromUser;
@property (nonatomic) int checkinCount;
@property (nonatomic) int checkinTime;
@property (nonatomic, assign) int weeklyCheckinCount;
@property (nonatomic, assign) int intervalCheckinCount;
@property (nonatomic, readonly) NSString *checkinCountString;
@property (nonatomic, readonly) NSString *checkinTimeString;
@property (nonatomic, readonly) NSString *formattedAddress;
@property (strong, nonatomic) NSMutableDictionary *activeUsers;
@property (nonatomic, assign) bool hasContactAtVenue;
@property (nonatomic, assign) bool autoCheckin;
@property (strong, nonatomic) NSString *specialVenueType;

- (CPVenue *)initFromDictionary:(NSDictionary *)json;
- (NSComparisonResult)sortByDistanceToUser:(CPVenue *)place;

@end
