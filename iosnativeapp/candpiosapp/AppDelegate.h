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


////////////////////////////////////////////////
#define kCandPWebServiceUrl			@"https://staging.coffeeandpower.com/"
//#define kCandPWebServiceUrl		@"https://coffeeandpower.com/"

////////////////////////////////////////////////
// CandP staging:			"230528896971048"
// CandP Dev (alternate)	"278566002200147"
#define kFacebookAppId		@"230528896971048"

// Emcro-created LI:
//#define kLinkedInKey @"dj7n9nz3bj65"
//#define kLinkedInSecret @"Hnt0m2JuooWM29OW"

// Dev LinkedIn:
#define kLinkedInKey @"4xkfzpnvuc72"
#define kLinkedInSecret @"mxgFhH1i1PbPlWjq"

// Prod LinkedIn:
//#define kLinkedInKey @"0"
//#define kLinkedInSecret @"0"


////////////////////////////////////////////////
// urban airship
// Configured in AirshipConfig.plist, not here anymore
//#define kUrbanAirshipApplicationKey			@"wa_ouebsSr6KZfqEDiH4qA"
//#define kUrbanAirshipApplicationSecret		@"_0L5-MnZTQaB4G821jl8qg"



////////////////////////////////////////////////

@class FacebookLoginSequence;
@class AFHTTPClient;

@interface AppDelegate : UIResponder <UIApplicationDelegate, FBSessionDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, readonly) Settings *settings;
@property (strong, readonly) Facebook *facebook;
@property (strong, nonatomic) NSObject *loginSequence;
@property (strong, nonatomic, readonly) AFHTTPClient *urbanAirshipClient;

-(void)loadCheckinScreen;
-(void)saveSettings;
+(AppDelegate*)instance;
-(void)logoutEverything;
@end
