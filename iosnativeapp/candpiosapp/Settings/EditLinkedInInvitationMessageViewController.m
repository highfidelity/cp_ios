//
//  EditLinkedInInvitationMessageViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/30/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

NSString * const kSubjectTemplate = @"%@ is inviting you to Coffee & Power";
NSString * const kBodyTemplate = @"Hi! [name of sender] is inviting you to join Coffee & Power, the mobile work network.\n\
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

@end

@implementation EditLinkedInInvitationMessageViewController

@synthesize subjectTextField = _subjectTextField;
@synthesize bodyTextView = _bodyTextView;

#pragma mark - UIView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *nickname = @"abc";
    NSString *code = @"AAAA";
    
    self.subjectTextField.text = [NSString stringWithFormat:kSubjectTemplate, nickname];
    self.bodyTextView.text = [NSString stringWithFormat:kBodyTemplate, code, nickname];
}

#pragma mark - actions

- (IBAction)cancelAction {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)sendAction {
    
}

@end
