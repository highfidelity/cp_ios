//
//  EmailLoginController.h
//  candpiosapp
//
//  Created by Andrew Hammond on 2/28/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLoginController.h"
@class EmailLoginSequence;

@interface EmailLoginController : BaseLoginController <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UILabel *emailErrorLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordErrorLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;

- (IBAction)login:(id)sender;
- (IBAction)signup:(id)sender;
- (IBAction)forgotPassword:(id)sender;
- (BOOL)hasValidEmail;
@end
