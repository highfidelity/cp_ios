//
//  AppDelegate.m
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import "SignupController.h"
#import "FaceToFaceHelper.h"
#import "ChatHelper.h"
#import "FlurryAnalytics.h"
#import "OAuthConsumer.h"
#import "PaymentHelper.h"
#import "EnterInvitationCodeViewController.h"
#import "CheckInDetailsViewController.h"
#import "CPAlertView.h"
#import "VenueInfoViewController.h"

#define kContactRequestAPNSKey @"contact_request"
#define kContactRequestAcceptedAPNSKey @"contact_accepted"
#define kCheckOutLocalNotificationAlertViewTitle @"You will be checked out of C&P in 5 min."

@interface AppDelegate(Internal)
-(void) loadSettings;
+(NSString*) settingsFilepath;
@end

@implementation AppDelegate
@synthesize settings;
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


# pragma mark - Settings Menu
- (void)toggleSettingsMenu
{
    [self.settingsMenuController showMenu: !self.settingsMenuController.isMenuShowing];
}


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

- (void)checkOutNow
{
    [SVProgressHUD showWithStatus:@"Checking out..."];
    
    [CPapi checkOutWithCompletion:^(NSDictionary *json, NSError *error) {
        
        BOOL respError = [[json objectForKey:@"error"] boolValue];
        
        [SVProgressHUD dismiss];
        if (!error && !respError) {
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
            [self setCheckedOut];
        } else {
            
            
            NSString *message = [json objectForKey:@"payload"];
            if (!message) {
                message = @"Oops. Something went wrong.";    
            }
            
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"An error occurred"
                                  message:message
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles: nil];
            [alert show];
        }
    }];    
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
    if (![CPAppDelegate currentUser]) {
        [CPAppDelegate showLoginBanner];
    } else if (self.userCheckedIn) {
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

- (void)showLoginBanner
{
    if (self.tabBarController.selectedIndex == 4) {
        return;
    }

    self.settingsMenuController.blockUIButton.frame = CGRectMake(0.0,
            self.settingsMenuController.loginBanner.frame.size.height,
            self.window.frame.size.width,
            self.window.frame.size.height);

    [self.settingsMenuController.view bringSubviewToFront: self.settingsMenuController.blockUIButton];
    [self.settingsMenuController.view bringSubviewToFront: self.settingsMenuController.loginBanner];

    [UIView animateWithDuration:0.3 animations:^ {
        self.settingsMenuController.loginBanner.frame = CGRectMake(0.0, 0.0,
                self.settingsMenuController.loginBanner.frame.size.width,
                self.settingsMenuController.loginBanner.frame.size.height);
    }];
}

- (void)hideLoginBannerWithCompletion:(void (^)(void))completion
{
    self.settingsMenuController.blockUIButton.frame = CGRectMake(0.0, 0.0, 0.0, 0.0);
    [self.settingsMenuController.view sendSubviewToBack:self.settingsMenuController.blockUIButton];

    [UIView animateWithDuration:0.3 animations:^ {
        self.settingsMenuController.loginBanner.frame = CGRectMake(0.0,
                -self.settingsMenuController.loginBanner.frame.size.height,
                self.settingsMenuController.loginBanner.frame.size.width,
                self.settingsMenuController.loginBanner.frame.size.height);

        if (completion) {
            completion();
        }
    }];
}




#pragma mark - View Lifecycle

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);

    // create the signal action structure 
    struct sigaction newSignalAction;
    // initialize the signal action structure
    memset(&newSignalAction, 0, sizeof(newSignalAction));
    // set SignalHandler as the handler in the signal action structure
    newSignalAction.sa_handler = &SignalHandler;
    // set SignalHandler as the handlers for SIGABRT, SIGILL and SIGBUS
    sigaction(SIGABRT, &newSignalAction, NULL);
    sigaction(SIGILL, &newSignalAction, NULL);
    sigaction(SIGBUS, &newSignalAction, NULL);
    
    [TestFlight takeOff:kTestFlightKey];

//#warning Disable for App Store builds!
//#define TESTING 1
//#ifdef TESTING
//    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
//#endif
    
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
    self.settingsMenuController.cpTabBarController = self.tabBarController;
    [settingsMenuController.view addSubview:self.tabBarController.view];
    [settingsMenuController addChildViewController:self.tabBarController];
    self.window.rootViewController = settingsMenuController;
    
    // make the status bar the black style
    application.statusBarStyle = UIStatusBarStyleBlackOpaque;

    [self.window makeKeyAndVisible];

    // here we're going to check what the user's previously registered app version was
    // this allows us to force them to login again if required
    // or to tell them to update
    NSString *appVersion = DEFAULTS(object, kUDLastLoggedAppVersion);

#if DEBUG
    NSLog(@"The last logged app version for this user is %@.", appVersion);
