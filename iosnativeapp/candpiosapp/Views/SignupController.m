//
//  SignupController.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "SignupController.h"
#import "AppDelegate.h"
#import "CPUIHelper.h"
#import "EmailLoginController.h"
#import "LinkedInLoginController.h"
#import "AFNetworking.h"
#import "Facebook+Blocks.h"
#import "SVProgressHUD.h"
#import "FlurryAnalytics.h"
#import "NSString+StringToNSNumber.h"

@interface SignupController ()
- (void)handleResponseFromFacebookLogin;

@end

@implementation SignupController
@synthesize facebookLoginButton;
@synthesize linkedinLoginButton;
@synthesize emailLoginButton;

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
    [[AppDelegate instance] hideCheckInButton];
    [self.navigationItem setHidesBackButton:YES animated:NO];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    self.title = @"Log In";
    // Set the back button that will appear in pushed views
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" 
                                                                             style:UIBarButtonItemStyleDone 
                                                                            target:nil 
                                                                            action:nil];
    // prepare for the icons to fade in
    self.facebookLoginButton.alpha = 0.0;
    self.linkedinLoginButton.alpha = 0.0;
    self.emailLoginButton.alpha = 0.0;
}

- (void) viewDidAppear:(BOOL)animated {
    // fade in the icons to direct user attention at them
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:0.3];
    self.facebookLoginButton.alpha = 1.0;
    self.linkedinLoginButton.alpha = 1.0;
    self.emailLoginButton.alpha = 1.0;        
    [UIView commitAnimations];    
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
    [self setFacebookLoginButton:nil];
    [self setLinkedinLoginButton:nil];
    [self setEmailLoginButton:nil];
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
	AppDelegate *appDelegate = [AppDelegate instance];
    appDelegate.facebookLoginController = self;
    if (![[appDelegate facebook] isSessionValid]) {   
        NSArray *extendedPermissions = [[NSArray alloc] 
                                        initWithObjects:@"offline_access", @"user_about_me", 
                                        @"user_education_history", @"user_location", @"user_website", @"user_work_history", nil];
        [[appDelegate facebook] authorize:extendedPermissions];
    }
    else
    {
        // we have a facebook session, so just get our info & set it with c&p
        [self handleResponseFromFacebookLogin];
    }

}

- (IBAction)loginWithLinkedInTapped:(id)sender 
{
	// Handle LinkedIn login
	// The LinkedIn login object will handle the sequence that follows
    LinkedInLoginController *linkedInLoginController = [[LinkedInLoginController alloc] initWithNibName:@"LinkedInLoginController" bundle:nil];
    [self.navigationController pushViewController:linkedInLoginController animated:YES];
}

- (IBAction)loginWithEmailTapped:(id)sender 
{
	// handle email login
	// include Forgot option (but not create for now)
    Settings *settings = [AppDelegate instance].settings;
    
    EmailLoginController *emailLoginController = [[EmailLoginController alloc] initWithNibName:@"EmailLoginController" bundle:nil];
    emailLoginController.emailField.text = [settings valueForKey:@"userEmailAddress"];
    [emailLoginController.emailField becomeFirstResponder];
    [self.navigationController pushViewController:emailLoginController animated:YES];
}

- (void)handleResponseFromFacebookLogin
{
    
    NSString *fbAccessToken = [[[AppDelegate instance] facebook] accessToken];
    
    NSString *urlString = [NSString stringWithFormat:@"%@userData.php?action=collectFbData&fb_access_token=%@", kCandPWebServiceUrl, fbAccessToken];
    NSURL *locationURL = [NSURL URLWithString:urlString];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), 
                   ^{
                       NSLog(@"collect FB: %@", [NSString stringWithContentsOfURL:locationURL 
                                                                         encoding:NSUTF8StringEncoding
                                                                            error:nil]);
                   }); 
    
    [AppDelegate instance].settings.facebookAccessToken = fbAccessToken;
    [AppDelegate instance].settings.facebookExpirationDate = [[AppDelegate instance].facebook expirationDate];
	[[AppDelegate instance] saveSettings];
	
	[SVProgressHUD showWithStatus:@"Logging in"];
    
	// get the user's facebook id (via facebook 'me' object)
	FBRequestOperation *getMe = [[AppDelegate instance].facebook requestWithGraphPath:@"me" andCompletionHandler:^(FBRequestOperation *op, id fbJson, NSError *err) {
        
		NSString *facebookId = [fbJson objectForKey:@"id"];
		NSLog(@"Got facebook user id: %@", facebookId);
		// we have succes!
		// kick off the request to the candp server
		NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
		[loginParams setObject:@"loginFacebook" forKey:@"action"];
		[loginParams setObject:facebookId forKey:@"login_fb_id"];
		[loginParams setObject:[NSNumber numberWithInt:1] forKey:@"login_fb_connect"];
		[loginParams setObject:@"json" forKey:@"type"];
        [loginParams setObject:[AppDelegate instance].settings.facebookAccessToken forKey: @"fb_access_token"];
        
		NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"POST"
                                                                     path:@"login.php"
                                                               parameters:loginParams];
		
		AFJSONRequestOperation *postOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id candpJson) {
            
			
			[SVProgressHUD dismiss];
#if DEBUG
            NSLog(@"login json: %@", candpJson);
#endif
            
			NSString *message = [candpJson objectForKey:@"message"];
			if(message && [message compare:@"Error"] == 0)
			{
				// they haven't created an account
				// so do it now
				NSString *errorDetail = [[candpJson objectForKey:@"params"]objectForKey:@"message"];
				NSString *displayMessage = [NSString stringWithFormat:@"You must create an account with Facebook first. Detail: %@",errorDetail];
				UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Unable to login"
															   message:displayMessage
															  delegate:self 
													 cancelButtonTitle:@"OK"
													 otherButtonTitles: nil];
				[alert show];
			}
			else
			{
				// we got in!
				// so remember the success!
				NSDictionary *userInfo = [[candpJson objectForKey:@"params"]objectForKey:@"user"];
				
				NSString *userId = [userInfo objectForKey:@"id"];
				NSString *nickname = [userInfo objectForKey:@"nickname"];
				
				// extract some user info
				[AppDelegate instance].settings.candpUserId = [userId numberFromIntString];
				[AppDelegate instance].settings.userNickname = nickname;
				[[AppDelegate instance] saveSettings];
                
                [FlurryAnalytics logEvent:@"login_facebook"];
                
                // userId isn't actually an NSNumber it's an NSString!?
                [FlurryAnalytics setUserID:(NSString *)userId];
                
                // Wrap up common login operations
                [self pushAliasUpdate];
                
				[self.navigationController popToRootViewControllerAnimated:YES];
			}
			
		} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
			// handle error
			NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription] );
			[SVProgressHUD dismissWithError:[error localizedDescription]];
            
		}];
		
		[[NSOperationQueue mainQueue] addOperation:postOperation];
        
	}];
	
	[[NSOperationQueue mainQueue] addOperation:getMe];
}


@end
