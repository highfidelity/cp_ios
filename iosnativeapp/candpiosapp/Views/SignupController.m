//
//  SignupController.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "SignupController.h"
#import "AppDelegate.h"
#import "EmailLoginSequence.h"
#import "FacebookLoginSequence.h"
#import "LinkedInLoginSequence.h"
#import "CPUIHelper.h"

@implementation SignupController
@synthesize signupButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [[AppDelegate instance] hideCheckInButton];
    [self.navigationItem setHidesBackButton:YES animated:NO];
    self.title = @"Log In";
    // Set the back button that will appear in pushed views
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" 
                                                                             style:UIBarButtonItemStyleDone 
                                                                            target:nil 
                                                                            action:nil];
    // Style signup button
    UIButton * button = [CPUIHelper CPButtonWithText:@"Sign Up" color:CPButtonGrey frame:self.signupButton.frame];
    [button addTarget:self action:@selector(signupTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.signupButton removeFromSuperview];
    [self.view addSubview:button];
    self.signupButton = button;
    [self.navigationController setNavigationBarHidden:YES animated:NO];    
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
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
    [self setSignupButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)loginWithFacebookTapped:(id)sender 
{
	// handle facebook login
	// the facebook login object will handle the sequence that follows

	FacebookLoginSequence *facebookLogin = [[FacebookLoginSequence alloc] init];
	[facebookLogin initiateLogin:self];
	[AppDelegate instance].loginSequence = facebookLogin;
}

- (IBAction)loginWithLinkedInTapped:(id)sender 
{
	// Handle LinkedIn login
	// The LinkedIn login object will handle the sequence that follows
    
	LinkedInLoginSequence *linkedInLogin = [[LinkedInLoginSequence alloc] init];
	[linkedInLogin initiateLogin:self];
	[AppDelegate instance].loginSequence = linkedInLogin;
}

- (IBAction)loginWithEmailTapped:(id)sender 
{
	// handle email login
	// include Forgot option (but not create for now)
	EmailLoginSequence *emailLogin = [[EmailLoginSequence alloc]init ];
	[emailLogin initiateLogin:self];
	[AppDelegate instance].loginSequence = emailLogin;
	
}

- (IBAction)signupTapped:(id)sender 
{
	// handle create (via email)
	EmailLoginSequence *emailLogin = [[EmailLoginSequence alloc] init];
	[emailLogin initiateAccountCreation: self];
	[AppDelegate instance].loginSequence = emailLogin;
}
@end
