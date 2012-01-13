//
//  FacebookLoginSequence.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/4/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "FacebookLoginSequence.h"
#import "AppDelegate.h"
#import "AFNetworking.h"
#import "Facebook+Blocks.h"
#import "NSMutableURLRequestAdditions.h"
#import "MyWebTabController.h"
#import "EmailLoginSequence.h"
#import "SVProgressHUD.h"

@interface FacebookLoginSequence()
@end

@implementation FacebookLoginSequence


-(void)initiateLogin:(UIViewController*)mapViewControllerArg;
{
	self.mapViewController = mapViewControllerArg;
	
	// set a liberal cookie policy
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy: NSHTTPCookieAcceptPolicyAlways];

	[[AppDelegate instance] logoutEverything];
	
	if (![[AppDelegate instance].facebook isSessionValid]) {
		[[AppDelegate instance].facebook authorize:[NSArray arrayWithObjects:@"offline_access", nil]];
	}
	else
	{
		// we have a facebook session, so just get our info & set it with c&p
		[self handleResponseFromFacebookLogin];
	}
}

-(void)handleResponseFromFacebookLogin
{
	[AppDelegate instance].settings.facebookAccessToken = [[AppDelegate instance].facebook accessToken];
    [AppDelegate instance].settings.facebookExpirationDate = [[AppDelegate instance].facebook expirationDate];
	[[AppDelegate instance] saveSettings];
	
	[SVProgressHUD showWithStatus:@"Logging in"];

	// get the user's facebook id (via facebook 'me' object)
	FBRequestOperation *getMe = [[AppDelegate instance].facebook requestWithGraphPath:@"me" andCompletionHandler:^(FBRequestOperation *op, id fbJson, NSError *err) {
	//FBRequestOperation *getMe = [FBRequestOperation getPath:@"me" withParams:nil completionHandler:^(FBRequestOperation *op, id json, NSError *err) {
		
		// 'me' example result:
		//	{
		//		id: "1012916614",
		//		name: "David Mojdehi",
		//		first_name: "David",
		//		last_name: "Mojdehi",
		//		link: "http://www.facebook.com/dmojdehi",
		//		username: "dmojdehi",
		//      ...
		//	}
			
		NSString *facebookId = [fbJson objectForKey:@"id"];
		NSLog(@"Got facebook user id: %@", facebookId);
		// we have succes!
		// kick off the request to the candp server
		NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
		[loginParams setObject:@"loginFacebook" forKey:@"action"];
		[loginParams setObject:facebookId forKey:@"login_fb_id"];
		[loginParams setObject:[NSNumber numberWithInt:1] forKey:@"login_fb_connect"];
		[loginParams setObject:@"json" forKey:@"type"];
	

		NSMutableURLRequest *request = [self.httpClient requestWithMethod:@"POST" path:@"login.php" parameters:loginParams];
		//NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"login.php" parameters:loginParams];
		AFJSONRequestOperation *postOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id candpJson) {
			
			NSLog(@"Result code: %d (%@)", [response statusCode], [NSHTTPURLResponse localizedStringForStatusCode:[response statusCode]] );


			NSLog(@"Header fields:" );
			[[response allHeaderFields] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				NSLog(@"     %@ : '%@'", key, obj );
				
			}];
			
			NSLog(@"Json fields:" );
			[candpJson enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
				NSLog(@"     %@ : '%@'", key, obj );
				
			}];
			
			[SVProgressHUD dismiss];

			// if the user hasn't created an account, we get:
			//			{
			//				message = Error;
			//				params =     {
			//					message = "No valid session";
			//				};
			//				"seo_data" =     {
			//					description = "";
			//					title = "";
			//				};
			//				succeeded = 0;
			//			}
			NSString *message = [candpJson objectForKey:@"message"];
			if(message && [message compare:@"Error"] == 0)
			{
				// they haven't created an account
				// so do it now
				NSString *errorDetail = [[candpJson objectForKey:@"params"]objectForKey:@"message"];
#if 1
				NSString *displayMessage = [NSString stringWithFormat:@"You must create an account with Facebook first. Detail: %@",errorDetail];
				UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Unable to login"
															   message:displayMessage
															  delegate:self 
													 cancelButtonTitle:@"OK"
													 otherButtonTitles: nil];
				[alert show];
#else
				[self handleFacebookCreate:facebookId completion:^(NSError *error, id JSON) {
					
				}];
#endif
			}
			else
			{
				// we got in!
				// so remember the success!
				NSDictionary *userInfo = [[candpJson objectForKey:@"params"]objectForKey:@"user"];
				
				NSNumber *userId = [userInfo objectForKey:@"id"];
				NSString  *nickname = [userInfo objectForKey:@"nickname"];
				
				// extract some user info
				[AppDelegate instance].settings.candpUserId = userId;
				[AppDelegate instance].settings.userNickname = nickname;
				[[AppDelegate instance] saveSettings];

				[self.mapViewController.navigationController popToRootViewControllerAnimated:YES];
			}
			
		} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
			// handle error
			NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription] );
			[SVProgressHUD dismissWithError:[error localizedDescription]];

		} ];
		
		[[NSOperationQueue mainQueue]  addOperation:postOperation];
		
		
		
		
	}];
	
	[[NSOperationQueue mainQueue] addOperation:getMe];
	
	

}
								 
-(void)handleResponseFromCandP:(NSDictionary*)json
{
	
}

@end
