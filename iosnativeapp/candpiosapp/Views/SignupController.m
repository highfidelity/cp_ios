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

@implementation SignupController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    UIView *checkedInButton = [self.navigationController.view viewWithTag:901];
    checkedInButton.userInteractionEnabled = NO;
    checkedInButton.alpha = 0;
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
	//[emailLogin handleEmailCreate:@"david@mindfulbear.com" password:@"mindmind2012" nickname:@"DavidTest2012" ];
	//[emailLogin handleForgotEmailLogin:@"dmojdehi@mac.com"];
	//[emailLogin handleEmailLogin: @"candptest+5@gmail.com" password:@"abc123"];
	//[emailLogin handleEmailLogin: @"dmojdehi@mac.com" password:@""];
	[AppDelegate instance].loginSequence = emailLogin;
	
}

- (IBAction)signupTapped:(id)sender 
{
	// handle create (via email)
	EmailLoginSequence *emailLogin = [[EmailLoginSequence alloc]init ];
	[emailLogin initiateAccountCreation:self];
	[AppDelegate instance].loginSequence = emailLogin;
}
@end
