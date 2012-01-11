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
#import "AFJSONRequestOperation.h"
#import "NSMutableURLRequestAdditions.h"
#import "MyWebTabController.h"
#import "CreateEmailAccountController.h"
#import "TableCellHelper.h"

@interface EmailLoginSequence()
@property (nonatomic, strong) AFHTTPClient *httpClient;
@property (nonatomic, weak) UIViewController	*mapViewController;
@property (nonatomic, weak) UIViewController	*createOrLoginController;
-(void)loginButtonPressed:(id)sender;
-(void)createButtonPressed:(id)sender;
@end

@implementation EmailLoginSequence

@synthesize httpClient,mapViewController,createOrLoginController;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(id)init
{
	self = [super init];
	if(self)
	{
		
		httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kCandPWebServiceUrl]];
	}
	return self;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)initiateLogin:(UIViewController*)hostController;
{
	mapViewController = hostController;
	
	// set a liberal cookie policy
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy: NSHTTPCookieAcceptPolicyAlways];
	
	// show the login/create/forgot screen
	CreateEmailAccountController *controller = [[CreateEmailAccountController alloc] initWithNibName:@"CreateEmailAccountController" bundle:nil];
	controller.title = @"Login";

	if(true)
	{
		Settings *settings = [AppDelegate instance].settings;
		
		TableCellGroup *group = [[TableCellGroup alloc]init];
		group.headerText = @"Login to Coffee and Power";
		
		//////////////////
		// make the custom footer button
		UIView *footerView = [[UIView alloc] init];
		UIButton *footerButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 300, 44)];
		footerView.autoresizesSubviews = NO;
		[footerView addSubview:footerButton];
		group.footerView = footerView;
		
		[footerButton setTitle:@"Login" forState:UIControlStateNormal];
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
			if([field.text rangeOfString:@"@"].length >0 && [settings.userPassword length] > 0)
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
																	  kvoObject:settings
																	 kvoKeyName:@"userPassword" ];
		password.labelFont = [UIFont boldSystemFontOfSize:14.0];
		//email.customKeyObject = [iWallpaperAppDelegate instance].settings;
		password.textFieldWillChange = ^ BOOL (UITextField *field){
			// enable the button if there's text
			if(field.text.length >0 && [settings.userEmailAddress length] > 0)
				footerButton.enabled = YES;
			else
				footerButton.enabled = NO;
			return YES;
		};
		[group addCell:password];
		
		[controller.cellConfigs addObject:group];

	}
	createOrLoginController = controller;
	[hostController.navigationController pushViewController:controller animated:YES];

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)initiateAccountCreation:(UIViewController*)hostController;
{
	mapViewController = hostController;
	
	CreateEmailAccountController *controller = [[CreateEmailAccountController alloc] initWithNibName:@"CreateEmailAccountController" bundle:nil];
	
	controller.title = @"Create Account";
	
	
	if(true)
	{
		Settings *settings = [AppDelegate instance].settings;
		
		TableCellGroup *group = [[TableCellGroup alloc]init];
		group.headerText = @"Create your Coffee and Power Account";
		
		//////////////////
		// make the custom footer button
		UIView *footerView = [[UIView alloc] init];
		UIButton *footerButton = [[UIButton alloc] initWithFrame:CGRectMake(10, 10, 300, 44)];
		footerView.autoresizesSubviews = NO;
		[footerView addSubview:footerButton];
		group.footerView = footerView;
		
		[footerButton setTitle:@"Create Account" forState:UIControlStateNormal];
		
		footerButton.enabled = NO;
		UIImage *buttonBgDisabled = [UIImage imageNamed:@"button_disabled"];
		UIImage *buttonBgEnabled = [UIImage imageNamed:@"button"];
		[footerButton setBackgroundImage:buttonBgDisabled forState:UIControlStateDisabled];
		[footerButton setBackgroundImage:buttonBgEnabled forState:UIControlStateNormal];
		[footerButton addTarget:self action:@selector(createButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
		[footerButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
		
		
		
		//////////////////
		// add the first name field
		TableCellTextField *firstname = [[TableCellTextField alloc]initWithLabel:@"Nickname"
																 placeholderText:@"Joe"
																	   kvoObject:settings
																	  kvoKeyName:@"userNickname" ];
		firstname.labelFont = [UIFont boldSystemFontOfSize:14.0];
		//firstname.customKeyObject = settings;
		firstname.textFieldWillChange = ^BOOL (UITextField *field){
			// enable the button if there's text
			// enable the button if there's text
			if([field.text length]>0 && settings.userEmailAddress && [settings.userEmailAddress rangeOfString:@"@"].length > 0)
				footerButton.enabled = YES;
			else
				footerButton.enabled = NO;
			return YES;
		};
		[group addCell:firstname];
		
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
			if([field.text rangeOfString:@"@"].length >0 && [settings.userNickname length] > 0)
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
																	  kvoObject:settings
																	 kvoKeyName:@"userPassword" ];
		password.labelFont = [UIFont boldSystemFontOfSize:14.0];
		//email.customKeyObject = [iWallpaperAppDelegate instance].settings;
		password.textFieldWillChange = ^ BOOL (UITextField *field){
			// enable the button if there's text
			if(field.text.length >0 && [settings.userNickname length] > 0)
				footerButton.enabled = YES;
			else
				footerButton.enabled = NO;
			return YES;
		};
		[group addCell:password];
		
		// 
		TableCellTextField *password2 = [[TableCellTextField alloc]initWithLabel:@"Password"
																 placeholderText:@"confirm password"
																	   kvoObject:settings
																	  kvoKeyName:@"userPassword" ];
		password2.labelFont = [UIFont boldSystemFontOfSize:14.0];
		//email.customKeyObject = [iWallpaperAppDelegate instance].settings;
		password2.textFieldWillChange = ^ BOOL (UITextField *field){
			// enable the button if there's text
			if(field.text.length >0 && [settings.userNickname length] > 0)
				footerButton.enabled = YES;
			else
				footerButton.enabled = NO;
			return YES;
		};
		[group addCell:password2];
		
		[controller.cellConfigs addObject:group];
	}
	
	createOrLoginController = controller;
	[hostController.navigationController pushViewController:controller animated:YES];
}

-(void)loginButtonPressed:(id)sender
{
	// force all fields to commit
	[createOrLoginController.view endEditing:YES];
	[[AppDelegate instance] saveSettings];

	NSString *userEmail = [AppDelegate instance].settings.userEmailAddress;
	NSString *password = [AppDelegate instance].settings.userPassword;
	[self handleEmailLogin:userEmail password:password];
	
}

-(void)createButtonPressed:(id)sender
{
	// force all fields to commit
	[createOrLoginController.view endEditing:YES];
	[[AppDelegate instance] saveSettings];
	
	
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)handleEmailCreate:(NSString*)username password:(NSString*)password nickname:(NSString*)nickname
{	
	//http://dev.worklist.net/~stojce/candpfix/web/signup.php?action=signup&signupUsername=USERNAME3@example.com&signupPassword=PASSWORD&signupConfirm=PASSWORD&signupAcceptTerms=1&signupNickname=NICKNAME3&type=json
	// kick off the request to the candp server
	NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
	[loginParams setObject:@"signup" forKey:@"action"];
	[loginParams setObject:username forKey:@"signupUsername"];
	[loginParams setObject:password forKey:@"signupPassword"];
	[loginParams setObject:password forKey:@"signupConfirm"];
	[loginParams setObject:nickname forKey:@"signupNickname"];
	[loginParams setObject:[NSNumber numberWithInt:1] forKey:@"signupAcceptTerms"];
	[loginParams setObject:@"json" forKey:@"type"];
	
	NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"signup.php" parameters:loginParams];
	AFJSONRequestOperation *postOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
		NSDictionary *jsonDict = json;
		NSLog(@"Result code: %d (%@)", [response statusCode], [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]] );
		
		
		NSLog(@"Header fields:" );
		[[response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSLog(@"     %@ : '%@'", key, obj );
			
		}];
		
		NSLog(@"Json fields:" );
		[jsonDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSLog(@"     %@ : '%@'", key, obj );
			
		}];
		

		//[self handleResponseFromCandP:json];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		// handle error
		NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription] );
		
	} ];
	
	// 
	NSBlockOperation *dumpContents = [NSBlockOperation blockOperationWithBlock:^{
		// 
		NSString *responseString = postOperation.responseString;
		NSLog(@"Response was:");
		NSLog(@"-----------------------------------------------");
		NSLog(@"%@", responseString);
		NSLog(@"-----------------------------------------------");
	}];
	[dumpContents addDependency:postOperation];
	[[NSOperationQueue mainQueue]  addOperation:postOperation];
	[[NSOperationQueue mainQueue]  addOperation:dumpContents];
	
	
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
	
	NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"login.php" parameters:loginParams];
	//NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"login.php" parameters:loginParams];
	AFJSONRequestOperation *postOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
		NSDictionary *jsonDict = json;
		NSLog(@"Result code: %d (%@)", [response statusCode], [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]] );
		
		
		NSLog(@"Header fields:" );
		[[response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSLog(@"     %@ : '%@'", key, obj );
			
		}];
		
		NSLog(@"Json fields:" );
		[jsonDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSLog(@"     %@ : '%@'", key, obj );
			
		}];
		
		// currently, we only a success=0 field if it fails
		// (if it succeeds, it's just the user data)
		NSNumber *successNum = [jsonDict objectForKey:@"succeeded"];
		if(successNum && [successNum intValue] == 0)
		{
			NSString *errorMessage = [jsonDict objectForKey:@"message"];
			// we get here if we failed to login
			UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Unable to login" message:errorMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
			[alert show];
		}
		else
		{
			// remember that we're logged in!
			NSString *userId = [jsonDict objectForKey:@"user_id"];
			[AppDelegate instance].settings.candpUserId = userId;
			
			// 
			[mapViewController.navigationController popViewControllerAnimated:YES];
		}
		
		//[self handleResponseFromCandP:json];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		// handle error
		NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription] );
		
	} ];
	
	// 
	NSBlockOperation *dumpContents = [NSBlockOperation blockOperationWithBlock:^{
		// 
		NSString *responseString = postOperation.responseString;
		NSLog(@"Response was:");
		NSLog(@"-----------------------------------------------");
		NSLog(@"%@", responseString);
		NSLog(@"-----------------------------------------------");
	}];
	[dumpContents addDependency:postOperation];
	[[NSOperationQueue mainQueue]  addOperation:postOperation];
	[[NSOperationQueue mainQueue]  addOperation:dumpContents];
		
	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)handleForgotEmailLogin:(NSString*)username
{
	
	// kick off the request to the candp server
	NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
	[loginParams setObject:@"forgot" forKey:@"action"];
	[loginParams setObject:username forKey:@"username"];
	//[loginParams setObject:@"json" forKey:@"type"];
	
	
	NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"login.php" parameters:loginParams];
	//NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"login.php" parameters:loginParams];
	AFJSONRequestOperation *postOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
		NSDictionary *jsonDict = json;
		NSLog(@"Result code: %d (%@)", [response statusCode], [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]] );
		
		
		NSLog(@"Header fields:" );
		[[response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSLog(@"     %@ : '%@'", key, obj );
			
		}];
		
		NSLog(@"Json fields:" );
		[jsonDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSLog(@"     %@ : '%@'", key, obj );
			
		}];
		
		//[self handleResponseFromCandP:json];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		// handle error
		NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription] );
		
	} ];
	
	// 
	NSBlockOperation *dumpContents = [NSBlockOperation blockOperationWithBlock:^{
		// 
		NSString *responseString = postOperation.responseString;
		NSLog(@"Response was:");
		NSLog(@"-----------------------------------------------");
		NSLog(@"%@", responseString);
		NSLog(@"-----------------------------------------------");
	}];
	[dumpContents addDependency:postOperation];
	[[NSOperationQueue mainQueue]  addOperation:postOperation];
	[[NSOperationQueue mainQueue]  addOperation:dumpContents];
	

}

-(void)handleResponseFromCandP:(NSDictionary*)json
{
	
}

@end