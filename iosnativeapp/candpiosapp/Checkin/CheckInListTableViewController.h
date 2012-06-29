//
//  CheckInListTableViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 2/17/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.

#import <UIKit/UIKit.h>

@interface CheckInListTableViewController : UITableViewController <UIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic, assign) id delegate;
@property (nonatomic, strong) NSMutableArray *places;

- (void)refreshLocations;

@end
