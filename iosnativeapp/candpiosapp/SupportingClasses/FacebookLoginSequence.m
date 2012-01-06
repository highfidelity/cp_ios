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

@interface FacebookLoginSequence()
@property (nonatomic, strong) AFHTTPClient *httpClient;
@property (nonatomic, weak) UIViewController	*mapViewController;
@end

@implementation FacebookLoginSequence

@synthesize httpClient,mapViewController;

-(id)init
{
	self = [super init];
	if(self)
	{
		httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"https://coffeeandpower.com/"]];
	}
	return self;
}
-(void)initiateLogin:(UIViewController*)mapViewControllerArg;
{
	mapViewController = mapViewControllerArg;
	if (![[AppDelegate instance].facebook isSessionValid]) {
		[[AppDelegate instance].facebook authorize:[NSArray arrayWithObjects:@"offline_access", nil]];
	}
}

-(void)handleResponseFromFacebookLogin
{
	[AppDelegate instance].settings.facebookAccessToken = [[AppDelegate instance].facebook accessToken];
    [AppDelegate instance].settings.facebookExpirationDate = [[AppDelegate instance].facebook expirationDate];
	[[AppDelegate instance] saveSettings];
	
	// get the user's facebook id (via facebook 'me' object)
	FBRequestOperation *getMe = [[AppDelegate instance].facebook requestWithGraphPath:@"me" andCompletionHandler:^(FBRequestOperation *op, id json, NSError *err) {
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
			
		NSString *facebookId = [json objectForKey:@"id"];
		NSLog(@"Got facebook user id: %@", facebookId);
		// we have succes!
		// kick off the request to the candp server
		NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
		[loginParams setObject:@"loginFacebook" forKey:@"action"];
		[loginParams setObject:facebookId forKey:@"login_fb_id"];
		[loginParams setObject:[NSNumber numberWithInt:1] forKey:@"login_fb_connect"];
		
#if 1
		NSURL *requestUrl = [NSURL URLWithString:@"https://coffeeandpower.com/login.php"];
		NSMutableURLRequest *request = [NSMutableURLRequest POSTrequestWithURL:requestUrl dictionary:loginParams];
		

		// open a web view with the given url
		if(mapViewController)
		{
			MyWebTabController *controller = [mapViewController.storyboard instantiateViewControllerWithIdentifier:@"WebViewOfCandPUser"];
			controller.urlRequestToLoad = request;
			[mapViewController.navigationController pushViewController:controller animated:YES];
		}
#else
		NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"login.php" parameters:loginParams];
		AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
			
			NSLog(@"Name: %@ %@", [json valueForKeyPath:@"first_name"], [json valueForKeyPath:@"last_name"]);
			NSLog(@"Result code: %d", [response statusCode] );
			[self handleResponseFromCandP];
			
		} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
			
			// handle error
			
		}];
		[[NSOperationQueue mainQueue]  addOperation:operation];
#endif
		
		
		
	}];
	
	[[NSOperationQueue mainQueue] addOperation:getMe];
	
	

}
-(void)handleResponseFromCandP
{
	
}

@end
