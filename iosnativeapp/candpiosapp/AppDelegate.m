//
//  AppDelegate.m
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "AFHTTPClient.h"
#import "SignupController.h"
//#import "FaceToFaceInviteController.h" // TODO: replace with F2FHelper
#import "FaceToFaceHelper.h"
#import "ChatHelper.h"
#import "FlurryAnalytics.h"
#import "OAuthConsumer.h"
#import "CheckInHelper.h"
#import "SignupController.h"
#import "CPUIHelper.h"

@interface AppDelegate(Internal)
-(void)loadSettings;
+(NSString*)settingsFilepath;
-(void)addGoButton;
-(void)addCheckInButton;
@end

@implementation AppDelegate
@synthesize settings;
@synthesize facebook;
@synthesize facebookLoginController;
@synthesize urbanAirshipClient;
@synthesize settingsMenuController;
@synthesize rootNavigationController;

// TODO: Store what we're storing now in settings in NSUSERDefaults
// Why make our own class when there's an iOS Api for this?

+(AppDelegate*)instance
{
	return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

@synthesize window = _window;


# pragma mark - Check-in Button

- (void)addCheckInButton 
{
    UIButton *checkInButton = [UIButton buttonWithType:UIButtonTypeCustom];
    checkInButton.backgroundColor = [UIColor clearColor];
    checkInButton.frame = CGRectMake(235, 375, 75, 75);
    [checkInButton addTarget:self action:@selector(checkInButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [checkInButton setImage:[UIImage imageNamed:@"checked-in.png"] forState:UIControlStateNormal];
    checkInButton.tag = 901;
    [self.rootNavigationController.view addSubview:checkInButton];
}

- (void)hideCheckInButton {
    UIButton *checkInButton = (UIButton *)[self.rootNavigationController.view viewWithTag:901];
    checkInButton.alpha = 0.0;
    checkInButton.userInteractionEnabled = NO;
}

- (void)showCheckInButton {
    UIButton *checkInButton = (UIButton *)[self.rootNavigationController.view viewWithTag:901];
    checkInButton.alpha = 1.0;
    checkInButton.userInteractionEnabled = YES;
}

- (void)checkInButtonPressed:(id)sender
{
    [self.rootNavigationController performSegueWithIdentifier:@"ShowCheckInListTable" sender:self];
}


#pragma mark - View Lifecycle

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
	[self loadSettings];  
    
    [FlurryAnalytics startSession:flurryAnalytics];
    
    // Init Airship launch options
    NSMutableDictionary *takeOffOptions = [[NSMutableDictionary alloc] init];
    [takeOffOptions setValue:launchOptions forKey:UAirshipTakeOffOptionsLaunchOptionsKey];
    
    // Create Airship singleton that's used to talk to Urban Airship servers.
    // Please populate AirshipConfig.plist with your info from http://go.urbanairship.com
    [UAirship takeOff:takeOffOptions];
    
    urbanAirshipClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"https://go.urbanairship.com/api"]];
    
	// register for push 
    [[UAPush shared] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    
	// load the facebook api
	facebook = [[Facebook alloc] initWithAppId:kFacebookAppId 
                                   andDelegate:self];
	facebook.accessToken = settings.facebookAccessToken;
	facebook.expirationDate = settings.facebookExpirationDate;
	
    
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
        
    // Switch out the UINavigationController in the rootviewcontroller for the SettingsMenuController
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"SettingsStoryboard_iPhone" bundle:nil];
    self.settingsMenuController = (SettingsMenuController*)[mainStoryboard instantiateViewControllerWithIdentifier:@"SettingsMenu"];
    self.rootNavigationController = (UINavigationController*)self.window.rootViewController;
    self.settingsMenuController.frontViewController = self.rootNavigationController;
    [settingsMenuController.view addSubview:self.rootNavigationController.view];
    [settingsMenuController addChildViewController:self.rootNavigationController];
    self.window.rootViewController = settingsMenuController;
    [CPUIHelper addDarkNavigationBarStyleToViewController:self.rootNavigationController.topViewController];

    [self addCheckInButton];
    
    // make the status bar the black style
    application.statusBarStyle = UIStatusBarStyleBlackOpaque;

    if (settings.userNickname == nil) { 
        // force a login
        [self logoutEverything];
        SignupController *controller = [[SignupController alloc]initWithNibName:@"SignupController" bundle:nil];
        [self.rootNavigationController pushViewController:controller animated:NO];        
    }
    
    return YES;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationDidBecomeActive" object:nil];

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
    
    [UAirship land];
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


# pragma mark - Push Notifications

- (void)application:(UIApplication *)app
didReceiveLocalNotification:(UILocalNotification *)notif
{
    [self.rootNavigationController performSegueWithIdentifier:@"ShowCheckInListTable"
                                                        sender:self];
}

// Handle PUSH notifications while the app is running
- (void)application:(UIApplication*)application
didReceiveRemoteNotification:(NSDictionary*)userInfo
{
#if DEBUG
	NSLog(@"Received notification: %@", userInfo);
#endif
    
    NSString *alertMessage = (NSString *)[[userInfo objectForKey:@"aps"]
                                          objectForKey:@"alert"];
    
    // Chat push notification
    if ([userInfo valueForKey:@"chat"])
    {
        // Strip the user name out of the alert message (it's the string before the colon)
        NSMutableArray* chatParts = [NSMutableArray arrayWithArray:
         [alertMessage componentsSeparatedByString:@": "]];
        NSString *nickname = [chatParts objectAtIndex:0];
         [chatParts removeObjectAtIndex:0];
        NSString *message = [chatParts componentsJoinedByString:@": "];
        NSInteger userId = [[userInfo valueForKey:@"chat"] intValue];
        
        [ChatHelper respondToIncomingChatNotification:message
                                         fromNickname:nickname
                                           fromUserId:userId
                                         withRootView:self.rootNavigationController];
    }
    // This is a Face-to-Face invite ("f2f1" = [user id])
    else if ([userInfo valueForKey:@"f2f1"] != nil)
    {        
        // make sure we aren't looking at an invite from this user
        
        
        [FaceToFaceHelper presentF2FInviteFromUser:[[userInfo valueForKey:@"f2f1"] intValue]
                                          fromView:self.settingsMenuController];
    }
    // Face to Face Accept Invite ("f2f2" = [userId], "password" = [f2f password])
    else if ([userInfo valueForKey:@"f2f2"] != nil)
    {        
        [FaceToFaceHelper presentF2FAcceptFromUser:[[userInfo valueForKey:@"f2f2"] intValue]
                                      withPassword:[userInfo valueForKey:@"password"]
                                          fromView:self.settingsMenuController];        
    }
    // Face to Face Accept Invite ("f2f3" = [user nickname])
    else if ([userInfo valueForKey:@"f2f3"] != nil)
    {        
        [FaceToFaceHelper presentF2FSuccessFrom:[userInfo valueForKey:@"f2f3"] 
                                       fromView:self.settingsMenuController];
    }
    // Received payment
    else if ([userInfo valueForKey:@"payment_received"] != nil)
    {
        int user_id = [[userInfo valueForKey:@"payment_received"] intValue];
        [CheckInHelper showCheckInProfileForUser:user_id
                                        fromView: self.settingsMenuController];
    }
}

- (void)application:(UIApplication *)app
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken 
{
	// We get here if the user has allowed Push Notifications
	// We need to get our authorization token and send it to our servers
    
    NSString *deviceToken = [[[[devToken description]
                     stringByReplacingOccurrencesOfString: @"<" withString: @""]
                    stringByReplacingOccurrencesOfString: @">" withString: @""]
                   stringByReplacingOccurrencesOfString: @" " withString: @""];
    NSLog(@"Device token: %@", deviceToken);
    
    [[UAPush shared] registerDeviceToken:devToken];
}

- (void)application:(UIApplication *)app
didFailToRegisterForRemoteNotificationsWithError:(NSError *)err 
{
    settings.registeredForApnsSuccessfully = NO;
    NSLog(@"Error in registration. Error: %@", err);
}


#pragma mark - Login Stuff

// implement the Facebook Delegate
- (void)fbDidLogin 
{
    [facebookLoginController handleResponseFromFacebookLogin];
}

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


#pragma mark - User Settings

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
