//
//  LogVenuesTableViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 7/3/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPBaseTableViewController.h"

@interface FeedVenuesTableViewController : CPBaseTableViewController

@property (nonatomic, strong) NSMutableArray *venues;

- (void)reloadDefaultVenues;

@end
