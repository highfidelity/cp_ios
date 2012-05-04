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

// Constants have been moved to CPConstants.m

@class AFHTTPClient;
@class SignupController;
@class User;

@interface AppDelegate : UIResponder <UIApplicationDelegate,
                                      UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, readonly) Settings *settings;
@property (strong, nonatomic, readonly) AFHTTPClient *urbanAirshipClient;
@property (strong, nonatomic) SettingsMenuController *settingsMenuController;
@property (strong, nonatomic) CPTabBarController *tabBarController;
@property (readonly) BOOL userCheckedIn;
@property (strong) NSTimer *checkOutTimer;
           
-(void)saveSettings;
- (void)loadVenueView:(NSString *)venueName;
+(AppDelegate *)instance;
-(void)logoutEverything;
-(void)storeUserLoginDataFromDictionary:(NSDictionary *)userDictionary;
-(void)saveCurrentUserToUserDefaults:(User *)user;
-(User *)currentUser;
- (void)saveCurrentVenueUserDefaults:(CPVenue *)venue;
- (CPVenue *)currentVenue;
- (void)toggleSettingsMenu;
- (void)refreshCheckInButton;
- (void)promptForCheckout;
- (void)setCheckedOut;
- (void)checkOutNow;
- (void)showSignupModalFromViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)showEnterInvitationCodeModalFromViewController:(UIViewController *)viewController
         withDontShowTextNoticeAfterLaterButtonPressed:(BOOL)dontShowTextNoticeAfterLaterButtonPressed
                                              animated:(BOOL)animated;
- (void)syncCurrentUserWithWebAndCheckValidLogin;

- (void)showLoginBanner;
- (void)hideLoginBannerWithCompletion:(void (^)(void))completion;

void uncaughtExceptionHandler(NSException *exception);
void SignalHandler(int sig);

@end

