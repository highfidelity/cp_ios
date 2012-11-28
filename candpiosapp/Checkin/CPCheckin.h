//
//  CPCheckIn.h
//  candpiosapp
//
//  Created by Stephen Birarda on 11/28/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPCheckIn : NSObject

@property (strong, nonatomic) NSNumber *checkInID;
@property (strong, nonatomic) NSNumber *lat;
@property (strong, nonatomic) NSNumber *lng;
@property (strong, nonatomic) NSString *statusText;
@property (strong, nonatomic) NSNumber *isCurrentlyCheckedIn;
@property (strong, nonatomic) CPVenue *venue;

@end
