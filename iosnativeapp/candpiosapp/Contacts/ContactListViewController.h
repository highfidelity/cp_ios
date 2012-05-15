//
//  ContactListViewController.h
//  candpiosapp
//
//  Created by Fredrik Enestad on 2012-03-19.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "UserTableViewCell.h"

@interface ContactListViewController : UITableViewController <UISearchBarDelegate, UserTableViewCellDelegate>

@property (nonatomic, copy) NSArray *contacts;
@property (nonatomic, copy) NSArray *contactRequests;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;

@end
