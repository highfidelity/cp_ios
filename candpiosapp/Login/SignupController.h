//
//  SignupController.h
//  candpiosapp
//
//  Created by David Mojdehi on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignupController : UIViewController
- (IBAction)loginWithLinkedInTapped:(id)sender;

@property (weak, nonatomic) IBOutlet UIButton *linkedinLoginButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;

- (IBAction) dismissClick:(id)sender;
@end
