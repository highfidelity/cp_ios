#import <UIKit/UIKit.h>
#import "MapKit/MapKit.h"
#import "CPPlace.h"

@interface CheckInDetailsViewController : UITableViewController <UITextFieldDelegate, MKMapViewDelegate> {
    UISlider *slider;
    CPPlace *place;
}

@property (nonatomic, retain) UISlider *slider;
@property (nonatomic, retain) CPPlace *place;

@end
