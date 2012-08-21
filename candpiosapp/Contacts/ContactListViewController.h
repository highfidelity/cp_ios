//
//  ContactListViewController.h
//  candpiosapp
//
//  Created by Fredrik Enestad on 2012-03-19.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ContactListCell.h"
#import "CPBaseTableViewController.h"

#define kNumberOfContactRequestsNotification @"kNumberOfContactRequestsNotification"

@interface ContactListViewController : CPBaseTableViewController <UISearchBarDelegate, ContactListCellDelegate>

@property (strong, nonatomic) NSMutableArray *contacts;
@property (strong, nonatomic) NSMutableArray *contactRequests;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end
