//
//  CPMacros.h
//  candpiosapp
//
//  Created by Stephen Birarda on 11/13/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#ifndef candpiosapp_CPMacro_h
#define candpiosapp_CPMacro_h

// redefine NSLog so it throws to TF and prints it all pretty
#define NSLog(__FORMAT__, ...) TFLog((@"%s [Line %d] " __FORMAT__), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)

// define a way to quickly grab the app delegate
#define CPAppDelegate (AppDelegate *)[UIApplication sharedApplication].delegate

// quick way to check iOS version
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] floatValue] >= v)

#define IS_DEVICE_WITH_FOUR_INCH_DISPLAY    (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && [[UIScreen mainScreen] bounds].size.height == 568)

#endif
