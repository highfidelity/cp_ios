//
//  Settings.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/31/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Settings : NSObject< NSCoding, NSCopying >

@property (nonatomic, assign) bool flag;
@property (nonatomic, assign) bool hasLocation;
@property (nonatomic, assign) bool registeredForApnsSuccessfully;
@property (nonatomic, copy) CLLocation *lastKnownLocation;

@property (nonatomic, copy) NSString *candpLoginToken;
@property (nonatomic, copy) NSString *facebookAccessToken;
@property (nonatomic, copy) NSDate *facebookExpirationDate;

// note: userEmailAddress is only valid if the created their account with an email address
@property (nonatomic, copy) NSString *userEmailAddress;
@property (nonatomic, copy) NSString *userNickname;
@property (nonatomic, copy) NSString *userPassword;

@end
