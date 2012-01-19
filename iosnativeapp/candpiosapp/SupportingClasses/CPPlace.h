#import <Foundation/Foundation.h>

@interface CPPlace : NSObject {
    NSString *name;
    NSString *icon;
    NSString *foursquareID;
    CGFloat lat;
    CGFloat lng;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *icon;
@property (nonatomic, retain) NSString *foursquareID;
@property (nonatomic) CGFloat lat;
@property (nonatomic) CGFloat lng;

@end
