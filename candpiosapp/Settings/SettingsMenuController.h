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
    CPAfterLoginActionShowMap
} CPAfterLoginAction;

@interface SettingsMenuController : UIViewController <UITableViewDelegate,
                                                      UITableViewDataSource,
                                                      UIAlertViewDelegate,
                                                      UINavigationControllerDelegate,
                                                      UIImagePickerControllerDelegate>

@property (strong, nonatomic) CPTabBarController *cpTabBarController;
@property (strong, nonatomic) MapTabController *mapTabController;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *edgeShadow;
@property (weak, nonatomic) IBOutlet UIView *loginBanner;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *blockUIButton;
@property (nonatomic) CPAfterLoginAction afterLoginAction;
@property (nonatomic) BOOL isMenuShowing;

// the following properties are used to dismiss F2F alerts that don't need to still be showing once new ones come in
@property (strong, nonatomic) UIAlertView *f2fInviteAlert;

- (IBAction)loginButtonClick:(id)sender;
- (IBAction)blockUIButtonClick:(id)sender;
- (IBAction)showTermsOfServiceModal:(id)sender;

- (void)showMenu:(BOOL)shouldReveal;
- (void)closeMenu;

- (void)showProfilePicturePickerModalForSource:(UIImagePickerControllerSourceType)imagePickerSource;

@end
