//
//  AppDelegate.m
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import "FaceToFaceHelper.h"
#import "CPChatHelper.h"
#import "OAuthConsumer.h"
#import "CPAlertView.h"
#import "VenueInfoViewController.h"
#import "CPCheckinHandler.h"
#import "CPGeofenceHandler.h"
#import "CPUserSessionHandler.h"
#import "UserProfileViewController.h"

#define kContactRequestAPNSKey @"contact_request"
#define kContactRequestAcceptedAPNSKey @"contact_accepted"
#define kContactEndorsedAPNSKey @"contact_endorsed"

#define kCheckOutAlertTag 602
#define kFeedViewAlertTag 500
#define kContactEndorsedTag 501

#define kDefaultLatitude 37.77493
#define kDefaultLongitude -122.419415

@interface AppDelegate() {
    NSCache *_cache;
}

@property (nonatomic, strong) NSDictionary* urbanAirshipTakeOffOptions;

-(void) loadSettings;
+(NSString*) settingsFilepath;

@end

@implementation AppDelegate

@synthesize locationManager = _locationManager;

// TODO: Store what we're storing now in settings in NSUSERDefaults
// Why make our own class when there's an iOS Api for this?

#pragma mark - View Lifecycle

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    // temporarily handle decoding of old User object
    [NSKeyedUnarchiver setClass:[CPUser class] forClassName:@"User"];
    
    [self setupTestFlightSDK];
    [self setupFlurryAnalytics];
    
    // store urbanAirshipTakeOffOptions so we can use them when we want to take off
    NSMutableDictionary *takeOffOptions = [[NSMutableDictionary alloc] init];
    [takeOffOptions setValue:launchOptions forKey:UAirshipTakeOffOptionsLaunchOptionsKey];
    self.urbanAirshipTakeOffOptions = takeOffOptions;
        
    // Switch out the UINavigationController in the rootviewcontroller for the SettingsMenuController
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"SettingsStoryboard_iPhone" bundle:nil];
    self.settingsMenuController = (SettingsMenuController*)[mainStoryboard instantiateViewControllerWithIdentifier:@"SettingsMenu"];
    self.tabBarController = (CPTabBarController *)self.window.rootViewController;
    self.settingsMenuController.cpTabBarController = self.tabBarController;
    [self.settingsMenuController.view addSubview:self.tabBarController.view];
    [self.settingsMenuController addChildViewController:self.tabBarController];
    self.window.rootViewController = self.settingsMenuController;
    
    // TODO: move the data that we take from the map to a different class so that we have a model for the data that the map and other views can pull from
    // for now we're forcing the map view to get loaded here so that the data is ready
    // because it's no longer the first view in the app
    self.settingsMenuController.mapTabController = [[self.tabBarController storyboard] instantiateViewControllerWithIdentifier:@"venueMapController"];
    
    // make the status bar the black style
    application.statusBarStyle = UIStatusBarStyleBlackOpaque;

    [self.window makeKeyAndVisible];
    [self customAppearanceStyles];
    
    // check if we need to force a user logout if their version of the app is too old
    [CPUserSessionHandler performAppVersionCheck];
    
    if (![CPUserDefaultsHandler currentUser]) {
        [CPUserSessionHandler showSignupModalFromViewController:self.tabBarController animated:NO];
    } else {
        [CPUserSessionHandler performAfterLoginActions];
    }
     
    [CPUserSessionHandler hideLoginBannerWithCompletion:nil];
    
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
    if (_locationManager) {
        // in order to make sure we don't have stray significant change monitoring
        // from previous app versions
        // we need to call stopMonitoringSignificantLocationChanges here
        [_locationManager stopMonitoringSignificantLocationChanges];
        
        // stop monitoring user location, we're going to the background
        [_locationManager stopUpdatingLocation];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
    [CPUserSessionHandler syncCurrentUserWithWebAndCheckValidLogin];
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
    BOOL succeeded = NO;

    NSString *urlString = [NSString stringWithFormat:@"%@", url];
    
    NSRange textRangeLinkedIn;
    textRangeLinkedIn = [urlString rangeOfString:@"candp://linkedin"];
    
    if (textRangeLinkedIn.location != NSNotFound)
    {
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              urlString, @"url",
                              nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"linkedInCredentials" object:self userInfo:dict];
        
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
    NSString *cancelText;
    NSString *otherText;

    if ([notif.alertAction isEqualToString:@"Check Out"]) {
        // For regular timeout checkouts
        cancelText = @"Ignore";
        otherText = @"View";
        CPAlertView *alertView;

        alertView = [[CPAlertView alloc] initWithTitle:notif.alertBody
                                               message:nil
                                              delegate:self
                                     cancelButtonTitle:cancelText
                                     otherButtonTitles:otherText, nil];
        alertView.tag = kCheckOutAlertTag;

        if (alertView) {
            alertView.context = notif.userInfo;
            [alertView show];
        }
    } else if ([notif.userInfo valueForKey:@"geofence"]) {
        [[CPGeofenceHandler sharedHandler] handleGeofenceNotification:notif.alertBody userInfo:notif.userInfo];
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
        
        [CPChatHelper respondToIncomingChatNotification:message
                                         fromNickname:nickname
                                           fromUserId:userId];
    } else if ([userInfo valueForKey:@"feed_venue_id"]) {

        CPAlertView *alertView = [[CPAlertView alloc] initWithTitle:@"Incoming message"
                                                            message:alertMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"Ignore"
                                                  otherButtonTitles:@"View", nil];
        alertView.tag = kFeedViewAlertTag;
        alertView.context = userInfo;
        [alertView show];

    } else if ([userInfo valueForKey:@"geofence"]) {
        [[CPGeofenceHandler sharedHandler] handleGeofenceNotification:alertMessage userInfo:userInfo];
    } else if ([userInfo valueForKey:kContactEndorsedAPNSKey]) {
        CPAlertView *alertView = [[CPAlertView alloc] initWithTitle:@"Contact Endorsed"
                                                            message:alertMessage
                                                           delegate:self
                                                  cancelButtonTitle:@"Ignore"
                                                  otherButtonTitles:@"View", nil];
        alertView.tag = kContactEndorsedTag;
        alertView.context = userInfo;
        [alertView show];
        
    } else if ([userInfo valueForKey:kContactRequestAPNSKey]) {        
        [FaceToFaceHelper presentF2FInviteFromUserID:@([[userInfo valueForKey:kContactRequestAPNSKey] intValue])];
    } else if ([userInfo valueForKey:kContactRequestAcceptedAPNSKey]) {
        [FaceToFaceHelper presentF2FSuccessFrom:[userInfo valueForKey:@"acceptor"]];
    } else {
        // just show the alert if there was one, and the app is active
        if (alertMessage && [UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
            CPAlertView *alertView = [[CPAlertView alloc] initWithTitle:@"Incoming message"
                                                                message:alertMessage
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
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
    self.settings.registeredForApnsSuccessfully = NO;
    NSLog(@"Error in registration. Error: %@", err);
}

#pragma mark - Third Party SDKs

- (void)setupUrbanAirship
{
    if (self.urbanAirshipTakeOffOptions) {
        // Create Airship singleton that's used to talk to Urban Airship servers.
        // Please populate AirshipConfig.plist with your info from http://go.urbanairship.com
        [UAirship takeOff:self.urbanAirshipTakeOffOptions];
        
        // register for push
        [[UAPush shared] registerForRemoteNotificationTypes:
         (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
        
        // nil out the urban airship take off options
        self.urbanAirshipTakeOffOptions = nil;
    }
}

- (void)pushAliasUpdate {
    // Set my UserID as an UrbanAirship alias for push notifications
    NSString *userIDString = [[CPUserDefaultsHandler currentUser].userID stringValue];
    
    NSLog(@"Attempting to register user alias %@ with UrbanAirship", userIDString);
    [UAPush shared].alias = userIDString;
    [[UAPush shared] updateRegistration];
}

- (void)setupTestFlightSDK
{
    // if this is a build for TestFlight then set the user's UDID so sessions in testflight are associated with them
#define TESTING 1
#ifdef TESTING
    
    [TestFlight setOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:@"disableInAppUpdates"]];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#pragma clang diagnostic pop   

#endif
    
    [TestFlight takeOff:kTestFlightKey];
}

-(void)setupFlurryAnalytics
{
    [Flurry startSession:flurryAnalyticsKey];
    
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
    [Flurry logEvent:@"enabled_notifications" withParameters:flurryParams];
    NSLog(@"Notification types: %@", flurryParams);
}

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _locationManager.distanceFilter = 20;
        
        [_locationManager startUpdatingLocation];
    }
    return _locationManager;
}

- (CLLocation *)currentOrDefaultLocation
{
    CLLocation *userLocation = [CPAppDelegate locationManager].location;
    if (!userLocation) {
        userLocation = [[CLLocation alloc] initWithLatitude:kDefaultLatitude longitude:kDefaultLongitude];
    }

    return userLocation;
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
    if ([CPUserDefaultsHandler isUserCurrentlyCheckedIn] && [[CPUserDefaultsHandler currentVenue].name isEqualToString:region.identifier]) {
        return;
    } else {
        // grab the right venue from our past venues
        CPVenue * autoVenue = [[CPGeofenceHandler sharedHandler] venueWithName:region.identifier];
        // Check in the user immediately
        [[CPGeofenceHandler sharedHandler] autoCheckInForVenue:autoVenue];
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [[CPGeofenceHandler sharedHandler] handleAutoCheckOutForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"monitoringDidFailForRegion, ERROR: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Location Manager failed with error: %@", error.localizedDescription);
}

#pragma mark - Appearance Styles
- (void)customAppearanceStyles
{
    // let's use UIAppearance to set our styles on UINavigationBars
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlack];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"header.png"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIFont fontWithName:@"LeagueGothic" size:22] forKey:UITextAttributeFont]];

    // UIAppearance styles on UIBarButtonItems
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObject:[UIFont fontWithName:@"LeagueGothic" size:16]
                                                                                     forKey:UITextAttributeFont]
                                                forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(1, -1)
                                                         forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(0, 0)
                                               forBarMetrics:UIBarMetricsDefault];

    UIImage *backImage = [UIImage imageNamed:@"back-button.png"];
    backImage = [backImage stretchableImageWithLeftCapWidth:17 topCapHeight:0];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

    UIImage *headerButtonImage = [UIImage imageNamed:@"header-button.png"];
    headerButtonImage = [headerButtonImage stretchableImageWithLeftCapWidth:7 topCapHeight:0];
    [[UIBarButtonItem appearance] setBackgroundImage:headerButtonImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

# pragma mark - Settings Menu
- (void)toggleSettingsMenu
{
    [self.settingsMenuController showMenu: !self.settingsMenuController.isMenuShowing];
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
			_settings  = newSettings;
		}
		else {
			_settings = [[Settings alloc]init];
		}
	}
	@catch (NSException * e) 
	{
		// if we couldn't load the file, go ahead and delete the file
		[[NSFileManager defaultManager] removeItemAtPath:[AppDelegate settingsFilepath] error:nil];
		_settings = [[Settings alloc]init];
	}
}

