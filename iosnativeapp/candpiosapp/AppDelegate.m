//
//  AppDelegate.m
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "FacebookLoginSequence.h"
#import "NSMutableURLRequestAdditions.h"
#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "CheckInListTableViewController.h"

@interface AppDelegate(Internal)
-(void)loadSettings;
+(NSString*)settingsFilepath;
@end

@implementation AppDelegate
@synthesize settings;
@synthesize facebook;
@synthesize loginSequence;
@synthesize urbanAirshipClient;

+(AppDelegate*)instance
{
	return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
	[self loadSettings];  
	
	// load the facebook api
	facebook = [[Facebook alloc] initWithAppId:kFacebookAppId andDelegate:self];
	facebook.accessToken = settings.facebookAccessToken;
	facebook.expirationDate = settings.facebookExpirationDate;
	
	
	urbanAirshipClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"https://go.urbanairship.com/api"]];

	// register for push 
	// TODO: put this as part of the login procedure
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert)];

    return YES;
}

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif {
    [self loadCheckinScreen];
}

- (void)loadCheckinScreen {
    CheckInListTableViewController *checkInListTableViewController = [[CheckInListTableViewController alloc] init];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:checkInListTableViewController];
    
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    [tabBarController presentModalViewController:navigationController animated:NO];
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

// For 4.2+ support
- (BOOL)application:(UIApplication *)application
			openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
		 annotation:(id)annotation 
{
    return [facebook handleOpenURL:url]; 
}

////////////////////////////////////////////////////////////////////////////////////

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken 
{
	// We get here if the user has allowed Push Notifications
	
	// We need to get our authorization token and send it to our servers
	
	

	// first, encode the the push authorization token
    const unsigned char *devTokenBytes = [devToken bytes];
	NSMutableString * devTokenHexEncoded=[NSMutableString stringWithCapacity:([devToken length] * 2)];
	for (int i = 0; i < [devToken length]; ++i) {
		[devTokenHexEncoded appendFormat:@"%02X", (unsigned long)devTokenBytes[i]];
	}
	
	//---------------------
	// Now, create the http request to upload it
	// create the username & password fields
	[urbanAirshipClient setAuthorizationHeaderWithUsername:kUrbanAirshipApplicationKey password:kUrbanAirshipApplicationSecret];
	NSString *path = [NSString stringWithFormat:@"/api/device_tokens/%@", devTokenHexEncoded];
	NSMutableURLRequest *registerTokenAtUrbanAirship = [urbanAirshipClient requestWithMethod:@"PUT" path:path parameters:nil];

	
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:registerTokenAtUrbanAirship];
	__weak AFHTTPRequestOperation *weakOp = operation;
	operation.completionBlock = ^ {
		if ([weakOp hasAcceptableStatusCode]) {
			NSLog(@"Push notification credentials sent");
			
			// remember that it's succeeded
			settings.registeredForApnsSuccessfully = YES;
			[self saveSettings];

		} else {
			NSLog(@"[Error]: (%@ %@) %@", [weakOp.request HTTPMethod], [[weakOp.request URL] relativePath], weakOp.error);
		}
	};
	
	NSOperationQueue *queue = [[NSOperationQueue alloc] init];
	[queue addOperation:operation];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err 
{
    settings.registeredForApnsSuccessfully = NO;
    //NSLog(@"Error in registration. Error: %@", err);
}

////////////////////////////////////////////////////////////////////////////////////
// implement the Facebook Delegate
- (void)fbDidLogin 
{
	if(loginSequence && [loginSequence respondsToSelector:@selector( handleResponseFromFacebookLogin)])
		[(FacebookLoginSequence*) loginSequence handleResponseFromFacebookLogin];
	
}
- (void)fbDidLogout
{
	// we should have already cleared these out
//    settings.facebookAccessToken = nil ;
//    settings.facebookExpirationDate = nil ;
//	[self saveSettings];
	
}
////////////////////////////////////////////////////////////////////////////////////

-(void)logoutEverything
{
	// clear out the cookies
	//NSArray *httpscookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"https://coffeeandpower.com"]];
	//NSArray *httpscookies2 = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"https://staging.coffeeandpower.com"]];
	NSArray *httpscookies3 = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:kCandPWebServiceUrl]];
	
	[httpscookies3 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSHTTPCookie *cookie = (NSHTTPCookie*)obj;
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
	}];
#if DEBUG
	// check they're all gone
	NSArray *httpscookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:kCandPWebServiceUrl]];
#endif
	
	// facebook
	if(facebook && [facebook isSessionValid])
	{
		[facebook logout];
	}
	settings.facebookExpirationDate = nil;
	settings.facebookAccessToken = nil;
	
	// and email credentials
	// (note that we keep the username & password)
	settings.candpUserId = nil;
	settings.userNickname = nil;
	
	
	[[AppDelegate instance] saveSettings];

}


////////////////////////////////////////////////////////////////////////////////////

+(NSString*)settingsFilepath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES /*expandTilde?*/);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:@"SettingsFile" ];
	
}

-(void) loadSettings
{	
	// load the new settings
	@try 
	{
		// load our settings
		Settings *newSettings = [NSKeyedUnarchiver unarchiveObjectWithFile:[AppDelegate settingsFilepath]];
		if(newSettings) {
			settings  = newSettings;
		}
		else {
			settings = [[Settings alloc]init];
		}
	}
	@catch (NSException * e) 
	{
		// if we couldn't load the file, go ahead and delete the file
		[[NSFileManager defaultManager] removeItemAtPath:[AppDelegate settingsFilepath] error:nil];
		settings = [[Settings alloc]init];
		
	}
	
}
-(void)saveSettings
{
	// save the new settings object
	[NSKeyedArchiver archiveRootObject:settings toFile:[AppDelegate settingsFilepath]];
	
}


@end
