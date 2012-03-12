//
//  CheckInHelper.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 26.2.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "PaymentHelper.h"

@implementation PaymentHelper

+ (void)showPaymentReceivedAlertWithMessage:(NSString *)message
{
    // the alert delegate will be the settings menu view controller
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Payment Recieved" 
                                                        message:message
                                                       delegate:[CPAppDelegate settingsMenuController] 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:@"Wallet", nil];
    [alertView show];
}

@end
