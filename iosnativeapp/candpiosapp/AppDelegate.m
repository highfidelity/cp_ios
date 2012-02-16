//
//  AppDelegate.m
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "FacebookLoginSequence.h"
#import "AFHTTPClient.h"
#import "CheckInListTableViewController.h"
#import "FlurryAnalytics.h"
#import "OAuthConsumer.h"

@interface AppDelegate(Internal)
-(void)loadSettings;
+(NSString*)settingsFilepath;
-(void)addGoButton;
-(void)addCheckInButton;
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
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
	[self loadSettings];  

    [FlurryAnalytics startSession:@"BI59BJPSZZTIFB5H87HQ"];

    //Init Airship launch options
    NSMutableDictionary *takeOffOptions = [[NSMutableDictionary alloc] init];
    [takeOffOptions setValue:launchOptions forKey:UAirshipTakeOffOptionsLaunchOptionsKey];
    
    // Create Airship singleton that's used to talk to Urban Airship servers.
    // Please populate AirshipConfig.plist with your info from http://go.urbanairship.com
    [UAirship takeOff:takeOffOptions];

	// load the facebook api
	facebook = [[Facebook alloc] initWithAppId:kFacebookAppId andDelegate:self];
	facebook.accessToken = settings.facebookAccessToken;
	facebook.expirationDate = settings.facebookExpirationDate;
	
	urbanAirshipClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"https://go.urbanairship.com/api"]];

	// register for push 
    [[UAPush shared] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    // Handle the case where we were launched from a PUSH notification
    if (launchOptions != nil)
	{
		NSDictionary* dictionary = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
		if (dictionary != nil)
		{
			NSLog(@"Launched from push notification: %@", dictionary);
			//[self addMessageFromRemoteNotification:dictionary updateUI:NO];
		}
	}
    
    [self addGoButton];
    [self addCheckInButton];

    return YES;
}

- (void)application:(UIApplication *)app didReceiveLocalNotification:(UILocalNotification *)notif {
    [self.window.rootViewController performSegueWithIdentifier:@"ShowCheckInListTable" sender:self];
}

// Handle PUSH notifications while the app is running
- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
	NSLog(@"Received notification: %@", userInfo);
	NSString* alertValue = [[userInfo valueForKey:@"aps"] valueForKey:@"alert"];
    
    // If we received a chat push notification
    if ([userInfo valueForKey:@"chat"]) {
        NSString* sendingUserId = [[userInfo valueForKey:@"chat"]
                                    valueForKey:@"f"];
        
        // Strip the user name out of the alert message (it's the string before the colon)
        NSMutableArray* parts = [NSMutableArray arrayWithArray:[alertValue componentsSeparatedByString:@": "]];
        [parts removeObjectAtIndex:0];
        NSString *message = [parts componentsJoinedByString:@": "];
        
        NSLog(@"Received chat message: %@ - %@", sendingUserId, message);
        
    }
}

- (void)addGoButton
{
    UIButton *goButton = [UIButton buttonWithType:UIButtonTypeCustom];
    goButton.backgroundColor = [UIColor clearColor];
    goButton.frame = CGRectMake(10, 395, 75, 75);
    [goButton setImage:[UIImage imageNamed:@"go-button.png"] forState:UIControlStateNormal];
    goButton.tag = 900;
    [self.window.rootViewController.view addSubview:goButton];
}

