//
//  FaceToFaceInviteController.m
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/14.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "FaceToFaceAcceptDeclineViewController.h"
#import "FaceToFacePasswordInputViewController.h"
#import "CPapi.h"
#import "CPUIHelper.h"

#define F2FPasswordViewTag 1515

@implementation FaceToFaceAcceptDeclineViewController
@synthesize user = _user;
@synthesize actionBar = _actionBar;
@synthesize actionBarHeader = _actionBarHeader;
@synthesize f2fAcceptButton = _f2fAcceptButton;
@synthesize f2fDeclineButton = _f2fDeclineButton;
@synthesize viewUnderToolbar = _viewUnderToolbar;
@synthesize passwordField = _passwordField;
@synthesize toolbarTitle = _toolbarTitle;
@synthesize scrollView = _scrollView;
@synthesize toolbar = _toolbar;
@synthesize userProfile = _userProfile;

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // change the toolbar to the dark style
    [CPUIHelper addDarkToolbarStyleToToolbar:self.toolbar];
    
    // make the accept button a CPButton
    self.f2fAcceptButton = [CPUIHelper makeButtonCPButton:self.f2fAcceptButton withCPButtonColor:CPButtonTurquoise];
    
    // make the decline button a CPButton
    self.f2fDeclineButton = [CPUIHelper makeButtonCPButton:self.f2fDeclineButton withCPButtonColor:CPButtonGrey];
    
    // set the background of the action bar
    self.actionBar.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"texture-diagonal-noise-dark.png"]];
    
    // set the shadow on the actionBar
    [CPUIHelper addShadowToView:self.actionBar color:[UIColor blackColor] offset:CGSizeMake(0,-2) radius:3 opacity:0.5];
    
    // add a shadow to the toolbar
    [CPUIHelper addShadowToView:self.toolbar color:[UIColor blackColor] offset:CGSizeMake(0,2) radius:3 opacity:0.5];
    
    // Get the main storyboard that has the UserProfileViewController
    UIStoryboard *mainStory = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    self.userProfile = [mainStory instantiateViewControllerWithIdentifier:@"UserProfileViewController"];
    // tell that view controller when it loads that it's loading for a F2F Invite
    self.userProfile.isF2FInvite = YES;
    // set the user on that view controller to the user we just got back
    self.userProfile.user = self.user; 
    // seems like 20 is being added to this view frame (status bar?) so bring the origin back to 0
    self.userProfile.view.frame = CGRectMake(0, 0, self.viewUnderToolbar.frame.size.width, self.viewUnderToolbar.frame.size.height);
    
    [self.viewUnderToolbar insertSubview:self.userProfile.view atIndex:0];
    
    // set the title of the toolbar
    self.toolbarTitle.text = [NSString stringWithFormat:@"F2F with %@?", self.user.nickname];
    
    self.actionBarHeader.text = [NSString stringWithFormat:@"%@ is nearby and\n wants to meet you face to face.", [self.user firstName]];
}

- (void)viewDidUnload
{
    [self setF2fAcceptButton:nil];
    [self setF2fDeclineButton:nil];
    [self setActionBar:nil];
    [self setActionBarHeader:nil];
    [self setViewUnderToolbar:nil];
    [self setToolbar:nil];
    [self setScrollView:nil];
    [self setToolbarTitle:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Actions

- (IBAction)acceptF2F {
    // TODO: Don't show the password entry screen unless we know that the accept request worked
    [CPapi sendF2FAccept:self.user.userID];

    if (![self.view viewWithTag:F2FPasswordViewTag]) {
        // get the password entry view if we don't have it
        // grab the view controller from the storyboard
        FaceToFacePasswordInputViewController *f2fPasswordVC = [self.storyboard instantiateViewControllerWithIdentifier:@"FaceToFacePasswordInput"];
        
        // set the frame of the password entry view so it's below the current view
        f2fPasswordVC.view.frame = CGRectMake(0, self.scrollView.frame.size.height, f2fPasswordVC.view.frame.size.width, f2fPasswordVC.view.frame.size.height);
        f2fPasswordVC.view.tag = F2FPasswordViewTag;
        
        [self.scrollView addSubview:f2fPasswordVC.view];
        
        // set the scrollView contentSize so we can hold everything
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.contentSize.height + f2fPasswordVC.view.frame.size.height);
        
        // set the text on the top label
        f2fPasswordVC.waitLabel.text = [NSString stringWithFormat:@"Wait for %@ to find you\nand tell you the password.", [self.user firstName]];
        
        // set our passwordField property to the passwordField of the view we just added
        self.passwordField = f2fPasswordVC.passwordField;
        
        // be the delegate of that password field
        self.passwordField.delegate = self;
        
        // change cancel button target and action
        UIBarButtonItem *cancel = (UIBarButtonItem *)[f2fPasswordVC.toolbar.items objectAtIndex:1];
        cancel.target = self;
        cancel.action = @selector(cancelPasswordEntry:);
    } 
    
    // slide up the view
    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
        [self.scrollView setContentOffset:CGPointMake(0, self.scrollView.frame.size.height)];
        [self.passwordField becomeFirstResponder];
    } completion:NULL];
    
}

- (IBAction)declineF2F {
    [CPapi sendF2FDecline:self.user.userID];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)cancelPasswordEntry:(id)sender {
    // slide back the view to show the accept decline view
    [self.passwordField resignFirstResponder];
    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
        [self.scrollView setContentOffset:CGPointMake(0, 0)];
    } completion:NULL];
    
    // don't remove the password view because we might be showing it again
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // the user has input a passwod and tapped on go
    // let's try the F2F
    [CPapi sendF2FVerify:self.user.userID password:textField.text];
    return NO;
}

@end
