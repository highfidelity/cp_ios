//
//  SignupController.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "SignupController.h"
#import "LinkedInLoginController.h"
#import "AFNetworking.h"
#import "Facebook+Blocks.h"
#import "FlurryAnalytics.h"

@interface SignupController ()
- (void)handleResponseFromFacebookLogin;

@end

@implementation SignupController
@synthesize facebookLoginButton;
@synthesize linkedinLoginButton;
@synthesize emailLoginButton;
@synthesize dismissButton;

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
    //self.facebookLoginButton.alpha = 0.0;
    self.linkedinLoginButton.alpha = 1.0;
    //self.emailLoginButton.alpha = 0.0;        
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
    [CPUIHelper makeButtonCPButton:self.dismissButton
                 withCPButtonColor:CPButtonGrey];
}

- (void)viewDidUnload
{
    [self setFacebookLoginButton:nil];
    [self setLinkedinLoginButton:nil];
    [self setEmailLoginButton:nil];
    [self setDismissButton:nil];
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
                                        @"user_education_history", @"user_location", @"user_website", @"user_work_history", @"email", nil];
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
    [self performSegueWithIdentifier:@"ShowLinkedInLoginController" sender:sender];
}

- (void)handleResponseFromFacebookLogin
{
    NSString *fbAccessToken = [[[AppDelegate instance] facebook] accessToken];
    
    // TODO: Pull this into CPapi
    NSString *urlString = [NSString stringWithFormat:@"%@userData.php?action=collectFbData&fb_access_token=%@",
                                                     kCandPWebServiceUrl,
                                                     fbAccessToken];
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
	FBRequestOperation *getMe = [[AppDelegate instance].facebook requestWithGraphPath:@"me" 
                                                                 andCompletionHandler:^(FBRequestOperation *op, id fbJson, NSError *err)
    {
        
		NSString *facebookId = [fbJson objectForKey:@"id"];
		NSLog(@"Got facebook user id: %@", facebookId);
        NSString *fullName = [fbJson objectForKey:@"name"];
        NSString *email = [fbJson objectForKey:@"email"];
        
        NSString *password = [NSString stringWithFormat:@"%d-%@",
                              [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]],
                              [[NSProcessInfo processInfo] globallyUniqueString]];

		// we have succes!
		// kick off the request to the candp server
		NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
		[loginParams setObject:facebookId forKey:@"fb_id"];
		[loginParams setObject:@"1" forKey:@"fb_connect"];
		[loginParams setObject:@"json" forKey:@"type"];
        [loginParams setObject:[AppDelegate instance].settings.facebookAccessToken forKey: @"fb_access_token"];
        [loginParams setObject:fullName forKey:@"signupNickname"];
        [loginParams setObject:email forKey:@"signupUsername"];
        [loginParams setObject:password forKey:@"signupPassword"];
        [loginParams setObject:password forKey:@"signupConfirm"];
        [loginParams setObject:@"signup" forKey:@"action"];
        [loginParams setObject:@"json" forKey:@"type"];
        
		NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"POST"
                                                                     path:@"signup.php"
                                                               parameters:loginParams];
		
		AFJSONRequestOperation *postOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id candpJson) {
            
			[SVProgressHUD dismiss];
#if DEBUG
            NSLog(@"login json: %@", candpJson);
#endif

            NSInteger succeeded = [[candpJson objectForKey:@"succeeded"] intValue];
            NSLog(@"success: %d", succeeded);
            
            if(succeeded == 0)
            {
                NSString *outerErrorMessage = [candpJson objectForKey:@"message"];// often just 'error'
                
                NSString *errorMessage = [NSString stringWithFormat:@"The error was: %@", outerErrorMessage];
                
                // we get here if we failed to login
                UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Unable to log in"
                                                               message:errorMessage
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles: nil];
                [alert show];
                
                [self.navigationController dismissModalViewControllerAnimated:YES];
            }
            else
            {
				// we got in!
				// so remember the success!
                NSDictionary *userInfo = [[candpJson objectForKey:@"params"] objectForKey:@"params"];
                
                // store the user info to NSUserDefaults
                [CPAppDelegate storeUserLoginDataFromDictionary:userInfo];
                
                NSString *userId = [userInfo objectForKey:@"id"];
                
                [FlurryAnalytics logEvent:@"login_facebook"];
                
                [FlurryAnalytics setUserID:userId];
                
                // Wrap up common login operations
                [BaseLoginController pushAliasUpdate];
                
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

- (IBAction) dismissClick:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

@end
