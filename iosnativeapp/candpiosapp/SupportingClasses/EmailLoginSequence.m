//
//  EmailLoginSequence.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/10/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "EmailLoginSequence.h"
#import "AppDelegate.h"
#import "AFNetworking.h"
#import "CreateEmailAccountController.h"
#import "TableCellHelper.h"
#import "SVProgressHUD.h"
#import "FlurryAnalytics.h"
#import "SSKeychain.h"
#import "EmailLoginController.h"
#import "NSString+StringToNSNumber.h"

@interface EmailLoginSequence()
@property (nonatomic, weak) UIViewController	*createOrLoginController;
@property (nonatomic, strong) EmailLoginController *emailLoginController;

-(void)loginButtonPressed:(id)sender;
-(void)createButtonPressed:(id)sender;

@end

@implementation EmailLoginSequence

@synthesize createOrLoginController;
@synthesize emailLoginController;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)initiateLogin:(UIViewController*)hostController;
{
	self.mapViewController = hostController;
	
	// set a liberal cookie policy
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy: NSHTTPCookieAcceptPolicyAlways];
	
	// show the login/create/forgot screen
	CreateEmailAccountController *controller = [[CreateEmailAccountController alloc] initWithNibName:@"CreateEmailAccountController" bundle:nil];
	controller.title = @"Log In";

	if(true)
	{
        
		Settings *settings = [AppDelegate instance].settings;
        
        self.emailLoginController = [[EmailLoginController alloc] initWithNibName:@"EmailLoginController" bundle:nil];
        self.emailLoginController.emailField.text = [settings valueForKey:@"userEmailAddress"];
        [self.emailLoginController.emailField becomeFirstResponder];
        [hostController.navigationController pushViewController:self.emailLoginController animated:YES];
        return;
		
		TableCellGroup *group = [[TableCellGroup alloc]init];
		group.headerText = @"Log In to Coffee and Power";
		
		//////////////////
		// make the custom footer button
		UIView *footerView = [[UIView alloc] init];
		UIButton *footerButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 300, 44)];
		footerView.autoresizesSubviews = NO;
		[footerView addSubview:footerButton];
		group.footerView = footerView;
		
		[footerButton setTitle:@"Log In" forState:UIControlStateNormal];
		footerButton.enabled = NO;
		UIImage *buttonBgDisabled = [UIImage imageNamed:@"button_disabled"];
		UIImage *buttonBgEnabled = [UIImage imageNamed:@"button"];
		[footerButton setBackgroundImage:buttonBgDisabled forState:UIControlStateDisabled];
		[footerButton setBackgroundImage:buttonBgEnabled forState:UIControlStateNormal];
		[footerButton addTarget:self action:@selector(loginButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[footerButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
		
		
		//////////////////
		// add the email field
		TableCellTextField *email = [[TableCellTextField alloc]initWithLabel:@"Email"
															 placeholderText:@"joe@example.com"
																   kvoObject:settings
																  kvoKeyName:@"userEmailAddress" ];
		email.labelFont = [UIFont boldSystemFontOfSize:14.0];
		//email.customKeyObject = [iWallpaperAppDelegate instance].settings;
		email.textFieldWillChange = ^ BOOL (UITextField *field){
			// enable the button if there's text
			if([field.text rangeOfString:@"@"].length >0 && [[SSKeychain passwordForService:@"email" account:@"candp"]
 length] > 0)
				footerButton.enabled = YES;
			else
				footerButton.enabled = NO;
			return YES;
		};
		[group addCell:email];
		
		//////////////////
		// add the password field
		TableCellTextField *password = [[TableCellTextField alloc]initWithLabel:@"Password"
																placeholderText:@"password"
																	  kvoObject:nil
																	 kvoKeyName:nil];
		password.labelFont = [UIFont boldSystemFontOfSize:14.0];
		password.secureTextEntry = true;
		//email.customKeyObject = [iWallpaperAppDelegate instance].settings;
		password.textFieldWillChange = ^ BOOL (UITextField *field){
			// enable the button if there's text
			if(field.text.length >0)
				footerButton.enabled = YES;
			else
				footerButton.enabled = NO;
			return YES;
		};
        
        password.textFieldDidCommit = ^ void (UITextField *field){
            [SSKeychain setPassword:field.text forService:@"email" account:@"candp"];
        };

		[group addCell:password];
		
		[controller.cellConfigs addObject:group];

	}
	createOrLoginController = controller;
	[hostController.navigationController pushViewController:controller animated:YES];

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)initiateAccountCreation:(UIViewController*)hostController;
{
	self.mapViewController = hostController;
	
	CreateEmailAccountController *controller = [[CreateEmailAccountController alloc] initWithNibName:@"CreateEmailAccountController" bundle:nil];
	
	controller.title = @"Create Account";
	
    TableCellGroup *group = [[TableCellGroup alloc]init];
    group.headerText = @"Create your Coffee and Power Account";
    
    //////////////////
    // make the custom footer button
    UIView *footerView = [[UIView alloc] init];
    UIButton *footerButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 300, 44)];
    footerView.autoresizesSubviews = NO;
    [footerView addSubview:footerButton];
    group.footerView = footerView;
    
    //////////////////
    // add the Create Account button
    [footerButton setTitle:@"Create Account" forState:UIControlStateNormal];
    
    footerButton.enabled = NO;
    UIImage *buttonBgDisabled = [UIImage imageNamed:@"button_disabled"];
    UIImage *buttonBgEnabled = [UIImage imageNamed:@"button"];
    [footerButton setBackgroundImage:buttonBgDisabled forState:UIControlStateDisabled];
    [footerButton setBackgroundImage:buttonBgEnabled forState:UIControlStateNormal];
    [footerButton addTarget:self action:@selector(createButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [footerButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
    
    //////////////////
    // add the nickname field
    TableCellTextField *nickname = [[TableCellTextField alloc] initWithLabel:@"Nickname"
                                                             placeholderText:@"Joe"
                                                                   kvoObject:self
                                                                  kvoKeyName:@"signupNickname_" ];
    nickname.labelFont = [UIFont boldSystemFontOfSize:14.0];
    nickname.textFieldWillChange = ^BOOL(UITextField *field) {
        if ([field.text length] > 0 && [signupEmalAddress_ length] > 0 && [signupPassword_ length] > 0 && [signupConfirmPassword_ length] > 0) {
            [footerButton setEnabled: YES];
        }
        else {
            [footerButton setEnabled: NO];
        }
        return YES;
    };
    [group addCell:nickname];
    
    //////////////////
    // add the email field 
    TableCellTextField *email = [[TableCellTextField alloc] initWithLabel:@"Email"
                                                          placeholderText:@"joe@example.com"
                                                                kvoObject:self
                                                               kvoKeyName:@"signupEmalAddress_" ];
    email.labelFont = [UIFont boldSystemFontOfSize:14.0];
    email.textFieldWillChange = ^ BOOL (UITextField *field) {
        if ([signupNickname_ length] > 0 && [field.text length] > 0 && [signupPassword_ length] > 0 && [signupConfirmPassword_ length] > 0) {
            [footerButton setEnabled: YES];
        }
        else {
            [footerButton setEnabled: NO];
        }
        return YES;
    };
    [group addCell:email];
    
    //////////////////
    // add the password field
    TableCellTextField *password = [[TableCellTextField alloc] initWithLabel:@"Password"
                                                             placeholderText:@"Required"
                                                                   kvoObject:self
                                                                  kvoKeyName:@"signupPassword_"];
    password.labelFont = [UIFont boldSystemFontOfSize:14.0];
    password.secureTextEntry = true;
    password.textFieldWillChange = ^BOOL(UITextField *field) {
        if ([signupNickname_ length] > 0 &&  [signupEmalAddress_ length] > 0 && [field.text length] > 0 && [signupConfirmPassword_ length] > 0) {
            [footerButton setEnabled: YES];
        }
        else {
            [footerButton setEnabled: NO];
        }
        return YES;
    };
    [group addCell:password];
    
    //////////////////
    // add the confirm password filed
    TableCellTextField *password2 = [[TableCellTextField alloc]initWithLabel:@"Verify"
                                                             placeholderText:@"confirm password"
                                                                   kvoObject:self
                                                                  kvoKeyName:@"signupConfirmPassword_"];
    password2.labelFont = [UIFont boldSystemFontOfSize:14.0];
    password2.secureTextEntry = true;
    password2.textFieldWillChange = ^BOOL(UITextField *field) {
        if ([signupNickname_ length] > 0 &&  [signupEmalAddress_ length] > 0 &&  [signupPassword_ length] > 0 && [field.text length] > 0) {
            [footerButton setEnabled: YES];
        }
        else {
            [footerButton setEnabled: NO];
        }
        return YES;
    };
    [group addCell:password2];
    
    [controller.cellConfigs addObject:group];
	
	createOrLoginController = controller;
	[hostController.navigationController pushViewController:controller animated:YES];
}

-(void)loginButtonPressed:(id)sender
{
	// force all fields to commit
	[createOrLoginController.view endEditing:YES];
	[[AppDelegate instance] saveSettings];
	
	// make sure we logout (clear any old sessions)
	[[AppDelegate instance] logoutEverything];

	[SVProgressHUD showWithStatus:@"Logging in"];
	
	NSString *userEmail = [AppDelegate instance].settings.userEmailAddress;
	NSString *password = [SSKeychain passwordForService:@"email" account:@"candp"];
	[self handleEmailLogin:userEmail password:password];

}

- (void)createButtonPressed:(id)sender
{
	// force all fields to commit
	[createOrLoginController.view endEditing:YES];
    
    NSString *errorTitle;
    NSString *errorMsg;
    
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];

    if (![signupPassword_ isEqualToString: signupConfirmPassword_]) {
        errorTitle = @"Password Missmatch";
        errorMsg = @"Password verification does not match the password you entered.";
    }
    
    if ([signupPassword_ length] < 6) {
        errorTitle = @"Password Too Short";
        errorMsg = @"Your password must be at least 6 characters.";
    }
    
    if ([signupEmalAddress_ length] == 0 || ![emailTest evaluateWithObject:signupEmalAddress_]) {
        errorTitle = @"Invlid Email Address";
        errorMsg = @"Please enter a valid email address.";
    }
    
    if ([signupNickname_ length] < 3) {
        errorTitle = @"Invlid Nickname";
        errorMsg = @"Nickname must be at least 3 characters long.";
    }
    
    if (errorMsg) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:errorTitle
                                                        message:errorMsg 
                                                       delegate:self 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    [SVProgressHUD showWithStatus:@"Creating Account"];
    
    [self handleEmailCreate:signupEmalAddress_
                   password:signupPassword_
                   nickname:signupNickname_
                 completion:^(NSError *error, id JSON) {
                     
                     [SVProgressHUD dismiss];
                     
                     if (!error) {
                         
                         NSDictionary *jsonDict = JSON;
                         NSNumber *successNum = [jsonDict objectForKey:@"succeeded"];
                         
                         if (successNum && [successNum intValue] == 0) {
                             NSString *serverErrorMessage = [jsonDict objectForKey:@"message"];
                             
                             UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Creating Account"
                                                                             message:serverErrorMessage 
                                                                            delegate:self 
                                                                   cancelButtonTitle:@"OK" 
                                                                   otherButtonTitles:nil];
                             [alert show];
                         }
                         else {
                             
                             NSDictionary *userInfo = [[jsonDict objectForKey:@"params"] objectForKey:@"params"];
                             
                             NSString *userId = [userInfo objectForKey:@"id"];
                             NSString  *nickname = [userInfo objectForKey:@"nickname"];
                             
                             [AppDelegate instance].settings.candpUserId = [userId numberFromIntString];
                             [AppDelegate instance].settings.userNickname = nickname;
                             [[AppDelegate instance] saveSettings];
                             
                             [FlurryAnalytics logEvent:@"signup_email"];
                             [FlurryAnalytics setUserID:(NSString *)userId];
                             
                             [self finishLogin];
                             [self.mapViewController.navigationController popToRootViewControllerAnimated:YES];    
                         }
                         
                     }
                     else {
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Creating Account"
                                                                         message:@"There was an error creating the account."
                                                                        delegate:self
                                                               cancelButtonTitle:@"OK"
                                                               otherButtonTitles:nil];
                         [alert show];
                     }
                 }
            ];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)handleEmailLogin:(NSString*)username password:(NSString*)password
{	
			
	// kick off the request to the candp server
	NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
	[loginParams setObject:@"login" forKey:@"action"];
	[loginParams setObject:username forKey:@"username"];
	[loginParams setObject:password forKey:@"password"];
	[loginParams setObject:@"json" forKey:@"type"];
	
	NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"POST" path:@"login.php" parameters:loginParams];
	//NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"login.php" parameters:loginParams];
	AFJSONRequestOperation *postOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
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
			//NSString *outerErrorMessage = [jsonDict objectForKey:@"message"];
			NSString *serverErrorMessage = [[jsonDict objectForKey:@"params"] objectForKey:@"message"];
			NSString *errorMessage = [NSString stringWithFormat:@"The error was:%@", serverErrorMessage];
			// we get here if we failed to login
			UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Unable to login" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		}
		else
		{
			// remember that we're logged in!
			// (it's really the persistent cookie that tracks our login, but we need a superficial indicator, too)
			NSDictionary *userInfo = [[jsonDict objectForKey:@"params"]objectForKey:@"user"];
			
			NSString *userId = [userInfo objectForKey:@"id"];
			NSString  *nickname = [userInfo objectForKey:@"nickname"];
			
			// extract some user info
			[AppDelegate instance].settings.candpUserId = [userId numberFromIntString];
			[AppDelegate instance].settings.userNickname = nickname;
			[[AppDelegate instance] saveSettings];
            
            [FlurryAnalytics logEvent:@"login_email"];
            
            // userId isn't actually an NSNumber it's an NSString!?
            [FlurryAnalytics setUserID:(NSString *)userId];
            
            // Perform common login operations
            [self finishLogin];

			//[mapViewController.navigationController popViewControllerAnimated:YES];
			[self.mapViewController.navigationController popToRootViewControllerAnimated:YES];
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

@end