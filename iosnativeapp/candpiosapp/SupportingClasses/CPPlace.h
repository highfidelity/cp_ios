#import <Foundation/Foundation.h>

@interface CPPlace : NSObject {
    NSString *name;
    NSString *icon;
    NSString *foursquareID;
    NSString *address;
    NSString *city;
    NSString *state;
    NSString *zip;
    CGFloat lat;
    CGFloat lng;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *icon;
@property (nonatomic, retain) NSString *foursquareID;
@property (nonatomic, retain) NSString *address;
@property (nonatomic, retain) NSString *city;
@property (nonatomic, retain) NSString *state;
@property (nonatomic, retain) NSString *zip;
@property (nonatomic) CGFloat lat;
@property (nonatomic) CGFloat lng;

@end
