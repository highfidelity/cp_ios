//
//  AppDelegate.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"
#import "Facebook.h"
#import "UAirship.h"
#import "UAPush.h"
#import "SettingsMenuController.h"
#import "CPTabBarController.h"

// Constants have been moved to CPConstants.m

@class FacebookLoginSequence;
@class AFHTTPClient;
@class SignupController;
@class User;

@interface AppDelegate : UIResponder <UIApplicationDelegate,
                                      FBSessionDelegate,
                                      UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, readonly) Settings *settings;
@property (strong, readonly) Facebook *facebook;
@property (strong, nonatomic) SignupController *facebookLoginController;
@property (strong, nonatomic, readonly) AFHTTPClient *urbanAirshipClient;
@property (strong, nonatomic) SettingsMenuController *settingsMenuController;
@property (strong, nonatomic) CPTabBarController *tabBarController;
@property (readonly) BOOL userCheckedIn;
@property (strong) NSTimer *checkOutTimer;
           
-(void)saveSettings;
+(AppDelegate *)instance;
-(void)logoutEverything;
-(void)storeUserLoginDataFromDictionary:(NSDictionary *)userDictionary;
-(void)saveCurrentUserToUserDefaults:(User *)user;
-(User *)currentUser;
- (void)toggleSettingsMenu;
- (void)refreshCheckInButton;
- (void)setCheckedOut;
-(void)startCheckInClockHandAnimation;
-(void)stopCheckInClockHandAnimation;
- (void)showSignupModalFromViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (void)showEnterInvitationCodeModalFromViewController:(UIViewController *)viewController
         withDontShowTextNoticeAfterLaterButtonPressed:(BOOL)dontShowTextNoticeAfterLaterButtonPressed
                                              animated:(BOOL)animated;
- (void)syncCurrentUserWithWebAndCheckValidLogin;

- (void)showLoginBanner;
- (void)hideLoginBannerWithCompletion:(void (^)(void))completion;

void uncaughtExceptionHandler(NSException *exception);
@end