- (void)addCheckInButton 
{
    UIButton *checkInButton = [UIButton buttonWithType:UIButtonTypeCustom];
    checkInButton.backgroundColor = [UIColor clearColor];
    checkInButton.frame = CGRectMake(235, 395, 75, 75);
    [checkInButton addTarget:self action:@selector(checkInButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [checkInButton setImage:[UIImage imageNamed:@"checked-in.png"] forState:UIControlStateNormal];
    checkInButton.tag = 901;
    [self.window.rootViewController.view addSubview:checkInButton];    
}

- (void)hideGoAndCheckInButtons {
    UIButton *goButton = (UIButton *)[self.window.rootViewController.view viewWithTag:900];
    UIButton *checkInButton = (UIButton *)[self.window.rootViewController.view viewWithTag:901];
    goButton.alpha = 0.0;
    goButton.userInteractionEnabled = NO;
    checkInButton.alpha = 0.0;
    checkInButton.userInteractionEnabled = NO;
}

- (void)showGoAndCheckInButtons {
    
    UIButton *goButton = (UIButton *)[self.window.rootViewController.view viewWithTag:900];
    UIButton *checkInButton = (UIButton *)[self.window.rootViewController.view viewWithTag:901];
    goButton.alpha = 1.0;
    goButton.userInteractionEnabled = YES;
    checkInButton.alpha = 1.0;
    checkInButton.userInteractionEnabled = YES;
}

- (void)checkInButtonPressed:(id)sender
{
    [self.window.rootViewController performSegueWithIdentifier:@"ShowCheckInListTable" sender:self];
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
    [UAirship land];
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
    BOOL succeeded;

    NSString *urlString = [NSString stringWithFormat:@"%@", url];
    
    NSRange textRange;
    textRange = [urlString rangeOfString:@"candp://linkedin"];
    
    if (textRange.location != NSNotFound)
    {

        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              urlString, @"url",
                              nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"linkedInCredentials" object:self userInfo:dict];
        
        succeeded = YES;
    }
    else {
        succeeded = [facebook handleOpenURL:url]; 
    }
    
    return succeeded;
}

- (void)requestTokenTicket:(OAServiceTicket *)ticket
  didFinishWithAccessToken:(NSData *)data {
    NSString *responseBody = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];

    if (ticket.didSucceed) {
        NSLog(@"responseBody: %@", responseBody);

        return;
        NSMutableDictionary* pairs = [NSMutableDictionary dictionary] ;
        NSScanner* scanner = [[NSScanner alloc] initWithString:responseBody] ;
        NSCharacterSet* delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&"];
        
        while (![scanner isAtEnd]) {
            NSString* pairString ;
            [scanner scanUpToCharactersFromSet:delimiterSet
                                    intoString:&pairString] ;
            [scanner scanCharactersFromSet:delimiterSet intoString:NULL] ;
            NSArray* kvPair = [pairString componentsSeparatedByString:@"="] ;
            if ([kvPair count] == 2) {
                NSString* key = [kvPair objectAtIndex:0];
                NSString* value = [kvPair objectAtIndex:1];
                [pairs setObject:value forKey:key] ;
            }
        }
        
        NSString *token = [pairs objectForKey:@"oauth_token"];
        NSString *secret = [pairs objectForKey:@"oauth_token_secret"];
        
        // Store auth token + secret
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"linkedin_token"];
        [[NSUserDefaults standardUserDefaults] setObject:secret forKey:@"linkedin_secret"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
//        [singleton addService:@"LinkedIn" id:2 accessToken:token accessSecret:secret expirationDate:nil];
        
//        [self loadLinkedInConnections];
    }
    else {
        NSLog(@"ERROR responseBody: %@", responseBody);
    }
}

////////////////////////////////////////////////////////////////////////////////////

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken 
{
	// We get here if the user has allowed Push Notifications
	
	// We need to get our authorization token and send it to our servers
    [[UAPush shared] registerDeviceToken:devToken];
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
	//NSArray *httpscookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:kCandPWebServiceUrl]];
#endif
	
	// facebook
//	if (facebook && [facebook isSessionValid])
//	{
//		[facebook logout];
//	}
//	settings.facebookExpirationDate = nil;
//	settings.facebookAccessToken = nil;

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

void uncaughtExceptionHandler(NSException *exception) {
    [FlurryAnalytics logError:@"Uncaught" message:@"Crash!" exception:exception];
}

@end
