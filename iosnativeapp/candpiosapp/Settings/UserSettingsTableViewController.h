//
//  UserSettingsViewController.h
//  candpiosapp
//
//  Created by Stephen Birarda on 3/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UserSettingsTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UITextField *nicknameTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) NSString *pendingEmail;
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) User *currentUser;
@property (assign, nonatomic) BOOL finishedSync;
@property (assign, nonatomic) BOOL newDataFromSync;
@property (weak, nonatomic) IBOutlet UIButton *profileImageButton;
@property (strong, nonatomic) UIImageView *profileImage;

@end
