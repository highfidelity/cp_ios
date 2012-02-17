//
//  UserListTableViewController.h
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocalizedDistanceCalculator.h"

@interface UserListTableViewController : UITableViewController {
    NSMutableArray *missions;
    NSArray *orderedMissions;
}

@property (nonatomic, retain) NSMutableArray *missions;
@property (nonatomic, retain) NSArray *orderedMissions;

@end
