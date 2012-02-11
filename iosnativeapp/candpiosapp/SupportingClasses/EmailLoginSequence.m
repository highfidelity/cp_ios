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
#import "SVProgressHUD.h"
#import "FlurryAnalytics.h"
#import "SSKeychain.h"

@interface EmailLoginSequence()
@property (nonatomic, weak) UIViewController	*createOrLoginController;
-(void)loginButtonPressed:(id)sender;
-(void)createButtonPressed:(id)sender;

@end

@implementation EmailLoginSequence

@synthesize createOrLoginController;



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
-(void)initiateAccountCreation:(UIViewController*)hostController;
{
	self.mapViewController = hostController;
	
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
																	  kvoObject:nil
																	 kvoKeyName:nil];
		password.labelFont = [UIFont boldSystemFontOfSize:14.0];
		password.secureTextEntry = true;
		//email.customKeyObject = [iWallpaperAppDelegate instance].settings;
		password.textFieldWillChange = ^ BOOL (UITextField *field){
			// enable the button if there's text
			if(field.text.length >0 && [settings.userNickname length] > 0)
				footerButton.enabled = YES;
			else
				footerButton.enabled = NO;
			return YES;
		};

        password.textFieldDidCommit = ^ void (UITextField *field){
            [SSKeychain setPassword:field.text forService:@"email" account:@"candp"];
        };

		[group addCell:password];
		
		// 
		TableCellTextField *password2 = [[TableCellTextField alloc]initWithLabel:@"Password"
																 placeholderText:@"confirm password"
																	   kvoObject:nil
																	  kvoKeyName:nil];
		password2.labelFont = [UIFont boldSystemFontOfSize:14.0];
		password2.secureTextEntry = true;
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
	
	// make sure we logout (clear any old sessions)
	[[AppDelegate instance] logoutEverything];

	[SVProgressHUD showWithStatus:@"Logging in"];
	
	NSString *userEmail = [AppDelegate instance].settings.userEmailAddress;
	NSString *password = [SSKeychain passwordForService:@"email" account:@"candp"];
	[self handleEmailLogin:userEmail password:password];

}

