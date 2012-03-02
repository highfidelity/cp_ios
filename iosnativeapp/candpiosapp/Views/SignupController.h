//
//  SignupController.h
//  candpiosapp
//
//  Created by David Mojdehi on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseLoginController.h"

@interface SignupController : BaseLoginController
- (IBAction)loginWithFacebookTapped:(id)sender;
- (IBAction)loginWithLinkedInTapped:(id)sender;
- (IBAction)loginWithEmailTapped:(id)sender;
- (void)handleResponseFromFacebookLogin;

@property (weak, nonatomic) IBOutlet UIButton *facebookLoginButton;
@property (weak, nonatomic) IBOutlet UIButton *linkedinLoginButton;
@property (weak, nonatomic) IBOutlet UIButton *emailLoginButton;

@end
