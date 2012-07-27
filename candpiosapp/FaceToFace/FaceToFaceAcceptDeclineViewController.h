//
//  FaceToFaceInviteController.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/14.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserProfileViewController.h"

@interface FaceToFaceAcceptDeclineViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) User *user;
@property (nonatomic, strong) UserProfileViewController *userProfile;
@property (nonatomic, weak) IBOutlet UIView *actionBar;
@property (nonatomic, weak) IBOutlet UILabel *actionBarHeader;
@property (nonatomic, weak) IBOutlet UIButton *f2fAcceptButton;
@property (nonatomic, weak) IBOutlet UIButton *f2fDeclineButton;
@property (nonatomic, weak) IBOutlet UIView *viewUnderToolbar;
@property (nonatomic, weak) IBOutlet UITextField *passwordField;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UINavigationBar *navigationBar;

- (IBAction)acceptF2F;
- (IBAction)declineF2F;
- (void)cancelPasswordEntry:(id)sender;

@end
