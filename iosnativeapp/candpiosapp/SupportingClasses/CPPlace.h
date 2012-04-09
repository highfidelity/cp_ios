//
//  CPPlace.h
//  candpiosapp
//
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface CPPlace : NSObject <MKAnnotation>

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
@property (nonatomic, assign) double lat;
@property (nonatomic, assign) double lng;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, assign) double distanceFromUser;
@property (nonatomic) int checkinCount;
@property (nonatomic, assign) int weeklyCheckinCount;
@property (nonatomic, assign) int intervalCheckinCount;
@property (nonatomic, readonly) NSString *checkinCountString;
@property (nonatomic, readonly) NSString *formattedAddress;
@property (nonatomic, strong) NSMutableDictionary *activeUsers;

// TODO: kill the lat and lng properties and merge with coordinate

- (CPPlace *)initFromDictionary:(NSDictionary *)json;
- (NSComparisonResult)sortByDistanceToUser:(CPPlace *)place;

@end
