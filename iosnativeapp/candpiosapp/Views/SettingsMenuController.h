//
//  SettingsMenuController.h
//  candpiosapp
//
//  Created by Andrew Hammond on 2/23/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapTabController.h"

@interface SettingsMenuController : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIViewController *frontViewController;
@property (strong, nonatomic) MapTabController *mapTabController;
@property (nonatomic) BOOL isMenuShowing;
@property (weak, nonatomic) IBOutlet UIImageView *edgeShadow;

- (void)showMenu:(BOOL)shouldReveal;
- (void)closeMenu;

@end
