#import <Foundation/Foundation.h>

@interface CPPlace : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) NSString *foursquareID;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *state;
@property (nonatomic, strong) NSString *zip;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, assign) double lat;
@property (nonatomic, assign) double lng;
@property (nonatomic, assign) int othersHere;
@property (nonatomic, assign) double distanceFromUser;
@property (nonatomic) int checkinCount;
@property (nonatomic, readonly) NSString *formattedAddress;

- (NSComparisonResult)sortByDistanceToUser:(CPPlace *)place;

@end
