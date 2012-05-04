//
//  ContactListViewController.h
//  candpiosapp
//
//  Created by Fredrik Enestad on 2012-03-19.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactListViewController : UITableViewController <UISearchBarDelegate>

@property (nonatomic, retain) NSArray *contacts;
@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;

@end
