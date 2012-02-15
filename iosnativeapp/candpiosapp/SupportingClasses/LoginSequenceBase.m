//
//  LoginSequenceBase.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LoginSequenceBase.h"
#import "AppDelegate.h"
#import "AFNetworking.h"

@interface LoginSequenceBase()
-(void)handleCommonCreate:(NSString*)username
		password:(NSString*)password
		nickname:(NSString*)nickname
		facebookId:(NSString*)facebookId
		completion:(void (^)(NSError *error, id JSON))completion;
@end

@implementation LoginSequenceBase

@synthesize httpClient;
@synthesize mapViewController;

////////////////////////////////////////////////////////////////////////////////////////
-(id)init
{
	self = [super init];
	if(self)
	{
		
		httpClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:kCandPWebServiceUrl]];
	}
	return self;
}


////////////////////////////////////////////////////////////////////////////////////////
-(void)handleEmailCreate:(NSString*)username
                password:(NSString*)password
                nickname:(NSString*)nickname
              completion:(void (^)(NSError *error, id JSON))completion
{
	[self handleCommonCreate:username password:password nickname:nickname facebookId:nil completion:completion];
}

// Things to do once a user logs in via any method
-(void)finishLogin {
    // Set my UserID as an UrbanAirship alias for push notifications
    NSString *userid = (NSString *)[AppDelegate instance].settings.candpUserId;
    NSLog(@"Pushing aliases to UrbanAirship: %@", userid);
    [[UAPush shared] updateAlias:userid];
}


/////////////////////////////////////////////////////////////////////////////////////////
-(void)handleCommonCreate:(NSString*)username
				 password:(NSString*)password
				 nickname:(NSString*)nickname
			   facebookId:(NSString*)facebookId
			   completion:(void (^)(NSError *error, id JSON))completion
{
	// kick off the request to the candp server
	NSMutableDictionary *loginParams = [NSMutableDictionary dictionary];
	[loginParams setObject:@"signup" forKey:@"action"];
	[loginParams setObject:username forKey:@"signupUsername"];
	if(facebookId)
	{
		[loginParams setObject:[NSNumber numberWithInt:1] forKey:@"fb_connect"];
		[loginParams setObject:facebookId forKey:@"fb_id"];
	}
	else
	{
		[loginParams setObject:password forKey:@"signupPassword"];
		[loginParams setObject:password forKey:@"signupConfirm"];
		[loginParams setObject:nickname forKey:@"signupNickname"];
	}
	[loginParams setObject:[NSNumber numberWithInt:1] forKey:@"signupAcceptTerms"];
	[loginParams setObject:@"json" forKey:@"type"];
	NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"signup.php" parameters:loginParams];
	AFJSONRequestOperation *postOperation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id json) {
#if DEBUG        
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
#endif		
        completion(nil, json);
		
	} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
		// handle error
		NSLog(@"AFJSONRequestOperation error: %@", [error localizedDescription] );
        completion(error, nil);
		
	} ];
	
	[[NSOperationQueue mainQueue] addOperation:postOperation];
}

@end
