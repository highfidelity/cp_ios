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
#import "FaceToFaceHelper.h"
#import "ChatHelper.h"
#import "FlurryAnalytics.h"
#import "OAuthConsumer.h"
#import "PaymentHelper.h"
#import "SignupController.h"
#import "BaseLoginController.h"
#import "EnterInvitationCodeViewController.h"
#import "User.h"

@interface AppDelegate(Internal)
-(void) loadSettings;
+(NSString*) settingsFilepath;
-(void) addGoButton;
@end

@implementation AppDelegate
@synthesize settings;
@synthesize facebook;
@synthesize facebookLoginController;
@synthesize urbanAirshipClient;
@synthesize settingsMenuController;
@synthesize tabBarController;
@synthesize userCheckedIn = _userCheckedIn;
@synthesize checkOutTimer = _checkOutTimer;

// TODO: Store what we're storing now in settings in NSUSERDefaults
// Why make our own class when there's an iOS Api for this?

+(AppDelegate*)instance
{
	return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

@synthesize window = _window;


# pragma mark - Check-in/out Stuff

// TODO: consolidate this with the checkedIn property on the current user in NSUserDefaults
- (BOOL)userCheckedIn 
{
    NSNumber *checkoutEpoch = DEFAULTS(object, kUDCheckoutTime);
    return [checkoutEpoch intValue] > [[NSDate date]timeIntervalSince1970];
}

- (void)startCheckInClockHandAnimation
{
    // spin the clock hand
    [CPUIHelper spinView:[self.tabBarController.centerButton viewWithTag:903] duration:15 repeatCount:MAXFLOAT clockwise:YES timingFunction:nil];
}

- (void)stopCheckInClockHandAnimation
{
    // stop the clock hand spin
    [[self.tabBarController.centerButton viewWithTag:903].layer removeAllAnimations];
}

- (void)setCheckedOut
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"userCheckedIn" object:nil];
    NSInteger checkOutTime = (NSInteger) [[NSDate date] timeIntervalSince1970];
    SET_DEFAULTS(Object, kUDCheckoutTime, [NSNumber numberWithInt:checkOutTime]);
    [self refreshCheckInButton];
    if (self.checkOutTimer != nil) {
        [[self checkOutTimer] invalidate];
        self.checkOutTimer = nil;   
    }
}

- (void)checkInButtonPressed:(id)sender
{
    if (self.userCheckedIn) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Check Out"
                              message:@"Are you sure you want to be checked out?"
                              delegate:self.settingsMenuController
                              cancelButtonTitle:@"Cancel"
                              otherButtonTitles: @"Check Out", nil];
        alert.tag = 904;
        [alert show];
        
    } else {
        UINavigationController *checkInNC = [[UIStoryboard storyboardWithName:@"CheckinStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
        [self.tabBarController presentModalViewController:checkInNC animated:YES];
    }
}

- (void)refreshCheckInButton 
{
    // change the image and the text on the tab bar item
    if (self.userCheckedIn) {
        // start animating the clock hand
        [self startCheckInClockHandAnimation];
        [self.tabBarController.centerButton setBackgroundImage:[UIImage imageNamed:@"tab-check-out.png"] forState:UIControlStateNormal];
    } else {
        // stop animating the clock hand
        [self stopCheckInClockHandAnimation];
        [self.tabBarController.centerButton setBackgroundImage:[UIImage imageNamed:@"tab-check-in.png"] forState:UIControlStateNormal];
    }
}

# pragma mark - Signup 

- (void)showSignupModalFromViewController:(UIViewController *)viewController
                                 animated:(BOOL)animated
{
    [self logoutEverything];
    UIStoryboard *signupStoryboard = [UIStoryboard storyboardWithName:@"SignupStoryboard_iPhone" bundle:nil];
    UINavigationController *signupController = [signupStoryboard instantiateInitialViewController];
    
    [viewController presentModalViewController:signupController animated:animated];
}

- (void)showEnterInvitationCodeModalFromViewController:(UIViewController *)viewController
         withDontShowTextNoticeAfterLaterButtonPressed:(BOOL)dontShowTextNoticeAfterLaterButtonPressed
                                              animated:(BOOL)animated
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SignupStoryboard_iPhone" bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:
                                                    @"EnterInvitationCodeNavigationController"];
    
    EnterInvitationCodeViewController *controller = (EnterInvitationCodeViewController *)navigationController.topViewController;
    controller.dontShowTextNoticeAfterLaterButtonPressed = dontShowTextNoticeAfterLaterButtonPressed;
    
    [viewController presentModalViewController:navigationController animated:animated];
}

- (void)syncCurrentUserWithWebAndCheckValidLogin {
    if (self.currentUser.userID) {        
        User *webSyncUser = [[User alloc] init];
        webSyncUser.userID = self.currentUser.userID;
        
        [webSyncUser loadUserResumeData:^(NSError *error) {
            if (!error) {
                // TODO: make this a better solution by checking for a problem with the PHP session cookie in CPApi
                // for now if the email comes back null this person isn't logged in so we're going to send them to do that.
                if ( ! [webSyncUser.email isKindOfClass:[NSNull class]]) {
                    [self saveCurrentUserToUserDefaults:webSyncUser];
                    
                    if ( ! self.currentUser.isDaysOfTrialAccessWithoutInviteCodeOK) {
                        [self showSignupModalFromViewController:self.tabBarController animated:NO];
                        
                        [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Your %d days trial has ended.", kDaysOfTrialAccessWithoutInviteCode]
                                                    message:@"Please login and enter invite code."
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil] show];
                    }
                }
            }
        }];
    }
}


