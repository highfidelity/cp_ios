//
//  CreateLoginController.m
//  candpiosapp
//
//  Created by Andrew Hammond on 2/28/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CreateLoginController.h"
#import "TPKeyboardAvoidingScrollView.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "FlurryAnalytics.h"
#import "NSString+StringToNSNumber.h"

@implementation CreateLoginController
@synthesize scrollView;
@synthesize confirmPasswordField;
@synthesize confirmPasswordErrorLabel;
@synthesize nicknameField;
@synthesize signupBarButton;
@synthesize nicknameErrorLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated { 
    [super viewWillAppear:animated];
    self.title = @"Join";
    self.confirmPasswordErrorLabel.text = @"";
    self.nicknameErrorLabel.text = @"";
    self.nicknameField.text = [[AppDelegate instance] settings].userNickname;
    self.navigationItem.rightBarButtonItem = self.signupBarButton;
    
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setScrollView:nil];
    [self setConfirmPasswordField:nil];
    [self setConfirmPasswordErrorLabel:nil];
    [self setNicknameField:nil];
    [self setSignupButton:nil];
    [self setNicknameErrorLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#pragma mark - uitextfielddelegate methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailField) {
        [self.passwordField becomeFirstResponder];
    } else if (textField == self.passwordField) {
        [self.confirmPasswordField becomeFirstResponder];
    } else if (textField == self.confirmPasswordField) {
        [self.nicknameField becomeFirstResponder];
    } else if (textField == self.nicknameField) {
        [textField resignFirstResponder];
        // send the signup request
        [self signup:nil];
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.scrollView adjustOffsetToIdealIfNeeded];
}

#pragma mark - signup methods

- (IBAction)signup:(id)sender {
    // create an account for the user
	// force all fields to commit
	[self.view endEditing:YES];
    
    BOOL hasErrored = NO;
    
    if (![self.passwordField.text isEqualToString:self.confirmPasswordField.text]) {
        self.passwordErrorLabel.text = @"The passwords did not match.";
        hasErrored = YES;
    }
    
    if (self.passwordField.text.length < 6) {
        self.passwordErrorLabel.text = @"Your password must be more than 5 characters.";
        hasErrored = YES;
    }
    
    if (![self hasValidEmail]) {
        self.emailErrorLabel.text = emailNotValidMessage;
        hasErrored = YES;
    }
    
    if (self.nicknameField.text.length < 3) {
        self.nicknameErrorLabel.text = @"Nickname must be at least 3 characters long.";
        hasErrored = YES;
    }
    
    if (hasErrored) { 
        return;
    }
    
    [SVProgressHUD showWithStatus:@"Creating Account"];

    [self handleCommonCreate:self.emailField.text
                    password:self.passwordField.text
                    nickname:self.nicknameField.text
                  facebookId:nil
                  completion:^(NSError *error, id JSON) {
                     
                     [SVProgressHUD dismiss];
                     
                     if (!error) {
                         
                         NSDictionary *jsonDict = JSON;
                         NSNumber *successNum = [jsonDict objectForKey:@"succeeded"];
                         
                         if (successNum && [successNum intValue] == 0) {
                             NSString *serverErrorMessage = [jsonDict objectForKey:@"message"];
                             
                             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Creating Account"
                                                                             message:serverErrorMessage 
                                                                            delegate:self 
                                                                   cancelButtonTitle:@"OK" 
                                                                   otherButtonTitles:nil];
                             [alert show];
                         }
                         else {
                             
                             NSDictionary *userInfo = [[jsonDict objectForKey:@"params"] objectForKey:@"params"];
                             
                             NSString *userId = [userInfo objectForKey:@"id"];
                             NSString  *nickname = [userInfo objectForKey:@"nickname"];
                             
                             [AppDelegate instance].settings.candpUserId = [userId numberFromIntString];
                             [AppDelegate instance].settings.userNickname = nickname;
                             [[AppDelegate instance] saveSettings];
                             
                             [FlurryAnalytics logEvent:@"signup_email"];
                             [FlurryAnalytics setUserID:(NSString *)userId];
                             
                             [self pushAliasUpdate];
                             [self.navigationController popToRootViewControllerAnimated:YES];    
                         }
                         
                     }
                     else {
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Creating Account"
                                                                         message:@"There was an error creating the account."
                                                                        delegate:self
                                                               cancelButtonTitle:@"OK"
                                                               otherButtonTitles:nil];
                         [alert show];
                     }
                 }
     ];
}


@end
