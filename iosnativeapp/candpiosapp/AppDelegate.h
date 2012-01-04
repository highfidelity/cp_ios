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

// CandP Dev is "278566002200147"
#define kFacebookAppId		@"278566002200147"

@interface AppDelegate : UIResponder <UIApplicationDelegate, FBSessionDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, readonly) Settings *settings;
@property (strong, readonly) Facebook *facebook;

-(void)saveSettings;
+(AppDelegate*)instance;
@end