-(void)saveSettings
{
	// save the new settings object
	[NSKeyedArchiver archiveRootObject:_settings toFile:[AppDelegate settingsFilepath]];
	
}

- (void)loadVenueView:(NSString *)venueName
{    
    CPVenue *venue = [[CPGeofenceHandler sharedHandler] venueWithName:venueName];
    
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
    }
    else {
        // Venue wasn't found, so load the normal checkIn screen so the user can select it
        NSLog(@"Venue not found");
        
        UINavigationController *checkInNC = [[UIStoryboard storyboardWithName:@"CheckinStoryboard_iPhone" bundle:nil] instantiateInitialViewController];
        [self.tabBarController presentModalViewController:checkInNC animated:YES];
    }
}

#pragma mark - appCache
- (NSCache *)appCache
{
    if (!_cache) {
        _cache = [[NSCache alloc] init];
    }
    return _cache;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    CPAlertView *cpAlertView = (CPAlertView *)alertView;
    NSDictionary *userInfo = cpAlertView.context;

    if (alertView.tag == kCheckOutAlertTag) {
        if (alertView.firstOtherButtonIndex == buttonIndex) {            
            [CPCheckinHandler sharedHandler].checkOutTimer = [NSTimer scheduledTimerWithTimeInterval:300
                                                                                    target:[CPCheckinHandler sharedHandler]
                                                                                  selector:@selector(setCheckedOut) 
                                                                                  userInfo:nil 
                                                                                   repeats:NO];
            
            
            CPVenue *venue = (CPVenue *)[NSKeyedUnarchiver unarchiveObjectWithData:[userInfo objectForKey:@"venue"]];
            [CPCheckinHandler presentCheckInDetailsModalForVenue:venue presentingViewController:self.tabBarController];
        }
    } else if (alertView.tag == kContactEndorsedTag && alertView.firstOtherButtonIndex == buttonIndex) {

        CPUser *user = [[CPUser alloc] init];
        user.userID = @([[userInfo objectForKey:kContactEndorsedAPNSKey] intValue]);
        
        UserProfileViewController *vc = [[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone"
                                                                   bundle:nil] instantiateInitialViewController];
        vc.scrollToReviews = YES;
        vc.user = user;
        [[self.tabBarController.viewControllers objectAtIndex:self.tabBarController.selectedIndex] pushViewController:vc
                                                                                                             animated:YES];
    }
}

@end
