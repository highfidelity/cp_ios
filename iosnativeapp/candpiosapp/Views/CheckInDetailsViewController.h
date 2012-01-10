#import <UIKit/UIKit.h>
#import "CPPlace.h"

@interface CheckInDetailsViewController : UIViewController {
    UISlider *slider;
    CPPlace *place;
}

@property (nonatomic, retain) UISlider *slider;
@property (nonatomic, retain) CPPlace *place;

@end
