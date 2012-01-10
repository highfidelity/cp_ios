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



@interface EmailLoginSequence()
@property (nonatomic, strong) AFHTTPClient *httpClient;
@property (nonatomic, weak) UIViewController	*mapViewController;
@end

@implementation EmailLoginSequence

@synthesize httpClient,mapViewController;

-(id)init
{
	self = [super init];
	if(self)
	{
		
		httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kCandPWebServiceUrl]];
	}
	return self;
}
-(void)initiateLogin:(UIViewController*)mapViewControllerArg;
{
	mapViewController = mapViewControllerArg;
	
	// set a liberal cookie policy
	[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy: NSHTTPCookieAcceptPolicyAlways];
	
	// show the login/create/forgot screen
	
}

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