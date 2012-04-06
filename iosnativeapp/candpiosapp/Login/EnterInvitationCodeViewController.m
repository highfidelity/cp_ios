//
//  EnterInvitationCodeViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 4/6/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "EnterInvitationCodeViewController.h"

@interface EnterInvitationCodeViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UIButton *laterButton;
@property (nonatomic, weak) IBOutlet UITextField *codeTextField;

- (IBAction)laterButtonAction:(id)sender;

- (void)sendCode:(NSString *)code;
- (void)resizeCodeTextField;

@end


@implementation EnterInvitationCodeViewController

@synthesize laterButton = _laterButton;
@synthesize codeTextField = _codeTextField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [CPUIHelper makeButtonCPButton:self.laterButton
                 withCPButtonColor:CPButtonGrey];
    
    self.codeTextField.layer.cornerRadius = 7;
    self.codeTextField.backgroundColor = [UIColor whiteColor];
    
    [self resizeCodeTextField];
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
#pragma mark actions

- (IBAction)laterButtonAction:(id)sender; {
    [self.navigationController dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark private

- (void)sendCode:(NSString *)code {
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    CLLocation *location = [AppDelegate instance].settings.lastKnownLocation;
    
    [CPapi enterInvitationCode:code
                   forLocation:location
          withCompletionsBlock:^(NSDictionary *json, NSError *error) {
        BOOL respError = [[json objectForKey:@"error"] boolValue];
        
        if (!error && !respError) {
            NSDictionary *userInfo = [[json objectForKey:@"payload"] objectForKey:@"user"];
            [CPAppDelegate storeUserLoginDataFromDictionary:userInfo];
            
            [self.navigationController dismissModalViewControllerAnimated:YES];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" 
                                                                message:[json objectForKey:@"payload"]
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        
        [SVProgressHUD dismiss];
    }];

}

- (void)resizeCodeTextField {
    self.codeTextField.text = @"WWWW";
    [self.codeTextField sizeToFit];
    self.codeTextField.text = @"";
    
    CGRect codeFrame = CGRectInset(self.codeTextField.frame, -5, -2);
    codeFrame.origin.x = round((self.view.frame.size.width - codeFrame.size.width) / 2);
    self.codeTextField.frame = codeFrame;
}

@end
