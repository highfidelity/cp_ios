//
//  CPCheckinHandler.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/26/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPCheckinHandler : NSObject

@property (strong, nonatomic) NSTimer *checkOutTimer;

+ (void)presentCheckInListModalFromViewController:(UIViewController *)presentingViewController;
+ (void)presentCheckInDetailsModalForVenue:(CPVenue *)venue  presentingViewController:(UIViewController *)presentingViewController;
+ (void)handleSuccessfulCheckinToVenue:(CPVenue *)venue checkoutTime:(NSInteger)checkoutTime;
+ (void)queueLocalNotificationForVenue:(CPVenue *)venue checkoutTime:(NSInteger)checkoutTime;
- (void)setCheckedOut;
+ (void)saveCheckInVenue:(CPVenue *)venue andCheckOutTime:(NSInteger)checkOutTime;
+ (void)promptForCheckout;

+ (CPCheckinHandler *)sharedHandler;

@end