#pragma mark - View Lifecycle

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
	[self loadSettings];  
    
    [FlurryAnalytics startSession:flurryAnalyticsKey];
    
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
    [BaseLoginController pushAliasUpdate];
    
    // See what notifications the user has set and push to Flurry
    UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
    NSMutableDictionary *flurryParams = [[NSMutableDictionary alloc] init];
    NSString *alertValue = [[NSString alloc] init];

    if (types == UIRemoteNotificationTypeNone) {
        alertValue = @"None";
    }
    else
    {
        if ((types & UIRemoteNotificationTypeBadge) == UIRemoteNotificationTypeBadge) {
            alertValue = @"+Badges";
        }
        if ((types & UIRemoteNotificationTypeAlert) == UIRemoteNotificationTypeAlert) {
            alertValue = [alertValue stringByAppendingString:@"+Alerts"];
        }
        if ((types & UIRemoteNotificationTypeSound) == UIRemoteNotificationTypeSound) {
            alertValue = [alertValue stringByAppendingString:@"+Sounds"];
        }
    }
    [flurryParams setValue:alertValue forKey:@"Notifications"];
    [FlurryAnalytics logEvent:@"enabled_notifications" withParameters:flurryParams];
    NSLog(@"Notification types: %@", flurryParams);
    
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
    self.tabBarController = (CPTabBarController *)self.window.rootViewController;
    self.settingsMenuController.frontViewController = self.tabBarController;
    [settingsMenuController.view addSubview:self.tabBarController.view];
    [settingsMenuController addChildViewController:self.tabBarController];
    self.window.rootViewController = settingsMenuController;
    
    // make the status bar the black style
    application.statusBarStyle = UIStatusBarStyleBlackOpaque;

    [self.window makeKeyAndVisible];
    
    if ( ! [CPAppDelegate currentUser]) {
        [self showSignupModalFromViewController:self.tabBarController animated:NO];
    }
    [self syncCurrentUserWithWebAndCheckValidLogin];
    
    // let's use UIAppearance to set our styles on UINavigationBars
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"header.png"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIFont fontWithName:@"LeagueGothic" size:22] forKey:UITextAttributeFont]];
    
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
    [self syncCurrentUserWithWebAndCheckValidLogin];
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
    if (notif.alertAction = @"Check Out") {
        [AppDelegate instance].checkOutTimer = [NSTimer scheduledTimerWithTimeInterval:300
                                                                                target:self
                                                                              selector:@selector(setCheckedOut) 
                                                                              userInfo:nil 
                                                                               repeats:NO];
        
        [self.tabBarController performSegueWithIdentifier:@"ShowCheckInListTable"
                                                           sender:self]; 
    }
}

// Handle PUSH notifications while the app is running
- (void)application:(UIApplication*)application
didReceiveRemoteNotification:(NSDictionary*)userInfo
{
	NSLog(@"Received notification: %@", userInfo);
    
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
                                         withRootView:self.tabBarController];
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
        NSString *message = [userInfo valueForKeyPath:@"aps.alert"];
        [PaymentHelper showPaymentReceivedAlertWithMessage:message];
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
	SET_DEFAULTS(Object, kUDCurrentUser, nil);
}

- (void)storeUserLoginDataFromDictionary:(NSDictionary *)userInfo
{
    NSString *userId = [userInfo objectForKey:@"id"];
    NSString  *nickname = [userInfo objectForKey:@"nickname"];
    
    User *currUser = [[User alloc] init];
    currUser.nickname = nickname;
    currUser.userID = [userId intValue];
    [currUser setEnteredInviteCodeFromJSONString:[userInfo objectForKey:@"entered_invite_code"]];
    [currUser setJoinDateFromJSONString:[userInfo objectForKey:@"join_date"]];
    
    NSLog(@"%d", currUser.userID);
    
    [self saveCurrentUserToUserDefaults:currUser];
}

- (void)saveCurrentUserToUserDefaults:(User *)user
{
#if DEBUG
    NSLog(@"Storing user data for user with ID %d and nickname %@ to NSUserDefaults", user.userID, user.nickname);
#endif
    
    // encode the user object
    NSData *encodedUser = [NSKeyedArchiver archivedDataWithRootObject:user];
    
    // store it in user defaults
    SET_DEFAULTS(Object, kUDCurrentUser, encodedUser);
}

- (User *)currentUser
{
    if (DEFAULTS(object, kUDCurrentUser)) {
        // grab the coded user from NSUserDefaults
        NSData *myEncodedObject = DEFAULTS(object, kUDCurrentUser);
        // return it
        return (User *)[NSKeyedUnarchiver unarchiveObjectWithData:myEncodedObject];
    } else {
        return nil;
    }
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
