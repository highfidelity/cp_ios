//
//  EnterEmailAfterSingUpController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/1/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "EnterEmailAfterSingUpController.h"
#import "AppDelegate.h"
#import "CPapi.h"

@interface EnterEmailAfterSingUpController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *emailTextField;
@property (nonatomic, weak) IBOutlet UILabel *emailValidationMessage;
@property (nonatomic, weak) IBOutlet UILabel *weWillNotSpamYouLabel;
@property (nonatomic, weak) IBOutlet UIButton *sendButton;

- (IBAction)sendButtonPressed:(id)sender;

@end

@implementation EnterEmailAfterSingUpController

@synthesize emailTextField = _emailTextField;
@synthesize emailValidationMessage = _emailValidationMessage;
@synthesize weWillNotSpamYouLabel = _weWillNotSpamYouLabel;
@synthesize sendButton = _sendButton;

- (void)pushNextViewContollerOrDismissWithMessage:(NSString *)message {
    
    // shouldn't go to invite code anymore, that comes before us
    [self.navigationController dismissModalViewControllerAnimated:YES];
    
    if (message.length) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"" 
                                                            message:message
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)sendEmailSettingsWithEmail:(NSString *)email {
    [SVProgressHUD showWithStatus:@"Checking..."];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   email, @"email",
                                   nil];
    
    [CPapi setUserProfileDataWithDictionary:params andCompletion:^(NSDictionary *json, NSError *error) {
        if ( ! error && [[json objectForKey:@"succeeded"] boolValue]) {
            [SVProgressHUD dismiss];
            [self pushNextViewContollerOrDismissWithMessage:[json objectForKey:@"message"]];
        } else {
            [SVProgressHUD dismissWithError:[json objectForKey:@"message"]
                                 afterDelay:kDefaultDismissDelay];
        }
    }];
}

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

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendButtonPressed:nil];
    return NO;
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
