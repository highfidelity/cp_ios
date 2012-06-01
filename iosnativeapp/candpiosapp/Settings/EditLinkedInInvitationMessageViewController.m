//
//  EditLinkedInInvitationMessageViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/30/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

NSString * const kSubjectTemplate = @"%@ is inviting you to Coffee & Power";
NSString * const kBodyTemplate = @"Hi! %@ is inviting you to join Coffee & Power, the mobile work network.\n\
\n\
If you haven't already, first download the <iPhone> or <Android> Coffee & Power app.\n\
\n\
Your personal invite code is: %@\n\
\n\
This code is only good for 24 hours. If you accept this invitation, %@ will be shown as your sponsor on your Coffee & Power resume.\n\
\n\
Once signed up, you may sponsor other users with the 'Invite' button in the app settings page.\n\
\n\
Welcome!";

#import "EditLinkedInInvitationMessageViewController.h"

@interface EditLinkedInInvitationMessageViewController ()

@property (nonatomic, weak) IBOutlet UITextField *subjectTextField;
@property (nonatomic, weak) IBOutlet UITextView *bodyTextView;

- (IBAction)cancelAction;
- (IBAction)sendAction;
- (void)adjustViewForKeyboardVisible:(BOOL)visible withKeyboadrNotification:(NSNotification *)aNotification;

@end

@implementation EditLinkedInInvitationMessageViewController

@synthesize subjectTextField = _subjectTextField;
@synthesize bodyTextView = _bodyTextView;
@synthesize nickname = _nickname;
@synthesize connectionIDs = _connectionIDs;

#pragma mark - UIView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    [CPapi getInvitationCodeForLinkedInConnections:self.connectionIDs
                               wihtCompletionBlock:
     ^(NSDictionary *json, NSError *error) {
         if (error) {
             [SVProgressHUD dismissWithError:[error localizedDescription] afterDelay:kDefaultDimissDelay];
             return;
         }
         
         if ([[json objectForKey:@"error"] intValue]) {
             [SVProgressHUD dismissWithError:[json objectForKey:@"payload"] afterDelay:kDefaultDimissDelay];
             return;
         }
         
         NSString *invitationCode = [[json objectForKey:@"payload"] objectForKey:@"code"];
         
         self.subjectTextField.text = [NSString stringWithFormat:kSubjectTemplate, self.nickname];
         self.bodyTextView.text = [NSString stringWithFormat:kBodyTemplate,
                                   self.nickname, invitationCode, self.nickname];
         
         [SVProgressHUD dismiss];
     }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

#pragma mark - actions

- (IBAction)cancelAction {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)sendAction {
    [self.subjectTextField resignFirstResponder];
    [self.bodyTextView resignFirstResponder];
}

#pragma mark - notifications

- (void)keyboardWillShow:(NSNotification *)aNotification {
    [self adjustViewForKeyboardVisible:YES
              withKeyboadrNotification:aNotification];
}

- (void)keyboardWillHide:(NSNotification *)aNotification {
    [self adjustViewForKeyboardVisible:NO
              withKeyboadrNotification:aNotification];
}

#pragma mark - private

- (void)adjustViewForKeyboardVisible:(BOOL)visible withKeyboadrNotification:(NSNotification *)aNotification {
    NSDictionary* userInfo = [aNotification userInfo];
    
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    if (visible) {
        self.bodyTextView.contentInset = UIEdgeInsetsMake(0, 0, keyboardEndFrame.size.height, 0);
    } else {
        self.bodyTextView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }
    
    self.bodyTextView.scrollIndicatorInsets = self.bodyTextView.contentInset;
    
    [UIView commitAnimations];
}

@end
