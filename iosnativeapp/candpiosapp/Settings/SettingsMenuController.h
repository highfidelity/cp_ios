//
//  SettingsMenuController.h
//  candpiosapp
//
//  Created by Andrew Hammond on 2/23/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MapTabController.h"
#import "CPTabBarController.h"

@interface SettingsMenuController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, UIActionSheetDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) CPTabBarController *cpTabBarController;
@property (strong, nonatomic) MapTabController *mapTabController;
@property (nonatomic) BOOL isMenuShowing;
@property (weak, nonatomic) IBOutlet UIImageView *edgeShadow;
@property (weak, nonatomic) IBOutlet UIView *loginBanner;

// the following properties are used to dismiss F2F alerts that don't need to still be showing once new ones come in
@property (nonatomic, strong) UIAlertView *f2fInviteAlert;
@property (nonatomic, strong) UIAlertView *f2fPasswordAlert;

@property (weak, nonatomic) IBOutlet UIButton *venueButton;
@property (weak, nonatomic) IBOutlet UIButton *checkedInOnlyButton;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *blockUIButton;

- (IBAction)checkedInButtonClick:(UIButton *)sender;
- (IBAction)selectVenueCity:(id)sender;
- (IBAction)loginButtonClick:(id)sender;
- (IBAction)blockUIButtonClick:(id)sender;

- (void)showMenu:(BOOL)shouldReveal;
- (void)closeMenu;

@end
