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

@interface FacebookLoginSequence()
@property (nonatomic, strong) AFHTTPClient *httpClient;
@end

@implementation FacebookLoginSequence

@synthesize httpClient;

-(id)init
{
	self = [super init];
	if(self)
	{
		httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"https://coffeeandpower.com/"]];
	}
	return self;
}
-(void)initiateLogin
{
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
		
		
		// we have succes!
		// kick off the request to the candp server
		NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
		[loginParams setObject:[AppDelegate instance].settings.facebookAccessToken forKey:@"fb_id"];
		[loginParams setObject:[AppDelegate instance].settings.facebookAccessToken forKey:@"fb_connect"];
		
		NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"login.php" parameters:loginParams];
		AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
			
			NSLog(@"Name: %@ %@", [json valueForKeyPath:@"first_name"], [json valueForKeyPath:@"last_name"]);
			
			[self handleResponseFromCandP];
			
		} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON){
			
			// handle error
			
		}];
		
		[[NSOperationQueue mainQueue]  addOperation:operation];
		
		
	}];
	
	[[NSOperationQueue mainQueue] addOperation:getMe];
	
	

}
-(void)handleResponseFromCandP
{
	
}

@end
