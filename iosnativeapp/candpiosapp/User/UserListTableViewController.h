//
//  UserListTableViewController.h
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserListTableViewController : UITableViewController <UINavigationControllerDelegate> 

@property (nonatomic, retain) NSMutableArray *weeklyUsers;
@property (nonatomic, retain) NSMutableArray *checkedInUsers;
@property (nonatomic, assign) MapTabController *delegate;

- (void)refreshFromNewMapData:(NSNotification *)notification;

@end
