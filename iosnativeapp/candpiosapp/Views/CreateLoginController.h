//
//  CreateLoginController.h
//  candpiosapp
//
//  Created by Andrew Hammond on 2/28/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "EmailLoginController.h"
@class TPKeyboardAvoidingScrollView;

@interface CreateLoginController : EmailLoginController
@property (weak, nonatomic) IBOutlet TPKeyboardAvoidingScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordField;
@property (weak, nonatomic) IBOutlet UILabel *confirmPasswordErrorLabel;
@property (weak, nonatomic) IBOutlet UITextField *nicknameField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *signupBarButton;
@property (weak, nonatomic) IBOutlet UILabel *nicknameErrorLabel;

@end
