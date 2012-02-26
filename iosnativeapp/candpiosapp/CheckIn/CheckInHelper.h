//
//  CheckInHelper.h
//  candpiosapp
//
//  Created by Stojce Slavkovski on 26.2.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CheckInHelper : NSObject

+ (void)showCheckInProfileForUser:(int) user_id
                         fromView:(UIViewController *)view;

@end
