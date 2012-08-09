//
//  EnterEmailAfterSignUpController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "EnterEmailAfterSignUpController.h"
#import "AppDelegate.h"
#import "CPapi.h"
#import "CPUserSessionHandler.h"

@interface EnterEmailAfterSignUpController () <UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic, weak) IBOutlet UITextField *emailTextField;
@property (nonatomic, weak) IBOutlet UILabel *emailValidationMessage;
@property (nonatomic, weak) IBOutlet UILabel *weWillNotSpamYouLabel;
@property (nonatomic, weak) IBOutlet UIButton *sendButton;

- (IBAction)sendButtonPressed:(id)sender;

@end

@implementation EnterEmailAfterSignUpController

@synthesize emailTextField = _emailTextField;
@synthesize emailValidationMessage = _emailValidationMessage;
@synthesize weWillNotSpamYouLabel = _weWillNotSpamYouLabel;
@synthesize sendButton = _sendButton;

#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.emailTextField addTarget:self
                            action:@selector(emailTextFieldValueChanged:)
                  forControlEvents:UIControlEventEditingChanged];
    
    [CPUIHelper makeButtonCPButton:self.sendButton withCPButtonColor:CPButtonTurquoise];
    [CPUIHelper changeFontForLabel:self.weWillNotSpamYouLabel toLeagueGothicOfSize:28];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
    
    [self.emailTextField becomeFirstResponder];
}

#pragma mark - VC Helpers

- (void)dismissAndPerformAfterLoginActions
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^(void){
        [CPUserSessionHandler performAfterLoginActions];
    }];
}

- (void)sendEmailSettingsWithEmail:(NSString *)email {
    [SVProgressHUD showWithStatus:@"Checking..."];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   email, @"email",
                                   nil];
    
    [CPapi setUserProfileDataWithDictionary:params andCompletion:^(NSDictionary *json, NSError *error) {
        if ( ! error && [[json objectForKey:@"succeeded"] boolValue]) {
            [SVProgressHUD dismiss];
            NSString *message = [json objectForKey:@"message"];
            
            if (message.length) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
                                                                    message:message
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
            } else {
                [self dismissAndPerformAfterLoginActions];
            }            
        } else {
            [SVProgressHUD dismissWithError:[json objectForKey:@"message"]
                                 afterDelay:kDefaultDismissDelay];
        }
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendButtonPressed:nil];
    return NO;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // this has to be the okay button on the alert view
    // so dismiss us and perform the after login actions via CPUserSessionHandler
    [self dismissAndPerformAfterLoginActions];
}

#pragma mark - actions

- (IBAction)sendButtonPressed:(id)sender {
    NSString *email = self.emailTextField.text;
    
    if (email.length == 0  || ![CPUtils validateEmailWithString:email]) {
        NSString *message = @"Email address does not appear to be valid.";
        [SVProgressHUD dismissWithError:message
                             afterDelay:kDefaultDismissDelay];
    } else {
        [self.emailTextField resignFirstResponder];
        [self sendEmailSettingsWithEmail:email];
    }
}

- (void)emailTextFieldValueChanged:(id)sender {
    UITextField *textField = (UITextField *)sender;
    
    if(textField.text.length == 0 || ![CPUtils validateEmailWithString:textField.text]) {
        self.emailValidationMessage.text = @"Must be a valid email address!";
    }else {
        self.emailValidationMessage.text = @"";
    }
}


@end
