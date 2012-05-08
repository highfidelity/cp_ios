//
//  EnterInvitationCodeViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 4/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "EnterInvitationCodeViewController.h"
#import "User.h"

@interface EnterInvitationCodeViewController () <UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton *laterButton;
@property (nonatomic, weak) IBOutlet UITextField *codeTextField;

- (IBAction)laterButtonAction:(id)sender;

- (void)sendCode:(NSString *)code;
- (void)dismissOrPopViewControllerAnimated:(BOOL)animated;

@end


@implementation EnterInvitationCodeViewController

@synthesize laterButton = _laterButton;
@synthesize codeTextField = _codeTextField;

@synthesize dontShowTextNoticeAfterLaterButtonPressed = _dontShowTextNoticeAfterLaterButtonPressed;
@synthesize shouldDismissOrPop = _shouldDismissOrPop;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [CPUIHelper makeButtonCPButton:self.laterButton
                 withCPButtonColor:CPButtonTurquoise];
    [CPUIHelper changeFontForTextField:self.codeTextField toLeagueGothicOfSize:86];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
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
        [[AppDelegate instance] logoutEverything];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

#pragma mark -
#pragma mark actions

- (IBAction)laterButtonAction:(id)sender; {
    BOOL dismissModalViewController = YES;
    
    if ( ! self.dontShowTextNoticeAfterLaterButtonPressed) {
        if ( ! [[AppDelegate instance].currentUser isDaysOfTrialAccessWithoutInviteCodeOK]) {
            
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Your %d days trial has ended.", kDaysOfTrialAccessWithoutInviteCode]
                                        message:@"Please enter code or logout."
                                       delegate:self
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:@"Logout", nil] show];
            
            dismissModalViewController = NO;
            
        } else {
            [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Coffee & Power requires an invite for full membership but you have %d days of full access to try us out.", kDaysOfTrialAccessWithoutInviteCode]
                                        message:@"If you get an invite from another C&P user you can enter it anytime by going to the Account page/Enter invite code tab."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    }
    
    if (dismissModalViewController) {
        [self dismissOrPopViewControllerAnimated:YES];
    }
}

#pragma mark -
#pragma mark private

- (void)sendCode:(NSString *)code {
    [SVProgressHUD showWithStatus:@"Checking..."];
    
    CLLocation *location = [AppDelegate instance].settings.lastKnownLocation;
    
    [CPapi enterInvitationCode:code
                   forLocation:location
          withCompletionsBlock:^(NSDictionary *json, NSError *error) {
        BOOL respError = [[json objectForKey:@"error"] boolValue];
        
        if (!error && !respError) {
            NSDictionary *userInfo = [[json objectForKey:@"payload"] objectForKey:@"user"];
            [CPAppDelegate storeUserLoginDataFromDictionary:userInfo];
            
            [self dismissOrPopViewControllerAnimated:YES];
            
            [[[UIAlertView alloc] initWithTitle:@"Invite code accepted!" 
                                        message:nil
                                       delegate:nil 
                              cancelButtonTitle:@"OK" 
                              otherButtonTitles:nil] show];
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

- (void)dismissOrPopViewControllerAnimated:(BOOL)animated {
    if (kEnterInvitationCodeViewControllerShouldDismiss == self.shouldDismissOrPop) {
        [self.navigationController dismissModalViewControllerAnimated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
