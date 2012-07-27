//
//  CPPlace.h
//  candpiosapp
//
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface CPVenue : NSObject <MKAnnotation, NSCoding>

@property int venueID;
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
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property double distanceFromUser;
@property int checkinCount;
@property int checkinTime;
@property int weeklyCheckinCount;
@property int intervalCheckinCount;
@property (nonatomic, readonly) NSString *checkinCountString;
@property (nonatomic, readonly) NSString *checkinTimeString;
@property (nonatomic, readonly) NSString *formattedAddress;
@property (strong, nonatomic) NSMutableDictionary *activeUsers;
@property BOOL hasContactAtVenue;
@property BOOL autoCheckin;
@property (strong, nonatomic) NSString *specialVenueType;

- (CPVenue *)initFromDictionary:(NSDictionary *)json;
- (NSComparisonResult)sortByDistanceToUser:(CPVenue *)place;

@end
