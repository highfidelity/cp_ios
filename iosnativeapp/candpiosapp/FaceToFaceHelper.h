//
//  FaceToFaceHelper.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/17.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FaceToFaceHelper : NSObject

// Handle an incoming F2F request
// Present the 'greeted' with the option to Accept or Decline
+ (void)presentF2FInviteFromUser:(int) userId
                        fromView:(UIViewController *)view;

// F2F has been accepted
// Present the 'greeter' with the password to provide the 'greeted'
+ (void)presentF2FAcceptFromUser:(int) userId
                    withPassword:(NSString *)password
                        fromView:(UIViewController *)view;

// F2F is compelte. Congratulate both parties!
+ (void)presentF2FSuccessFrom:(NSString *) nickname
                     fromView:(UIViewController *) view;

@end
