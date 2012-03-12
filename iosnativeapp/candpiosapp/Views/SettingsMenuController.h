//
//  SettingsMenuController.h
//  candpiosapp
//
//  Created by Andrew Hammond on 2/23/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapTabController.h"

@interface SettingsMenuController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UIViewController *frontViewController;
@property (strong, nonatomic) MapTabController *mapTabController;
@property (nonatomic) BOOL isMenuShowing;
@property (weak, nonatomic) IBOutlet UIImageView *edgeShadow;

// the following properties are used to dismiss F2F alerts that don't need to still be showing once new ones come in
@property (nonatomic, strong) UIAlertView *f2fInviteAlert;
@property (nonatomic, strong) UIAlertView *f2fPasswordAlert;

@property (weak, nonatomic) IBOutlet UISwitch *citySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *venueSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *checkedInSwitch;

-(IBAction) switchValueChanged: (id)sender;

- (void)showMenu:(BOOL)shouldReveal;
- (void)closeMenu;

@end
