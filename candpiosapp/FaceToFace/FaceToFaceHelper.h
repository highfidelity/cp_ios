//
//  FaceToFaceHelper.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/17.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingsMenuController.h"

@interface FaceToFaceHelper : NSObject <UIActionSheetDelegate>

- (void)showContactRequestActionSheetForUserID:(int)userID;

+ (FaceToFaceHelper *)sharedHelper;

// Handle an incoming F2F request
// Present the 'greeted' with the option to Accept or Decline
+ (void)presentF2FInviteFromUser:(int) userId
                        fromView:(SettingsMenuController *)view;

// F2F has been accepted
// Present the 'greeter' with the password to provide the 'greeted'
+ (void)presentF2FAcceptFromUser:(int) userId
                    withPassword:(NSString *)password
                        fromView:(SettingsMenuController *)view;

// F2F is compelte. Congratulate both parties!
+ (void)presentF2FSuccessFrom:(NSString *) nickname
                     fromView:(SettingsMenuController *) view;



@end
