//
//  UserListTableViewController.h
//  candpiosapp
//
//  Created by Emmanuel Crouvisier on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserListTableViewController : UITableViewController 

@property (nonatomic, retain) NSMutableArray *users;
@property (nonatomic, retain) NSMutableArray *checkedInUsers;
@property (nonatomic) NSInteger listType;
@property (nonatomic, retain) NSString *currentVenue;
@property (nonatomic) MKMapRect mapBounds;
@property (nonatomic, assign) id delegate;

- (void)refreshViewOnCheckin:(NSNotification *)notification;

@end
