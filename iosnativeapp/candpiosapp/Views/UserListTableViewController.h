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
    NSMutableArray *missions;
    NSMutableArray *checkedInMission;
    NSString *titleForList;
    NSInteger listType;
    NSString *currentVenue;
}

@property (nonatomic, retain) NSMutableArray *missions;
@property (nonatomic, retain) NSMutableArray *checkedInMissions;
@property (nonatomic, copy) NSString *titleForList;
@property (nonatomic) NSInteger listType;
@property (nonatomic, retain) NSString *currentVenue;

@end
