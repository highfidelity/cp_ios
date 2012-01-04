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
@property (nonatomic, copy) CLLocation *lastKnownLocation;

@property (nonatomic, assign) NSString *candpLoginToken;

@end
