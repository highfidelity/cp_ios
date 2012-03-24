//
//  UserListTableViewController.h
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPUtils.h"

@interface UserListTableViewController : UITableViewController {
@private
    BOOL venueList;
}

@property (nonatomic, retain) NSMutableArray *venues;
@property (nonatomic, retain) NSMutableArray *missions;
@property (nonatomic, retain) NSMutableArray *checkedInMissions;
@property (nonatomic, copy) NSString *titleForList;
@property (nonatomic) NSInteger listType;
@property (nonatomic, retain) NSString *currentVenue;
@property (nonatomic) MKMapRect mapBounds;

- (IBAction)peopleButtonClick:(UIButton *)sender;
- (IBAction)placesButtonClick:(UIButton *)sender;

@end
