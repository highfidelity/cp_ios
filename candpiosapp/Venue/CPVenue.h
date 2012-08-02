//
//  CPPlace.h
//  candpiosapp
//
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface CPVenue : NSObject <MKAnnotation, NSCoding>

@property (nonatomic, assign) int venueID;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *foursquareID;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *zip;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *formattedPhone;
@property (nonatomic, strong) NSString *photoURL;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) double distanceFromUser;
@property (nonatomic) int checkinCount;
@property (nonatomic) int checkinTime;
@property (nonatomic, assign) int weeklyCheckinCount;
@property (nonatomic, assign) int intervalCheckinCount;
@property (nonatomic, readonly) NSString *checkinCountString;
@property (nonatomic, readonly) NSString *checkinTimeString;
@property (nonatomic, readonly) NSString *formattedAddress;
@property (nonatomic, strong) NSMutableDictionary *activeUsers;
@property (nonatomic, assign) bool hasContactAtVenue;
@property (nonatomic, assign) bool autoCheckin;
@property (nonatomic, strong) NSString *specialVenueType;
@property (nonatomic) NSUInteger postsCount;

- (CPVenue *)initFromDictionary:(NSDictionary *)json;
- (NSComparisonResult)sortByDistanceToUser:(CPVenue *)place;

@end
