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
+ (void)presentF2FInviteFromUser:(int) userId;

// F2F is compelte. Congratulate both parties!
+ (void)presentF2FSuccessFrom:(NSString *) nickname;



@end
