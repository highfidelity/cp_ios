//
//  FaceToFaceInviteController.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/14.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "FaceToFaceAcceptDeclineViewController.h"
#import "FaceToFacePasswordInputViewController.h"
#import "ContactListViewController.h"

#define F2FPasswordViewTag 1515

@implementation FaceToFaceAcceptDeclineViewController

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // make the accept button a CPButton
    self.f2fAcceptButton = [CPUIHelper makeButtonCPButton:self.f2fAcceptButton withCPButtonColor:CPButtonTurquoise];
    
    // make the decline button a CPButton
    self.f2fDeclineButton = [CPUIHelper makeButtonCPButton:self.f2fDeclineButton withCPButtonColor:CPButtonGrey];
    
    // set the background of the action bar
    self.actionBar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-diagonal-noise-dark.png"]];
    
    // set the shadow on the actionBar
    [CPUIHelper addShadowToView:self.actionBar color:[UIColor blackColor] offset:CGSizeMake(0,-2) radius:3 opacity:0.5];
    
    // add a shadow to the toolbar
    [CPUIHelper addShadowToView:self.navigationBar color:[UIColor blackColor] offset:CGSizeMake(0,2) radius:3 opacity:0.5];
    
    // TODO: add the UserProfileViewController as a child view controller
    // via addChildViewController
    // current implementation seems to work but child view controller setup would be cleaner
    
    // Get the main storyboard that has the UserProfileViewController
    self.userProfile = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
    // tell that view controller when it loads that it's loading for a F2F Invite
    self.userProfile.isF2FInvite = YES;
    // set the user on that view controller to the user we just got back
    self.userProfile.user = self.user; 
    // seems like 20 is being added to this view frame (status bar?) so bring the origin back to 0
    self.userProfile.view.frame = CGRectMake(0, 0, self.viewUnderToolbar.frame.size.width, self.viewUnderToolbar.frame.size.height);
    
    [self.viewUnderToolbar insertSubview:self.userProfile.view atIndex:0];
    
    // set the title of the navigation item
    self.navigationBar.topItem.title = @"Contact Request";
    
    self.actionBarHeader.text = [NSString stringWithFormat:@"%@ is nearby and\nwants to add you to their Contacts.", [self.user firstName]];
}

#pragma mark - Actions

- (IBAction)acceptContactRequest {
    // prevent double tape on the Accept button during the existing request
    self.f2fAcceptButton.enabled = NO;
    
    // use common handler method
    [self handleContactRequestAction:YES];
}

- (IBAction)declineContactRequest {
    // use common contact request action handler
    [self handleContactRequestAction:NO];
}

- (void)handleContactRequestAction:(BOOL)isAcceptance
{
    // show a progressHUD
    [SVProgressHUD showWithStatus:@"Loading..."];
    
    void (^completionBlock)(NSDictionary *, NSError *) = ^(NSDictionary *json, NSError *error){
        NSString *errorMessage;
        
        if (error) {
            errorMessage = [error localizedDescription];
        } else {
            if (json == NULL) {
                errorMessage = @"We couldn't send the request.\nPlease try again.";
            } else if ([[json objectForKey:@"error"] boolValue]) {
                errorMessage = [json objectForKey:@"message"];
            }
        }
        
        if (errorMessage) {
            if (isAcceptance) {
                [SVProgressHUD dismiss];
                
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Contact Request"
                                      message:errorMessage
                                      delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles: nil];
                [alert show];
                
                // avoid stacking the f2f alerts
                [CPAppDelegate settingsMenuController].f2fInviteAlert = alert;
                
                self.f2fAcceptButton.enabled = YES;
            } else {
                [self dismissModalViewControllerAnimated:YES];
                
                [SVProgressHUD performSelector:@selector(showErrorWithStatus:)
                                    withObject:errorMessage
                                    afterDelay:kDefaultDismissDelay];
            }
        } else {
            [self dismissModalViewControllerAnimated:YES];
            
            [SVProgressHUD performSelector:@selector(showSuccessWithStatus:)
                                withObject:[NSString stringWithFormat:@"Contact Request %@!", (isAcceptance ? @"Accepted" : @"Declined")]
                                afterDelay:kDefaultDismissDelay];
            
            // tell the ContactListViewController to update so the badge is correct
            [ContactListViewController getNumberOfContactRequestsAndUpdateBadge];
        }
    };
    
    if (isAcceptance) {
        [CPapi sendAcceptContactRequestFromUserId:self.user.userID completion:completionBlock];
    } else {
        [CPapi sendDeclineContactRequestFromUserId:self.user.userID completion:completionBlock];
    }
    
}

@end
