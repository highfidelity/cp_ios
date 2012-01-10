#import <Foundation/Foundation.h>

@interface CPPlace : NSObject {
    NSString *name;
    NSString *icon;
    NSString *foursquareID;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *icon;
@property (nonatomic, retain) NSString *foursquareID;

@end
