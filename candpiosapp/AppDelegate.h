//
//  AppDelegate.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"
#import "UAirship.h"
#import "UAPush.h"
#import "SettingsMenuController.h"
#import "CPTabBarController.h"
#import <CoreLocation/CoreLocation.h>
#import "FlurryAnalytics.h"

@class AFHTTPClient;
@class SignupController;
@class User;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) Settings *settings;
@property (strong, nonatomic, readonly) AFHTTPClient *urbanAirshipClient;
@property (strong, nonatomic, readonly) CLLocationManager *locationManager;
@property (strong, nonatomic) SettingsMenuController *settingsMenuController;
@property (strong, nonatomic) CPTabBarController *tabBarController;
@property (strong, nonatomic) NSTimer *checkOutTimer;
           
- (void)pushAliasUpdate;
- (void)saveSettings;
- (void)loadVenueView:(NSString *)venueName;
- (void)toggleSettingsMenu;
- (void)setupUrbanAirship;


void uncaughtExceptionHandler(NSException *exception);
void SignalHandler(int sig);

@end

