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
#import "UIButton+AnimatedClockHand.h"
#import "PushModalViewControllerFromLeftSegue.h"
#import "ContactListViewController.h"
#import "MKStoreManager.h"

#define kContactRequestAPNSKey @"contact_request"
#define kContactRequestAcceptedAPNSKey @"contact_accepted"
#define kCheckOutLocalNotificationAlertViewTitle @"You will be checked out of C&P in 5 min."
#define kRadiusForCheckins                      10 // measure in meters, from lat/lng of CPVenue

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
@synthesize locationManager;

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

-(void)refreshCheckInButton
{
    // helper to grab center button and refresh state
    [self.tabBarController.centerButton refreshButtonStateFromCheckinStatus];
}

// TODO: consolidate this with the checkedIn property on the current user in NSUserDefaults
- (BOOL)userCheckedIn 
{
    NSNumber *checkoutEpoch = DEFAULTS(object, kUDCheckoutTime);
    return [checkoutEpoch intValue] > [[NSDate date]timeIntervalSince1970];
}

- (void)promptForCheckout
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:@"Check Out"
                          message:@"Are you sure you want to be checked out?"
                          delegate:self.settingsMenuController
                          cancelButtonTitle:@"Cancel"
                          otherButtonTitles: @"Check Out", nil];
    alert.tag = 904;
    [alert show];
}

- (void)checkInNow:(CPVenue *)venue
{
    // Check the user in automatically now

    [FlurryAnalytics logEvent:@"autoCheckedIn"];
    
    NSInteger checkInTime = (NSInteger) [[NSDate date] timeIntervalSince1970];
    // Set a maximum checkInDuration to 24 hours
    NSInteger checkInDuration = 24;
    
    NSInteger checkOutTime = checkInTime + checkInDuration * 3600;
    NSString *statusText = @"";

    // use CPapi to checkin
    [CPapi checkInToLocation:venue hoursHere:checkInDuration statusText:statusText isVirtual:NO isAutomatic:YES completionBlock:^(NSDictionary *json, NSError *error){

        if (!error) {
            if (![[json objectForKey:@"error"] boolValue]) {

                // Cancel all old local notifications
                [[UIApplication sharedApplication] cancelAllLocalNotifications];

                // post a notification to say the user has checked in
                [[NSNotificationCenter defaultCenter] postNotificationName:@"userCheckinStateChange" object:nil];

                [self setCheckedOut];
                
                // set the NSUserDefault to the user checkout time
                SET_DEFAULTS(Object, kUDCheckoutTime, [NSNumber numberWithInt:checkOutTime]);
                
                // Store the current time as lastCheckinTime, used to only monitor the 20 most recent checkins with geofences due to device limitations
                venue.checkinTime = checkInTime;
                
                // Save current place to venue defaults as it's used in several places in the app
                [self saveCurrentVenueUserDefaults:venue];

                // Update past venue list so that the most recent checkin is placed in the right order of the priority list
                [self updatePastVenue:venue];
                
                [self refreshCheckInButton];
            }
            else {
                // There was an error checking in; probably safe to ignore
            }
        } else {
                // There was an error in the main call while checking in; probably safe to ignore
        }
    }];
}

- (void)checkOutNow
{
    [FlurryAnalytics logEvent:@"autoCheckedOut"];
    
    [SVProgressHUD showWithStatus:@"Checking out..."];
    
    [CPapi checkOutWithCompletion:^(NSDictionary *json, NSError *error) {
        
        BOOL respError = [[json objectForKey:@"error"] boolValue];

        if (!error && !respError) {
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
            [self setCheckedOut];
            [SVProgressHUD dismissWithSuccess:@"You have been sucessfully checked out." 
                                   afterDelay:kDefaultDimissDelay];
        } else {
            NSString *message = [json objectForKey:@"payload"];
            if (!message) {
                message = @"Oops. Something went wrong.";    
            }
            [SVProgressHUD dismissWithError:message 
                                 afterDelay:kDefaultDimissDelay];
        }
    }];    
}

