//
//  LogViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LogViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, assign) IBOutlet UITableView *tableView;
@property (nonatomic, assign) BOOL newLogEntryAfterLoad;

- (void)newLogEntry;
- (void)setSelectedVenue:(CPVenue *)selectedVenue;

@end
