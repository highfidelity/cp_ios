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

#define AUTOCHECKIN_PROMPT_TAG 4829

typedef enum {
    CPAfterLoginActionNone,
    CPAfterLoginActionShowLogbook,
    CPAfterLoginActionAddNewLog,
    CPAfterLoginActionShowMap
} CPAfterLoginAction;

@interface SettingsMenuController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) CPTabBarController *cpTabBarController;
@property (strong, nonatomic) MapTabController *mapTabController;
@property (nonatomic) BOOL isMenuShowing;
@property (weak, nonatomic) IBOutlet UIImageView *edgeShadow;
@property (weak, nonatomic) IBOutlet UIView *loginBanner;
@property (nonatomic, assign) CPAfterLoginAction afterLoginAction;

// the following properties are used to dismiss F2F alerts that don't need to still be showing once new ones come in
@property (nonatomic, strong) UIAlertView *f2fInviteAlert;
@property (nonatomic, strong) UIAlertView *f2fPasswordAlert;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *blockUIButton;

- (IBAction)loginButtonClick:(id)sender;
- (IBAction)blockUIButtonClick:(id)sender;

- (void)showMenu:(BOOL)shouldReveal;
- (void)closeMenu;

@end