- (void)setCheckedOut
{
    NSInteger checkOutTime = (NSInteger) [[NSDate date] timeIntervalSince1970];
    SET_DEFAULTS(Object, kUDCheckoutTime, [NSNumber numberWithInt:checkOutTime]);
    // nil out the venue in NSUserDefaults
    [self saveCurrentVenueUserDefaults:nil];
    [self refreshCheckInButton];
    if (self.checkOutTimer != nil) {
        [[self checkOutTimer] invalidate];
        self.checkOutTimer = nil;   
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"userCheckinStateChange" object:nil];
}

- (void)checkInButtonPressed:(id)sender
{
    if (![CPAppDelegate currentUser]) {
        [CPAppDelegate showLoginBanner];
    } else if (self.userCheckedIn) {
        [self promptForCheckout];
    } else {
        UINavigationController *checkInNC = [[UIStoryboard storyboardWithName:@"CheckinStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
        [self.tabBarController presentModalViewController:checkInNC animated:YES];
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
                                          pushFromLeft:(BOOL)pushFromLeft
                                              animated:(BOOL)animated
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SignupStoryboard_iPhone" bundle:nil];
    UINavigationController *navigationController = [storyboard instantiateViewControllerWithIdentifier:
                                                    @"EnterInvitationCodeNavigationController"];
    
    EnterInvitationCodeViewController *controller = (EnterInvitationCodeViewController *)navigationController.topViewController;
    controller.dontShowTextNoticeAfterLaterButtonPressed = dontShowTextNoticeAfterLaterButtonPressed;
    
    if (pushFromLeft) {
        controller.isPushedFromLeft = YES;
        PushModalViewControllerFromLeftSegue *segue = [[PushModalViewControllerFromLeftSegue alloc] initWithIdentifier:nil
                                                                                                                source:viewController
                                                                                                           destination:navigationController];
        [segue perform];
    } else {
        [viewController presentModalViewController:navigationController animated:animated];
    }
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

    [self startStandardUpdates];
    
    // Initialize MKStoreKit
    [MKStoreManager sharedManager];
    
    return YES;
}

- (CLRegion *)getRegionForVenue:(CPVenue *)venue
{
    CLRegion* region = [[CLRegion alloc] initCircularRegionWithCenter:venue.coordinate
                                                               radius:kRadiusForCheckins identifier:venue.name];
    
    return region;
}

- (void)startMonitoringVenue:(CPVenue *)venue
{
    // Set default autoCheckin to yes, so if the user re-enables it later it'll default to On to cut down on time to restore auto checkins
    venue.autoCheckin = YES;

    // Save current venue to be able to auto checkout in the future, and also used in other places in the app to determine checkin status
    [self saveCurrentVenueUserDefaults:venue];

    // Only start monitoring a region if automaticCheckins is YES
    BOOL automaticCheckins = [DEFAULTS(object, kAutomaticCheckins) boolValue];

    if (automaticCheckins) {        
        CLRegion* region = [self getRegionForVenue:venue];
        
        [self.locationManager startMonitoringForRegion:region
                                       desiredAccuracy:kCLLocationAccuracyNearestTenMeters];

        [CPapi saveVenueAutoCheckinStatus:venue];
    }
}

- (void)stopMonitoringVenue:(CPVenue *)venue
{
    venue.autoCheckin = NO;
    
    CLRegion* region = [self getRegionForVenue:venue];
    [self.locationManager stopMonitoringForRegion:region];

    [CPapi saveVenueAutoCheckinStatus:venue];
    
    [FlurryAnalytics logEvent:@"automaticCheckinLocationDisabled"];
}

- (void)startStandardUpdates
{
    // Create the location manager if this object does not already have one.

    if (nil == self.locationManager)
        self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;
    
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    
    self.locationManager.distanceFilter = 20;
    
    [self.locationManager startMonitoringSignificantLocationChanges];
    
    // Do not create regions if support is unavailable or disabled.
    if (![CLLocationManager regionMonitoringAvailable] || ![CLLocationManager regionMonitoringEnabled]) {
        return;
    }
}
 
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {

    CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:manager.location.coordinate.latitude longitude:manager.location.coordinate.longitude];
    CLLocation *placeLocation = [[CLLocation alloc] initWithLatitude:region.center.latitude longitude:region.center.longitude];
    CLLocationDistance distance = [currentLocation distanceFromLocation:placeLocation];

    // Only show the check in prompt if didEnter location is within 200 meters (in order to fix iOS 5.1+ location quirk)
    if (distance > 200) {
        return;
    }

    // Don't show notification if user is currently checked in to this venue
    if ([CPAppDelegate userCheckedIn] && [[CPAppDelegate currentVenue].name isEqualToString:region.identifier]) {
        return;
    } else {
        // grab the right venue from our past venues
        CPVenue * autoVenue = [self venueWithName:region.identifier];
        // Check in the user immediately
        [self checkInNow:autoVenue];
    }
}
 
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {    
    if ([CPAppDelegate userCheckedIn] && [[CPAppDelegate currentVenue].name isEqualToString:region.identifier]) {
        // Log user out immediately
        [self checkOutNow];
    }
}
 
- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"monitoringDidFailForRegion, ERROR: %@", error);
}
 
 - (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didfailwitherror");
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
//    if (self.locationManager.monitoredRegions.count == 0) {
//        [self.locationManager stopMonitoringSignificantLocationChanges];
//    }
//    else {
//        [self.locationManager startMonitoringSignificantLocationChanges];        
//    }

    // Stop monitoring for locations; if geofences are set up, they'll automatically work in the background    
    [self.locationManager stopMonitoringSignificantLocationChanges];    
//    [self.locationManager stopUpdatingLocation];
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
    BOOL succeeded = NO;

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
        
//        [self loadLinkedInUserProfile];
    }
    else {
        NSLog(@"ERROR responseBody: %@", responseBody);
    }
}