#endif
            
    if (!appVersion || [appVersion doubleValue] < 1.3) {
        // we either don't have a logged version or it's less than our current baseline
        // kill the current user object
#if DEBUG
        NSLog(@"Forcing logout based on app version check."); 
#endif
        [self logoutEverything];
    }
    
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    // set the kUDLastLoggedAppVersion to the current version if there has been a change
    if (!appVersion || [appVersion doubleValue] < [currentVersion doubleValue]) {
#if DEBUG
        NSLog(@"Storing app version %@ in NSUserDefaults.", currentVersion);
#endif
        SET_DEFAULTS(Object, kUDLastLoggedAppVersion, currentVersion);
    }    
    
    if ( ! [CPAppDelegate currentUser]) {
        [self showSignupModalFromViewController:self.tabBarController animated:NO];
    }
    [self syncCurrentUserWithWebAndCheckValidLogin];
    
    // let's use UIAppearance to set our styles on UINavigationBars
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"header.png"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIFont fontWithName:@"LeagueGothic" size:22] forKey:UITextAttributeFont]];
    
    
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIFont fontWithName:@"LeagueGothic" size:16]
                                                                                     forKey:UITextAttributeFont]
                                                forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(1, -1)
                                                         forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0, 0)
                                               forBarMetrics:UIBarMetricsDefault];
    
    [self hideLoginBannerWithCompletion:nil];

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
    
    // make sure the check in button starts spinning if it's supposed to
    // or that we switch to the right button if the check in state has changed
    [self refreshCheckInButton];

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
    
    NSRange textRangeLinkedIn, textRangeSmarterer;
    textRangeLinkedIn = [urlString rangeOfString:@"candp://linkedin"];
    textRangeSmarterer = [urlString rangeOfString:@"candp://smarterer"];
    
    if (textRangeLinkedIn.location != NSNotFound)
    {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              urlString, @"url",
                              nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"linkedInCredentials" object:self userInfo:dict];
        
        succeeded = YES;
    }
    else if (textRangeSmarterer.location != NSNotFound)
    {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              urlString, @"url",
                              nil];
        NSLog(@"smarterer url: %@", urlString);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"smartererCredentials" object:self userInfo:dict];
        
        succeeded = YES;
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
    NSDictionary *userDict = notif.userInfo;
    
    BOOL showAlert = NO;
    NSString *alertText;
    NSString *cancelText;
    NSString *otherText;
    NSInteger tagNumber;

    if (userDict && [[userDict objectForKey:@"type"] isEqualToString:@"didExitRegion"]) {
        if (app.applicationState == UIApplicationStateActive) {
            // Show didExitRegion alert
            showAlert = YES;
            alertText = notif.alertBody;
            otherText = @"Check Out";
            cancelText = @"Cancel";
            tagNumber = 601;
        }
        else {
            // Log out immediately if user tapped Check Out from notification
            [self checkOutNow];
        }
    }
    else if (userDict && [[userDict objectForKey:@"type"] isEqualToString:@"didEnterRegion"]) {
        if (app.applicationState == UIApplicationStateActive) {
            // Show didEnterRegion alert
            showAlert = YES;
            alertText = notif.alertBody;
            otherText = @"Check In";
            cancelText = @"Cancel";
            tagNumber = 602;
        }
        else {
            // Take the user to the Venue page as they chose to Check In
            [self loadVenueView:[userDict objectForKey:@"name"]];
        }
    }
    else if ([notif.alertAction isEqual:@"Check Out"]) {
        // For regular timeout checkouts
        showAlert = YES;
        alertText = kCheckOutLocalNotificationAlertViewTitle;
        cancelText = @"OK";
        otherText = @"View";
    }

    if (showAlert) {
        CPAlertView *alertView = [[CPAlertView alloc] initWithTitle:alertText
                                                            message:nil
                                                           delegate:self
                                                  cancelButtonTitle:cancelText
                                                  otherButtonTitles:otherText, nil];
        alertView.context = notif;
        
        if (tagNumber) {
            alertView.tag = tagNumber;
        }
        
        [alertView show];
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
    else if ([userInfo valueForKey:kContactRequestAPNSKey] != nil)
    {        
        [FaceToFaceHelper presentF2FInviteFromUser:[[userInfo valueForKey:kContactRequestAPNSKey] intValue]
                                          fromView:self.settingsMenuController];
    }
    else if ([userInfo valueForKey:kContactRequestAcceptedAPNSKey] != nil)
    {        
        [FaceToFaceHelper presentF2FSuccessFrom:[userInfo valueForKey:@"acceptor"]
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

-(void)logoutEverything
{
	// clear out the cookies
	NSArray *httpscookies3 = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:kCandPWebServiceUrl]];
	
	[httpscookies3 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSHTTPCookie *cookie = (NSHTTPCookie*)obj;
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
	}];

    if ([CPAppDelegate currentUser]) {
        SET_DEFAULTS(Object, kUDCurrentUser, nil);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginStateChanged" object:nil];
    }
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoginStateChanged" object:nil];
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

- (void)saveCurrentVenueUserDefaults:(CPVenue *)venue
{
    // encode the user object
    NSData *encodedVenue = [NSKeyedArchiver archivedDataWithRootObject:venue];
    
    // store it in user defaults
    SET_DEFAULTS(Object, kUDCurrentVenue, encodedVenue);
    
    // Store venue in pastVenues array if not already present
    NSArray *pastVenues = DEFAULTS(object, kUDPastVenues);
    
    if (pastVenues == nil || ![pastVenues containsObject:encodedVenue]) {
        NSMutableArray *mutablePastVenues = [[NSMutableArray alloc] initWithArray:pastVenues];
        [mutablePastVenues addObject:encodedVenue];
        SET_DEFAULTS(Object, kUDPastVenues, mutablePastVenues);
    }
}

- (CPVenue *)currentVenue
{
    if (DEFAULTS(object, kUDCurrentVenue)) {
        // grab the coded user from NSUserDefaults
        NSData *myEncodedObject = DEFAULTS(object, kUDCurrentVenue);
        // return it
        return (CPVenue *)[NSKeyedUnarchiver unarchiveObjectWithData:myEncodedObject];
    } else {
        return nil;
    }
}

- (CPVenue *)venueWithName:(NSString *)name
{
    NSArray *pastVenues = DEFAULTS(object, kUDPastVenues);

    CPVenue *venueMatch;

    for (NSData *encodedObject in pastVenues) {
        CPVenue *venue = (CPVenue *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];

        if ([venue.name isEqualToString:name]) {
            venueMatch = venue;
        }
    }
    
    return venueMatch;
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

- (void)loadVenueView:(NSString *)venueName
{    
    CPVenue *venue = [self venueWithName:venueName];
    
    if (venue) {
        NSLog(@"Load venue: %@", venueName);

        VenueInfoViewController *venueVC = [[UIStoryboard storyboardWithName:@"VenueStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
        venueVC.venue = venue;

        venueVC.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                               style:UIBarButtonItemStylePlain
                                                                              target:venueVC
                                                                              action:@selector(dismissViewControllerAnimated)];

        
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:venueVC];
        [self.tabBarController presentModalViewController:navigationController animated:YES];        
        
        // If you want to instead take the user directly to the check-in screen, use the code below
        
        //    CheckInDetailsViewController *vc = [[UIStoryboard storyboardWithName:@"CheckinStoryboard_iPhone" bundle:nil]
        //                                        instantiateViewControllerWithIdentifier:@"CheckinDetailsViewController"];
        //    [vc setPlace:venue];
        //    vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
        //                                                                           style:UIBarButtonItemStylePlain
        //                                                                          target:vc
        //                                                                          action:@selector(dismissViewControllerAnimated)];
        //    
        //    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
        //    [self.tabBarController presentModalViewController:navigationController animated:YES];
    }
    else {
        // Venue wasn't found, so load the normal checkIn screen so the user can select it
        NSLog(@"Venue not found");
        
        UINavigationController *checkInNC = [[UIStoryboard storyboardWithName:@"CheckinStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
        [self.tabBarController presentModalViewController:checkInNC animated:YES];
    }
}

#pragma mark - Crash Handlers

void uncaughtExceptionHandler(NSException *exception) {
    [FlurryAnalytics logError:@"Uncaught" message:@"Crash!" exception:exception];
}

void SignalHandler(int sig) {
    // NSLog(@"This is where we save the application data during a signal");
    // Save application data on crash
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:kCheckOutLocalNotificationAlertViewTitle]) {
        if (alertView.firstOtherButtonIndex == buttonIndex) {
            CPAlertView *cpAlertView = (CPAlertView *)alertView;
            UILocalNotification *notif = cpAlertView.context;
            
            [AppDelegate instance].checkOutTimer = [NSTimer scheduledTimerWithTimeInterval:300
                                                                                    target:self
                                                                                  selector:@selector(setCheckedOut) 
                                                                                  userInfo:nil 
                                                                                   repeats:NO];
            
            CPVenue *place = [[CPVenue alloc] initFromDictionary:notif.userInfo];
            CheckInDetailsViewController *vc = [[UIStoryboard storyboardWithName:@"CheckinStoryboard_iPhone" bundle:nil]
                                                instantiateViewControllerWithIdentifier:@"CheckinDetailsViewController"];
            [vc setPlace:place];
            vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                                   style:UIBarButtonItemStylePlain
                                                                                  target:vc
                                                                                  action:@selector(dismissViewControllerAnimated)];
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
            [self.tabBarController presentModalViewController:navigationController animated:YES];
        }
    }
    else if (alertView.tag == 601 && alertView.firstOtherButtonIndex == buttonIndex) {
        // Log user out immediately if they tapped Check Out
        [self checkOutNow];
    }
    else if (alertView.tag == 602 && alertView.firstOtherButtonIndex == buttonIndex) {
        CPAlertView *cpAlertView = (CPAlertView *)alertView;
        UILocalNotification *notif = cpAlertView.context;

        if (notif && notif.userInfo) {
            [self loadVenueView:[notif.userInfo objectForKey:@"name"]];
        }
    }
}

@end
