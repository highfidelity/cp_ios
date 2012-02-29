//
//  SignupController.h
//  candpiosapp
//
//  Created by David Mojdehi on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignupController : UIViewController
- (IBAction)loginWithFacebookTapped:(id)sender;
- (IBAction)loginWithLinkedInTapped:(id)sender;
- (IBAction)loginWithEmailTapped:(id)sender;
- (IBAction)signupTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;

@end