# pragma mark - Push Notifications

- (void)application:(UIApplication *)app
didReceiveLocalNotification:(UILocalNotification *)notif
{    
    NSString *alertText;
    NSString *cancelText;
    NSString *otherText;

    if ([notif.alertAction isEqualToString:@"Check Out"]) {
        // For regular timeout checkouts
        alertText = kCheckOutLocalNotificationAlertViewTitle;
        cancelText = @"Ignore";
        otherText = @"View";
    }

    // Only show the alert if there's a valid title to ensure that we don't show a blank alert
    if (alertText && alertText.length > 0) {
        CPAlertView *alertView;
        
        alertView = [[CPAlertView alloc] initWithTitle:alertText
                                               message:nil
                                              delegate:self
                                     cancelButtonTitle:cancelText
                                     otherButtonTitles:otherText, nil];        
        
        if (alertView) {
            alertView.context = notif;            
            [alertView show];
        }        
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
    } else if ([userInfo valueForKey:@"geofence"]) {
        // if the app is open then show an alert to the user
        if (application.applicationState == UIApplicationStateActive) {
            NSString *alertText = alertMessage;
            NSString *cancelText = @"View";
            NSString *otherText = @"Ignore";
            
            // alloc-init a CPAlertView
            CPAlertView *alertView = [[CPAlertView alloc] initWithTitle:alertText
                                                   message:nil
                                                  delegate:self
                                         cancelButtonTitle:cancelText
                                         otherButtonTitles:otherText, nil];    
            
            // add our userInfo to the alertView
            // be the delegate, give it a tag so we can recognize it
            // and show it
            alertView.context = userInfo;
            alertView.delegate = self;
            alertView.tag = 601;
            [alertView show];
        } else {
            // otherwise when they slide the notification bring them to the venue
            [self loadVenueView:[userInfo objectForKey:@"name"]];
        }
    } else if ([userInfo valueForKey:kContactRequestAPNSKey] != nil) {        
        [FaceToFaceHelper presentF2FInviteFromUser:[[userInfo valueForKey:kContactRequestAPNSKey] intValue]
                                          fromView:self.settingsMenuController];
    }
    else if ([userInfo valueForKey:kContactRequestAcceptedAPNSKey] != nil) {        
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
    currUser.numberOfContactRequests = [userInfo objectForKey:@"number_of_contact_requests"];
    
    // Reset the Automatic Checkins default to YES
    SET_DEFAULTS(Object, kAutomaticCheckins, [NSNumber numberWithBool:YES]);
    
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
    
    if (user.numberOfContactRequests) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNumberOfContactRequestsNotification
                                                            object:self
                                                          userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                    user.numberOfContactRequests, @"numberOfContactRequests",
                                                                    nil]];
    }
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

