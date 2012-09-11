//
//  EnterInvitationCodeViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 4/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "EnterInvitationCodeViewController.h"
#import "PushModalViewControllerFromLeftSegue.h"
#import "User.h"
#import "CPUserSessionHandler.h"

@interface EnterInvitationCodeViewController () <UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *laterButton;
@property (weak, nonatomic) IBOutlet UITextField *codeTextField;
@property (nonatomic) BOOL dismissModalViewController;

- (IBAction)laterButtonAction:(id)sender;

- (void)sendCode:(NSString *)code;
- (void)dismissLeftOrNormalModalViewControllerAnimated:(BOOL)animated;

@end

@implementation EnterInvitationCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [CPUIHelper makeButtonCPButton:self.laterButton
                 withCPButtonColor:CPButtonTurquoise];
    [CPUIHelper changeFontForTextField:self.codeTextField toLeagueGothicOfSize:86];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.dismissModalViewController) {
        [self dismissLeftOrNormalModalViewControllerAnimated:animated];
    } else {
        if (![[CPUserDefaultsHandler currentUser] isDaysOfTrialAccessWithoutInviteCodeOK]) {
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Your %d days trial has ended.", kDaysOfTrialAccessWithoutInviteCode]
                                        message:@"Please enter an invite code."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            [FlurryAnalytics logEvent:@"trialEnded"];
        }
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == self.codeTextField) {
        [self sendCode:textField.text];
    }
    return NO;
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.firstOtherButtonIndex == buttonIndex) {
        [CPUserSessionHandler logoutEverything];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

#pragma mark -
#pragma mark actions

- (IBAction)laterButtonAction:(id)sender; {
    self.dismissModalViewController = YES;
    
    if ( ! self.dontShowTextNoticeAfterLaterButtonPressed) {
        if ( ![[CPUserDefaultsHandler currentUser] isDaysOfTrialAccessWithoutInviteCodeOK]) {
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Your %d days trial has ended.", kDaysOfTrialAccessWithoutInviteCode]
                                        message:@"Please enter code or logout."
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:@"Logout", nil] show];
            
            self.dismissModalViewController = NO;
            [FlurryAnalytics logEvent:@"trialEnded"];
        } else {
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Coffee & Power requires an invite for full membership but you have %d days of full access to try us out.", kDaysOfTrialAccessWithoutInviteCode]
                                        message:@"If you get an invite from another C&P user you can enter it anytime by going to the Account page/Enter invite code tab."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];            
        }
    }
    
    if (![CPUserDefaultsHandler currentUser].isDaysOfTrialAccessWithoutInviteCodeOK) {
        UINavigationController *navigationController = (UINavigationController *)self.parentViewController;
        [CPUserSessionHandler showSignupModalFromViewController:navigationController.topViewController animated:YES];
    } else {
        if (self.dismissModalViewController) {
            [self dismissLeftOrNormalModalViewControllerAnimated:YES];
        }        
    }
}

#pragma mark -
#pragma mark private

- (void)sendCode:(NSString *)code {
    [SVProgressHUD showWithStatus:@"Checking..."];
    
    CLLocation *location = [CPAppDelegate locationManager].location;
    
    [CPapi enterInvitationCode:code
                   forLocation:location
          withCompletionsBlock:^(NSDictionary *json, NSError *error) {
        BOOL respError = [[json objectForKey:@"error"] boolValue];
        
        if (!error && !respError) {
            NSDictionary *userInfo = [[json objectForKey:@"payload"] objectForKey:@"user"];
            [CPUserSessionHandler storeUserLoginDataFromDictionary:userInfo];
            
            [self dismissLeftOrNormalModalViewControllerAnimated:YES];
            
            [[[UIAlertView alloc] initWithTitle:@"Invite code accepted!" 
                                        message:nil
                                       delegate:nil 
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil] show];
            [FlurryAnalytics logEvent:@"inviteCodeAccepted"];
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Error" 
                                        message:[json objectForKey:@"payload"]
                                       delegate:nil 
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil] show];
        }
        
        [SVProgressHUD dismiss];
    }];

}

- (void)dismissLeftOrNormalModalViewControllerAnimated:(BOOL)animated {
    self.dismissModalViewController = NO;
    if (self.isPushedFromLeft) {
        [self dismissPushModalViewControllerFromLeftSegue];
    } else {
        [self dismissModalViewControllerAnimated:animated];
    }
}

@end