-(void)createButtonPressed:(id)sender
{
	// force all fields to commit
	[createOrLoginController.view endEditing:YES];
	[[AppDelegate instance] saveSettings];

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Coming Soon" message:@".. we promise!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [alert show];
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
		
		// Successful login will return:
		//		{
		//			message = "Logged in";
		//			params =     {
		//				user =         {
		//					"SMS_forward_chat" = 1;
		//					"SMS_forward_mission_comments" = 1;
		//					"SMS_forward_new_missions" = 0;
		//					"SMS_forward_offers" = 1;
		//					"SMS_forward_payments" = 1;
		//					"SMS_grant_code_datetime" = "0000-00-00 00:00:00";
		//					"SMS_grant_confirm_code" = "";
		//					about = "";
		//					active = Y;
		//					"audio_anyonechat" = 0;
		//					"audio_commentorbidchat" = 1;
		//					"audio_levelup" = 1;
		//					"audio_matchingmission" = 1;
		//					"audio_newmission" = 1;
		//					"audio_offerchanged" = 1;
		//					"audio_one2onechat" = 1;
		//					"audio_paidchat" = 1;
		//					"audio_pingchat" = 1;
		//					awesomeness = "0.00000";
		//					balance = "<null>";
		//					"blocked_until" = "<null>";
		//					"can_delete_missions" = "<null>";
		//					"can_purchase_currency" = 1;
		//					"can_verify_id" = 0;
		//					"confirm_flag" = Y;
		//					"confirm_string" = "<null>";
		//					country = "<null>";
		//					"deletion_reason" = "<null>";
		//					email = "<null>";
		//					"email_forward_chat" = 1;
		//					"email_forward_iwant_keywords" = "<null>";
		//					"email_forward_iwill_keywords" = "<null>";
		//					"email_forward_mission_comments" = 1;
		//					"email_forward_new_iwant_missions_category" = "-1";
		//					"email_forward_new_iwill_missions_category" = "-1";
		//					"email_forward_new_missions" = 0;
		//					"email_forward_offers" = 1;
		//					"email_forward_payments" = 1;
		//					"email_news_and_updates" = 1;
		//					"email_weekly_updates" = 1;
		//					"fb_connect" = "<null>";
		//					"fb_id" = "<null>";
		//					"forgot_expire" = "0000-00-00 00:00:00";
		//					"forgot_hash" = "<null>";
		//					"gift_count" = 0;
		//					"got_SMS_grant" = "<null>";
		//					id = 6249;
		//					"int_code" = "<null>";
		//					"inviter_id" = 0;
		//					"is_admin" = "<null>";
		//					"join_date" = "2012-01-10 20:08:37";
		//					"last_ip_address" = "<null>";
		//					"last_location_update" = "0000-00-00 00:00:00";
		//					"last_status_text_update" = "0000-00-00 00:00:00";
		//					lat = "0.000000";
		//					"linkedin_connect" = "<null>";
		//					"linkedin_id" = "<null>";
		//					"linkedin_public_profile_url" = "<null>";
		//					lng = "0.000000";
		//					"logged_in" = 1;
		//					"master_link" =             {
		//						"affected_rows" = "<null>";
		//						"client_info" = "<null>";
		//						"client_version" = "<null>";
		//						"connect_errno" = "<null>";
		//						"connect_error" = "<null>";
		//						errno = "<null>";
		//						error = "<null>";
		//						"field_count" = "<null>";
		//						"host_info" = "<null>";
		//						info = "<null>";
		//						"insert_id" = "<null>";
		//						"protocol_version" = "<null>";
		//						"server_info" = "<null>";
		//						"server_version" = "<null>";
		//						sqlstate = "<null>";
		//						"thread_id" = "<null>";
		//						"warning_count" = "<null>";
		//					};
		//					nickname = DavidTest2012;
		//					notCol =             {
		//						join =                 {
		//							userSkills =                     {
		//								joinFields = "rel_users_skillsskill_id AS skillsList ";
		//								joinSQL = " LEFT JOIN rel_users_skills ON users.id = rel_users_skillsuser_id ";
		//								useIt = 0;
		//							};
		//						};
		//					};
		//					password = "<null>";
		//					phone = "<null>";
		//					"phone_confirmed" = N;
		//					photo = 0;
		//					"photo_original" = 0;
		//					"photo_thumbnail" = 0;
		//					"profile_video" = "<null>";
		//					provider = "<null>";
		//					"slave_link" =             {
		//						"affected_rows" = "<null>";
		//						"client_info" = "<null>";
		//						"client_version" = "<null>";
		//						"connect_errno" = "<null>";
		//						"connect_error" = "<null>";
		//						errno = "<null>";
		//						error = "<null>";
		//						"field_count" = "<null>";
		//						"host_info" = "<null>";
		//						info = "<null>";
		//						"insert_id" = "<null>";
		//						"protocol_version" = "<null>";
		//						"server_info" = "<null>";
		//						"server_version" = "<null>";
		//						sqlstate = "<null>";
		//						"thread_id" = "<null>";
		//						"warning_count" = "<null>";
		//					};
		//					"sms_forward_iwant_keywords" = "<null>";
		//					"sms_forward_iwill_keywords" = "<null>";
		//					"sms_forward_new_iwant_missions_category" = "-1";
		//					"sms_forward_new_iwill_missions_category" = "-1";
		//					smsaddr = "<null>";
		//					"special_code" = "<null>";
		//					status = Ready;
		//					"status_text" = "";
		//					"table_name" = users;
		//					"tos_accepted" = "2012-01-10 20:08:37";
		//					"url_video" = "";
		//					"video_chat" = 1;
		//					"visual_notification" = 1;
		//					"zoom_level" = 0;
		//				};
		
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
			
			NSNumber *userId = [userInfo objectForKey:@"id"];
			NSString  *nickname = [userInfo objectForKey:@"nickname"];
			
			// extract some user info
			[AppDelegate instance].settings.candpUserId = userId;
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
		
		//[self handleResponseFromCandP:json];
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		// handle error
#if DEBUG
		NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription] );
#endif
		[SVProgressHUD dismissWithError:[error localizedDescription]];

		
	} ];
	
	// 
	NSBlockOperation *dumpContents = [NSBlockOperation blockOperationWithBlock:^{
		// 
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)handleForgotEmailLogin:(NSString*)username
{
	
	// kick off the request to the candp server
	NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
	[loginParams setObject:@"forgot" forKey:@"action"];
	[loginParams setObject:username forKey:@"username"];
	//[loginParams setObject:@"json" forKey:@"type"];
	
	
	NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"POST" path:@"login.php" parameters:loginParams];
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