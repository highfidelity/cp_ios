//
//  VenuesTableViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 4/2/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VenueListTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *venues;
@property (nonatomic, assign) MapTabController *delegate;

@end
