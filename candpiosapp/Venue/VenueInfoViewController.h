//
//  VenueInfoViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 3/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPVenue.h"
#import "CPUserActionCell.h"

@interface VenueInfoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, CPUserActionCellDelegate>

+ (VenueInfoViewController *)onScreenVenueVC;

@property (strong, nonatomic) CPVenue *venue;
@property (weak, nonatomic) IBOutlet UIImageView *venuePhoto;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableDictionary *categoryCount;
@property (strong, nonatomic) NSMutableDictionary *currentUsers;
@property (nonatomic) BOOL scrollToUserThumbnail;
@property (strong, nonatomic) NSArray *orderedPreviousUsers;
@property (strong, nonatomic) NSArray *orderedCategories;

@end
