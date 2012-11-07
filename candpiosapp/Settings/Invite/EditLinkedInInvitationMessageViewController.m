//
//  EditLinkedInInvitationMessageViewController.m
//  candpiosapp
//
//  Created by Tomáš Horáček on 5/30/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "OAuthConsumer.h"
#import "CPLinkedInAPI.h"
#import "EditLinkedInInvitationMessageViewController.h"
#import "AppDelegate.h"

NSString * const kSubjectTemplate = @"%@ is inviting you to Workclub";

NSString * const kBodyTemplate = @"Hi! %@ is inviting you to join Workclub. Workclub is an app that lets you see who is working near you right now.\n\n\
If %@ is also a LinkedIn contact, they will automatically be added to your Workclub contact list and you will be notified when they check in to workplaces.\n\n\
If you have not already, download the app from the iTunes or Google Play stores.";

@interface EditLinkedInInvitationMessageViewController ()

@property (weak, nonatomic) IBOutlet UITextField *subjectTextField;
@property (weak, nonatomic) IBOutlet UITextView *bodyTextView;

- (IBAction)sendAction;
- (void)adjustViewForKeyboardVisible:(BOOL)visible withKeyboadrNotification:(NSNotification *)aNotification;
- (NSData *)messageBodyData;
- (void)setSendButtonEnabled:(BOOL)enabled;

@end

@implementation EditLinkedInInvitationMessageViewController

#pragma mark - UIView

- (void)viewDidLoad {
    [super viewDidLoad];

    self.subjectTextField.text = [NSString stringWithFormat:kSubjectTemplate, self.nickname];
    self.bodyTextView.text = [NSString stringWithFormat:kBodyTemplate, self.nickname, self.nickname];
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - actions

- (IBAction)sendAction {
    [self.subjectTextField resignFirstResponder];
    [self.bodyTextView resignFirstResponder];
    
    OAMutableURLRequest *request = [[CPLinkedInAPI shared] linkedInJSONAPIRequestWithRelativeURL:
                                    @"v1/people/~/mailbox"];
    
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[self messageBodyData]];
    
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    [fetcher fetchDataWithRequest:request
                         delegate:self
                didFinishSelector:@selector(sendLinkedInInvitationMessageResult:didFinish:)
                  didFailSelector:@selector(sendLinkedInInvitationMessageResult:didFail:)];
    
    [self setSendButtonEnabled:NO];
    [SVProgressHUD showWithStatus:@"Loading..."];
}

- (void)sendLinkedInInvitationMessageResult:(OAServiceTicket *)ticket didFinish:(NSData *)data {
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:kNilOptions
                                                           error:&error];
    
    NSInteger statusCode = [[json objectForKey:@"status"] integerValue];
    
    if (statusCode < 300) {
        [[CPAppDelegate settingsMenuController] dismissViewControllerAnimated:YES
                                                                          completion:NULL];
        [SVProgressHUD dismissWithSuccess:@"Invitation has been sent"];
        [FlurryAnalytics logEvent:@"invitedLinkedInConnections"];
    } else {
        [SVProgressHUD dismissWithError:[json objectForKey:@"message"] afterDelay:kDefaultDismissDelay];
        
        [self setSendButtonEnabled:YES];
    }
}

- (void)sendLinkedInInvitationMessageResult:(OAServiceTicket *)ticket didFail:(NSError *)error {
    [SVProgressHUD dismissWithError:[error localizedDescription] afterDelay:kDefaultDismissDelay];
    [self setSendButtonEnabled:YES];
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
          
- (NSData *)messageBodyData {
    
    NSMutableArray *recipientsValues = [NSMutableArray arrayWithCapacity:[self.connectionIDs count]];
    for (NSString *connectionID in self.connectionIDs) {
        NSString *connectionPath = [NSString stringWithFormat:@"/people/%@", connectionID];
        [recipientsValues addObject:[NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:connectionPath
                                                                                                   forKey:@"_path"]
                                                                forKey:@"person"]];
    }
    
    NSDictionary *messageData = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSDictionary dictionaryWithObject:recipientsValues forKey:@"values"], @"recipients",
                                 self.subjectTextField.text, @"subject",
                                 self.bodyTextView.text, @"body",
                                 nil];
    
    NSError *error;
    return [NSJSONSerialization dataWithJSONObject:messageData
                                           options:kNilOptions
                                             error:&error];
}
    
- (void)setSendButtonEnabled:(BOOL)enabled {
    self.navigationItem.rightBarButtonItem.enabled = enabled;
}

@end
