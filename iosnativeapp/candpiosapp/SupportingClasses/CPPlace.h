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
@property (nonatomic, strong) NSString *formattedPhone;
@property (nonatomic, strong) NSString *photoURL;
@property (nonatomic, assign) double lat;
@property (nonatomic, assign) double lng;
@property (nonatomic, readonly) int othersHere;
@property (nonatomic, assign) double distanceFromUser;
@property (nonatomic) int checkinCount;
@property (nonatomic, assign) int weeklyCheckinCount;
@property (nonatomic, assign) int monthlyCheckinCount;
@property (nonatomic, readonly) NSString *checkinCountString;
@property (nonatomic, readonly) NSString *formattedAddress;

- (NSComparisonResult)sortByDistanceToUser:(CPPlace *)place;

@end
