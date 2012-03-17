//
//  EmailLoginController.m
//  candpiosapp
//
//  Created by Andrew Hammond on 2/28/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "EmailLoginController.h"
#import "SSKeychain.h"
#import "Settings.h"
#import "AppDelegate.h"
#import "AFJSONRequestOperation.h"
#import "SVProgressHUD.h"
#import "FlurryAnalytics.h"
#import "AFHTTPClient.h"
#import "CreateLoginController.h"
#import "NSString+StringToNSNumber.h"

@interface EmailLoginController ()
@end
    
@implementation EmailLoginController
@synthesize emailField;
@synthesize passwordField;
@synthesize emailErrorLabel;
@synthesize passwordErrorLabel;
@synthesize loginButton;
@synthesize signupButton;
@synthesize forgotPasswordButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (BOOL)hasValidEmail { 
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    NSString *emailString = self.emailField.text;
    return !(emailString.length == 0 || ![emailTest evaluateWithObject:emailString]);
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [CPUIHelper makeButtonCPButton:self.signupButton withCPButtonColor:CPButtonGrey];
    [CPUIHelper makeButtonCPButton:self.forgotPasswordButton withCPButtonColor:CPButtonGrey];
    self.navigationItem.rightBarButtonItem = self.loginButton;
    self.title = @"Sign In";
    // Set the Back button for pushed views
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" 
                                                                             style:UIBarButtonItemStyleDone 
                                                                            target:nil 
                                                                            action:nil];
    [self.emailField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.emailField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    Settings *settings = [AppDelegate instance].settings;
    self.emailErrorLabel.text = @"";
    self.passwordErrorLabel.text = @"";
    self.emailField.text = [settings valueForKey:@"userEmailAddress"];
}

- (void)viewDidUnload
{
    [self setLoginButton:nil];
    [self setEmailField:nil];
    [self setPasswordField:nil];
    [self setEmailErrorLabel:nil];
    [self setPasswordErrorLabel:nil];
    [self setSignupButton:nil];
    [self setForgotPasswordButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)signup:(id)sender {
    CreateLoginController *createLoginController = [[CreateLoginController alloc] initWithNibName:@"CreateLoginController" bundle:nil];
    [self.navigationController pushViewController:createLoginController animated:YES];
}

- (IBAction)forgotPassword:(id)sender {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Doh!" message:@"Not yet implemented." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}


- (IBAction)login:(id)sender {
    NSString *username = self.emailField.text;
    NSString *password = self.passwordField.text;
    [SSKeychain setPassword:password forService:@"email" account:@"candp"];
    Settings *settings = [AppDelegate instance].settings;
    [settings setValue:username forKey:@"userEmailAddress"];

	// kick off the request to the candp server
	NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
	[loginParams setObject:@"login" forKey:@"action"];
	[loginParams setObject:username forKey:@"username"];
	[loginParams setObject:password forKey:@"password"];
	[loginParams setObject:@"json" forKey:@"type"];
	
	NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"POST" path:@"login.php" parameters:loginParams];
	AFJSONRequestOperation *postOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request 
                                                                                            success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
		NSDictionary *jsonDict = json;
        
#if DEBUG
		NSLog(@"Result code: %d (%@)", [response statusCode], [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]] );
		
		
		NSLog(@"Header fields:" );
		[[response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSLog(@"     %@ : '%@'", key, obj );
			
		}];
		
		NSLog(@"Json fields:" );
		[jsonDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSLog(@"     %@ : '%@'", key, obj );
			
		}];
#endif
		[SVProgressHUD dismiss];
        
		// currently, we only a success=0 field if it fails
		// (if it succeeds, it's just the user data)
		NSNumber *successNum = [jsonDict objectForKey:@"succeeded"];
		if(successNum && [successNum intValue] == 0)
		{
            
            // This is often just 'error'. Currently unused, commenting out - alexi
			NSString *serverErrorMessage = [[jsonDict objectForKey:@"params"] objectForKey:@"message"];
			NSString *errorMessage = [NSString stringWithFormat:@"The error was:%@", serverErrorMessage];
#if DEBUG
            NSLog(@"Unable to login: %@", errorMessage);
#endif
            self.emailErrorLabel.text = @"Unable to login. Email and password do not match.";
		}
		else
		{
			// remember that we're logged in!
			// (it's really the persistent cookie that tracks our login, but we need a superficial indicator, too)
			NSDictionary *userInfo = [[jsonDict objectForKey:@"params"] objectForKey:@"user"];
            
            [CPAppDelegate storeUserLoginDataFromDictionary:userInfo];
            
			NSString *userId = [userInfo objectForKey:@"id"];
            [FlurryAnalytics logEvent:@"login_email"];
            [FlurryAnalytics setUserID:userId];
            
            // Perform common login operations
            [BaseLoginController pushAliasUpdate];
            
			[self.navigationController popToRootViewControllerAnimated:YES];
		}
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		// handle error
#if DEBUG
		NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription] );
#endif
		[SVProgressHUD dismissWithError:[error localizedDescription]];
	} ];
    
	NSBlockOperation *dumpContents = [NSBlockOperation blockOperationWithBlock:^{
        
#if DEBUG
		NSString *responseString = postOperation.responseString;
		NSLog(@"Response was:");
		NSLog(@"-----------------------------------------------");
		NSLog(@"%@", responseString);
		NSLog(@"-----------------------------------------------");
#endif
	}];
	[dumpContents addDependency:postOperation];
	[[NSOperationQueue mainQueue]  addOperation:postOperation];
	[[NSOperationQueue mainQueue]  addOperation:dumpContents];
    
}


#pragma mark - UITextFieldDelegate methods

- (void)switchFromEmailField {
    if (self.emailField.isFirstResponder) { 
        [self.emailField resignFirstResponder];
        [self.passwordField becomeFirstResponder];
    }
    
    if ([self hasValidEmail]) { 
        self.emailErrorLabel.text = @"";
    } else {
        self.emailErrorLabel.text = emailNotValidMessage;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.emailField) { 
        [self switchFromEmailField];
    } 
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField { 
    if (textField == self.emailField) { 
        [self switchFromEmailField];
    } else if (textField == self.passwordField) {
        [SVProgressHUD showWithStatus:@"Logging in..."];
        [self login:nil];
    }
    return YES;
}



@end
