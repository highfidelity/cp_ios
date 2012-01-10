#import <UIKit/UIKit.h>

@interface CheckInListTableViewController : UITableViewController {
    NSMutableArray *places;
}

@property (nonatomic, retain) NSMutableArray *places;
- (void)refreshLocations;

@end
