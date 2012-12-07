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
@property (nonatomic, readonly) BOOL isCurrentlyCheckedIn;
@property (strong, nonatomic) NSNumber *checkoutSinceEpoch;
@property (strong, nonatomic, readonly) NSDate *checkoutDate;
@property (strong, nonatomic) CPVenue *venue;

@end