- (void)updatePastVenue:(CPVenue *)venue
{
    // Store updated venue in pastVenues array

    // encode the user object
    NSData *newVenueData = [NSKeyedArchiver archivedDataWithRootObject:venue];

    NSArray *pastVenues = DEFAULTS(object, kUDPastVenues);
    
    // Reverse order so that the oldest venues are knocked out
    pastVenues = [[pastVenues reverseObjectEnumerator] allObjects];
    
    NSMutableArray *mutablePastVenues = [[NSMutableArray alloc] init];
    
    NSInteger i = 0;
    
    for (NSData *encodedObject in pastVenues) {
        i++;
        
        CPVenue *unencodedVenue = (CPVenue *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        
        // Only add the current venue at the very end, so that it will stay on the list the longest
        if (unencodedVenue && unencodedVenue.name) {
            if (![unencodedVenue.name isEqualToString:venue.name]) {
                [mutablePastVenues addObject:encodedObject];
            }
        }
        
        // Limit number of geofencable venues to 20 due to iOS limitations; remove all of the old venues from monitoring
        if (i > 18) {
            [self stopMonitoringVenue:unencodedVenue];
        }
    }
    
    [mutablePastVenues addObject:newVenueData];
    
    SET_DEFAULTS(Object, kUDPastVenues, mutablePastVenues);    
}

- (void)saveCurrentVenueUserDefaults:(CPVenue *)venue
{
    // encode the user object
    NSData *newVenueData = [NSKeyedArchiver archivedDataWithRootObject:venue];
    
    // store it in user defaults
    SET_DEFAULTS(Object, kUDCurrentVenue, newVenueData);

    [self updatePastVenue:venue];
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

    CPAlertView *cpAlertView = (CPAlertView *)alertView;
    UILocalNotification *notif = cpAlertView.context;

    if ([alertView.title isEqualToString:kCheckOutLocalNotificationAlertViewTitle]) {
        if (alertView.firstOtherButtonIndex == buttonIndex) {            
            [AppDelegate instance].checkOutTimer = [NSTimer scheduledTimerWithTimeInterval:300
                                                                                    target:self
                                                                                  selector:@selector(setCheckedOut) 
                                                                                  userInfo:nil 
                                                                                   repeats:NO];
            
            
            CPVenue *venue = (CPVenue *)[NSKeyedUnarchiver unarchiveObjectWithData:[notif.userInfo objectForKey:@"venue"]];
            
            CheckInDetailsViewController *vc = [[UIStoryboard storyboardWithName:@"CheckinStoryboard_iPhone" bundle:nil]
                                                instantiateViewControllerWithIdentifier:@"CheckinDetailsViewController"];
            vc.checkInIsVirtual = false;
            [vc setPlace:venue];
            vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                                   style:UIBarButtonItemStylePlain
                                                                                  target:vc
                                                                                  action:@selector(dismissViewControllerAnimated)];
            
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:vc];
            [self.tabBarController presentModalViewController:navigationController animated:YES];
        }
    }
    else if (alertView.tag == 601 && alertView.firstOtherButtonIndex == buttonIndex) {
        // Load the venue if the user tapped on View from the didExit auto checkout alert
        if (notif && notif.userInfo) {
            [self loadVenueView:[notif.userInfo objectForKey:@"venue_name"]];
        }
    }
}

@end
